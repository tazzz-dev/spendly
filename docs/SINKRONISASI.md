# Sinkronisasi Opsional (Supabase + Google) dan Versi Web

Dokumen ini menjelaskan cara menyalakan fitur cloud yang **opsional** di
Spendly, beserta batasan versi web. Aturan perilakunya ada di
[`SPEC.md`](SPEC.md) §5.16.

Singkatnya: **aplikasi tetap 100% lokal tanpa langkah apa pun di sini.** Tanpa
kredensial Supabase, tidak ada plugin autentikasi yang dimuat, tidak ada
permintaan jaringan, dan halaman Sinkronisasi hanya menjelaskan bahwa fitur ini
belum aktif pada build tersebut.

---

## 1. Apa yang disinkronkan

| Tabel | Ikut | Alasan |
| --- | :---: | --- |
| `wallets` | ya | Rekening adalah induk transaksi |
| `debts` | ya | Catatan hutang piutang |
| `budgets` | ya | Anggaran per kategori/periode |
| `custom_reports` | ya | Rekap kustom tersimpan |
| `transactions` | ya | Seluruh pergerakan uang |
| `debt_entries` | ya | Entri pembayaran/penerimaan hutang |
| `app_settings` | **tidak** | Tema, bahasa, dan pengingat adalah pilihan perangkat |
| `notification_drafts`, `account_notification_mappings` | **tidak** | Notifikasi hanya milik ponsel yang menerimanya |
| `suggestions`, `schema_migrations` | **tidak** | Saran dibangun ulang dari riwayat; migrasi milik perangkat |

Urutan sinkronisasi mengikuti arah kunci asing: rekening, hutang, anggaran,
rekap kustom, transaksi, lalu entri hutang. Dengan begitu baris transaksi tidak
pernah tiba sebelum rekening yang dirujuknya.

Daftar pastinya ada di `lib/data/sync/sync_tables.dart`, dan diuji terhadap
skema SQLite sungguhan di `test/data/sync_tables_test.dart`.

---

## 2. Menyiapkan Supabase

1. Buat proyek di [supabase.com](https://supabase.com). Catat **Project URL**
   dan **publishable/anon key** dari Settings › API. Jangan pernah memakai
   `service_role` di aplikasi.
2. Buka **SQL Editor**, tempel seluruh isi [`supabase/schema.sql`](../supabase/schema.sql),
   lalu jalankan. Berkas itu membuat enam tabel, index `(user_id, updated_at)`,
   dan kebijakan Row Level Security untuk select/insert/update/delete.
3. Periksa di **Table Editor** bahwa keenam tabel muncul dan RLS-nya aktif.

Skema cloud memakai nama kolom yang sama persis dengan SQLite lokal. Uang dan
waktu disimpan sebagai `bigint` (epoch milidetik / rupiah utuh), dan boolean
sebagai `smallint` 0/1, sehingga nilai bolak-balik tidak berubah tipe.

---

## 3. Menyalakan login Google

1. Di **Google Cloud Console** › APIs & Services › Credentials, buat
   **OAuth client ID** bertipe *Web application*.
2. Tambahkan **Authorized redirect URI**:
   `https://<project-ref>.supabase.co/auth/v1/callback`
   (bukan alamat aplikasi; Supabase yang menerima kode dari Google lebih dulu).
3. Di Supabase Dashboard › **Authentication › Providers › Google**, aktifkan
   provider dan tempel Client ID serta Client Secret.
4. Di **Authentication › URL Configuration**:
   - **Site URL**: alamat produksi aplikasi web, mis. `https://spendly.example.com/`.
   - **Redirect URLs** (satu per baris):
     - `https://spendly.example.com/**` — versi web produksi
     - `http://localhost:*/**` — pengembangan web (`flutter run -d chrome`)
     - `io.supabase.spendly://login-callback` — Android dan iOS

Skema `io.supabase.spendly` sudah terdaftar di
`android/app/src/main/AndroidManifest.xml` dan `ios/Runner/Info.plist`. Bila
skema itu diubah, ubah juga `SyncConfig.callbackScheme` dan daftar Redirect URL.

---

## 4. Membangun aplikasi dengan kredensial

Kredensial **tidak** ditulis di kode. Keduanya diberikan saat build:

```powershell
flutter run -d <serial-hp> `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Build tanpa dua `--dart-define` itu tetap sah dan tetap bisa dipakai; halaman
Sinkronisasi akan berbunyi "Belum aktif di build ini".

Halaman Sinkronisasi dibuka dari **Pengaturan › Sinkronisasi & Akun**. Di sana
pengguna bisa masuk dengan Google, menekan **Sinkronkan sekarang**, melihat
waktu sinkronisasi terakhir, dan keluar. Keluar **tidak** menghapus data lokal.

---

## 5. Cara kerja sinkronisasi

Satu putaran berjalan per tabel, berurutan:

1. **Tarik** baris cloud dengan `updated_at` lebih besar dari penanda terakhir
   (`sync.pull.<tabel>`), dipecah 500 baris per permintaan.
2. **Gabungkan** dengan SQL `INSERT ... ON CONFLICT(id) DO UPDATE ... WHERE
   excluded.updated_at > <tabel>.updated_at`. Versi cloud hanya menang bila
   benar-benar lebih baru.
3. **Kirim** baris lokal yang berubah sejak penanda kirim (`sync.push.<tabel>`),
   200 baris per permintaan, dengan `upsert(onConflict: 'id')`.
4. **Simpan** penanda baru dan waktu sinkronisasi terakhir di `app_settings`.

Aturan konfliknya **last write wins** menurut `updated_at`, dengan toleransi
120 detik agar jam perangkat yang sedikit mundur tidak melewatkan baris.
Penghapusan memakai hapus lunak, jadi `deleted_at` ikut berpindah dan baris
yang dihapus di satu perangkat juga hilang di perangkat lain.

Beberapa hal yang disengaja:

- **Tidak ada sinkronisasi latar.** Pengguna yang menekan tombol, pengguna yang
  menunggu hasilnya. Lebih mudah dijelaskan dan tidak menguras baterai.
- **Akun berbeda tidak digabung diam-diam.** Bila basis data ini terakhir
  dipakai akun Google lain, muncul dialog "Akun berbeda" dengan pilihan
  **Pakai akun ini** (data lokal diunggah ke akun baru) atau batal.
- **Sinkronisasi bukan pengganti backup.** Data lokal tetap yang utama.

Bila sinkronisasi gagal, pesan yang tampil dibedakan: sesi login berakhir, cloud
menolak permintaan, atau kesalahan lain. Tidak ada data lokal yang dihapus saat
gagal.

---

## 6. Versi web

### Membangun

```powershell
flutter build web --release `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Hasilnya di `build/web/`. Dua berkas berikut **wajib** ikut terunggah; keduanya
disalin dari paket `drift` di pub cache dan sudah ada di `web/`:

- `sqlite3.wasm`
- `drift_worker.js`

Berkas itu harus disajikan dengan `Content-Type` yang benar (`application/wasm`
untuk wasm, JavaScript untuk worker). Sebagian server statis sudah benar secara
bawaan; periksa setelah deploy.

### Penyimpanan di peramban

Basis data web memakai SQLite WebAssembly. Drift memilih penyimpanan terbaik
yang didukung peramban: OPFS (lewat FileSystem Access API), lalu IndexedDB,
lalu memori. Untuk OPFS yang cepat dan aman antar-tab, server sebaiknya
mengirim:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Tanpa dua header itu aplikasi tetap berjalan, hanya lebih lambat. Perhatikan
dua akibat sampingnya: sebagian popup pihak ketiga (termasuk beberapa alur
Google Identity) bisa terganggu, dan Safari 16 punya bug cache worker. Ujilah
login Google di peramban target sebelum memutuskan menyalakannya. Fitur ini
memakai pengalihan OAuth biasa (bukan popup), jadi umumnya aman.

### Batasan web yang perlu diketahui

| Hal | Di web |
| --- | --- |
| Scan AI (OCR) | **Tidak tersedia.** ML Kit hanya untuk Android/iOS. Tab Scan AI menjelaskan hal ini |
| Auto-capture notifikasi | Tidak berlaku (hanya Android) |
| Data | Tersimpan di peramban itu saja (OPFS/IndexedDB). Pindah perangkat lewat sinkronisasi |
| Tab ganda | Aman bila OPFS/IndexedDB shared worker aktif; mode `unsafeIndexedDb` tidak aman untuk banyak tab |
| Mode privat | Firefox tidak mendukung FileSystem Access API di jendela privat; drift turun ke IndexedDB atau memori |
| Ekspor/impor berkas | Memakai unduhan dan pemilih berkas peramban, bukan jalur berkas ponsel |

Login web kembali ke **asal halaman** (`Uri.base.origin`). Karena itu alamat
produksi harus terdaftar di Redirect URLs Supabase; alamat `localhost` dengan
port berapa pun sudah dicakup wildcard `http://localhost:*/**`.

---

## 7. Yang belum diuji

Bagian ini jujur tentang batas verifikasi sejauh ini:

- Alur login Google belum diuji ujung-ke-ujung karena kredensial Supabase/Google
  belum tersedia saat fitur ini dibangun.
- Versi web sudah **berhasil dikompilasi** (`flutter build web --release`),
  tetapi belum dijalankan di peramban sungguhan: OPFS, tautan balik OAuth, dan
  header COOP/COEP belum diamati langsung.
- Sinkronisasi antarperangkat belum diuji dengan dua perangkat fisik.
- Auto-capture notifikasi sudah punya unit test parser dan widget test, tetapi
  belum diuji pada ponsel dengan notifikasi bank sungguhan.

Yang **sudah** diuji otomatis: paritas kolom tabel sinkronisasi dengan skema
SQLite, aturan *last write wins* dijalankan langsung pada SQLite di memori,
penjagaan konfigurasi, parser teks mutasi Scan AI, dan layar pratinjau Scan AI.

---

## 8. Daftar periksa sebelum rilis

- [ ] `supabase/schema.sql` sudah dijalankan di proyek produksi.
- [ ] RLS aktif pada keenam tabel; coba `select` tanpa login harus kosong.
- [ ] Redirect URL produksi dan `io.supabase.spendly://login-callback` terdaftar.
- [ ] Build membawa `SUPABASE_URL` dan `SUPABASE_ANON_KEY`; kunci yang dipakai
      bukan `service_role`.
- [ ] Login, sinkronisasi, dan keluar diuji di Android dan di web.
- [ ] Dua perangkat dengan akun sama: tambah transaksi di A, sinkronkan di B.
- [ ] Hapus transaksi di B, sinkronkan di A; baris hilang di kedua tempat.
- [ ] `sqlite3.wasm` disajikan sebagai `application/wasm` di server.
- [ ] Halaman Sinkronisasi tetap bisa dibuka pada build **tanpa** kredensial.
