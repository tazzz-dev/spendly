# Rencana Pembangunan

Pendamping `docs/SPEC.md` dan `docs/DATA-MODEL.md`. Isinya keputusan teknis dan
urutan pekerjaan.

## 1. Keputusan teknis

### Sudah bisa dipastikan

| Aspek | Pilihan | Alasan |
| --- | --- | --- |
| Bahasa & kerangka | Flutter 3.47.7 / Dart 3.13.5 (stable) | Satu basis kode untuk Android dan iOS, sesuai keputusan awal |
| Basis data | **drift** (di atas SQLite) | Rancangan di `DATA-MODEL.md` mengasumsikannya. Keunggulan dibanding sqflite mentah: query bertipe, migrasi terkelola, dan `watch()` yang memancarkan perubahan otomatis |
| Query reaktif | `drift` + `Stream` | Saldo dan rekap harus ikut berubah begitu transaksi disimpan. Ini kebutuhan inti, bukan kemewahan |
| Routing | `go_router` | Navigasi bertipe, cocok untuk lima tab + halaman detail |
| Grafik | **`fl_chart`** (lisensi MIT) | Menggantikan Syncfusion yang berlisensi komersial. Lihat SPEC L-12 |
| Lokalisasi | `flutter_localizations` + `gen-l10n` (berkas ARB) | Bawaan Flutter, tanpa pustaka pihak ketiga. Menggantikan `easy_localization` milik Sepran |
| Ekspor PDF | `pdf` (Apache-2.0) | |
| Ekspor CSV | `csv` (MIT) | Format gratis tanpa batas, sesuai SPEC X-5 |
| Ikon | `font_awesome_flutter` | |
| Suara | `speech_to_text` | Untuk input judul dengan suara (SPEC T-6) |
| Notifikasi | `flutter_local_notifications` | Pengingat harian (SPEC ST-6) |
| Pengenal | `uuid` v4 | Sesuai DATA-MODEL |
| Tanggal | `intl` | Format `dd MMM yyyy` dan pemisah angka gaya Indonesia |
| OCR (Scan AI) | `google_mlkit_text_recognition` | Membaca teks tangkapan layar **di perangkat**, tanpa mengirim gambar ke server (SPEC SC-3) |
| Pemilih gambar | `image_picker` | Galeri (banyak sekaligus) dan kamera, dengan izin bawaan platform |
| Sinkronisasi opsional | `supabase_flutter` (Auth Google + PostgREST) | Postgres + Row Level Security tanpa server sendiri; klien tetap memakai SQLite lokal sebagai sumber utama (SPEC §5.16) |
| Web | `drift_flutter` + SQLite WebAssembly | Basis data yang sama di peramban (OPFS/IndexedDB); dua berkas `sqlite3.wasm` dan `drift_worker.js` disalin ke `web/` |

### Keputusan tambahan

| Aspek | Pilihan | Alasan |
| --- | --- | --- |
| **Manajemen status** | **Riverpod** | `StreamProvider` berpasangan alami dengan `drift.watch()`, sehingga saldo ikut berubah otomatis begitu transaksi disimpan. Lebih sedikit berkas per fitur daripada BLoC. Karena `domain/` tidak bergantung pada pilihan ini, menggantinya nanti tidak akan membongkar logika bisnis |

Tidak ada keputusan yang masih menggantung.

Keputusan lain yang sudah terkunci di dokumen lain dan tidak dibuka lagi: uang
sebagai integer (SPEC G-11), pindah saldo dua baris (SPEC S-7), hapus lunak
(SPEC T-8), tanggal sebagai teks lokal (SPEC G-4).

## 2. Struktur folder

```
lib/
  app/            main.dart, tema (4 tema), router, lokalisasi
  core/           format uang & tanggal, konstanta, util, tipe hasil, kegagalan
  data/           satu database drift: tabel, DAO, migrasi, repository
    sync/         sinkronisasi Supabase opsional (konfigurasi, tabel, layanan)
  domain/         kalkulasi saldo, rekap, aturan hutang  <-- MURNI, tanpa Flutter
  features/
    wallets/      layar & widget rekening
    transactions/ layar transaksi, empat form jenis
    reports/      rekap realtime, bulanan, custom, tren aset
    debts/        hutang, detail, entri
    notifications/ inbox, konfirmasi, dan pengaturan auto-capture
    scan/         Scan AI: pilih gambar, pratinjau, simpan massal
    settings/     pengaturan, tema, bahasa, backup, ekspor, sinkronisasi
    onboarding/   pilih tema, izin notifikasi, tur
  l10n/           app_id.arb, app_en.arb, app_th.arb
supabase/
  schema.sql      tabel cloud, index, dan kebijakan RLS
web/              index.html, manifest, sqlite3.wasm, drift_worker.js
test/
  domain/         test murni untuk invarian SPEC §6
  data/           test migrasi, DAO, dan aturan penggabungan sinkronisasi
```

Yang penting: **`domain/` tidak boleh mengimpor Flutter.** Seluruh kalkulasi
saldo dan rekap tinggal di situ sebagai fungsi murni, sehingga invarian §6 bisa
diuji cepat tanpa emulator atau basis data.

## 3. Urutan pekerjaan

| # | Langkah | Keluaran | Butuh screenshot? |
| --- | --- | --- | --- |
| 1 | Fondasi | `flutter create`, skema drift 9 tabel, migrasi v1, empat tema, router. Aplikasi kosong yang bisa dibuka | tidak |
| 2 | Uang & tanggal | Formatter dan parser gaya Indonesia, dengan test. Selesai bila `Rp1.234.567` dan `1.234,567` sama-sama lulus | tidak |
| 3 | Rekening | CRUD, Total Saldo, rekening default, urutan frekuensi, larangan hapus | tidak |
| 4 | Domain kalkulasi | Rumus saldo SPEC §4 sebagai fungsi murni + test property-based untuk INV-1, INV-4, INV-5 | tidak |
| 5 | Transaksi | Empat jenis pergerakan, form, daftar harian, saran judul & kategori, kalkulator, input suara | tidak |
| 6 | Rekap | Realtime, Bulanan, Custom, rincian per kategori & judul, tren aset | **A, B, C** |
| 7 | Hutang | Daftar, dua total, halaman detail, entri bertanda | **E, F** |
| 8 | Pengaturan | Empat tema, tiga bahasa, angka desimal, pengingat, hapus data | tidak |
| 9 | Ekspor & backup | CSV gratis, backup dan pemulihan lokal berkas | tidak |
| 10 | Fitur pembeda | Anggaran, pencarian lanjutan, ringkasan bulanan otomatis | tidak |

**Status: langkah 1 sampai 4 selesai, langkah 5 berjalan, langkah 6 selesai,
langkah 8 baru sebagian.** Sembilan tabel dan tujuh index terbentuk, rekening
bawaan dibuat otomatis saat pemasangan pertama, format uang dan tanggal lulus
test, tab Rekening sudah menampilkan saldo dari basis data sungguhan, dan
rekening kini bisa ditambah, disunting, serta dihapus — dengan penolakan yang
disertai alasan untuk rekening bawaan dan rekening yang masih dipakai.

Langkah 4 menaruh seluruh rumus pergerakan uang sebagai fungsi murni di
`lib/domain/`, lengkap dengan test acak bersemai tetap untuk INV-1, INV-4, dan
INV-5. Langkah 5 sudah punya kerangka layar Transaksi, tetapi pembagian
pekerjaannya kini dipecah ke sesi terpisah, bersama Rekening dan Pengaturan.

### Gelombang pertama: tiga sesi berdampingan

Langkah 3, 5, 7, dan 8 dipecah ke empat worktree Orca yang berdampingan.
Tujuannya sederhana: dua sesi tidak boleh menyunting berkas yang sama pada saat
yang sama. Tiga sesi pertama bercabang dari commit basis `816a900`; sesi Hutang
bercabang dari `main` setelah catatan gelombang ini ditulis.

| Sesi | Modul | Cabang | Worktree | Model |
| --- | --- | --- | --- | --- |
| `modul_1` | Rekening (langkah 3) | `modul_1` | `<worktree-lokal>/modul_1` | DeepSeek V4.1 Flash Free |
| `modul_2` | Transaksi (langkah 5) | `modul_2` | `<worktree-lokal>/modul_2` | DeepSeek V4.1 Flash Free |
| `modul_3` | Pengaturan (langkah 8) | `modul_3` | `<worktree-lokal>/modul_3` | DeepSeek V4.1 Flash Free |
| `modul_4` | Hutang (langkah 7) | `modul_4` | `<worktree-lokal>/modul_4` | DeepSeek V4.1 Flash Free |

Aturan yang dipegang ketiganya:

- Hanya `modul_1` yang memakai HP. Satu perangkat untuk tiga sesi berarti harus
  ada satu pemilik.
- Tiap sesi hanya menyunting wilayah modulnya sendiri.
- Berkas bersama dibekukan: `lib/app/`, `lib/core/`, `lib/data/providers.dart`,
  seluruh `docs/`, dan `pubspec.yaml` kecuali penambahan baris baru.
- Satu pengecualian sempit: `modul_4` boleh menyentuh `lib/app/app.dart`, tetapi
  hanya untuk mengganti placeholder tab Hutang dengan layar sungguhan, menghapus
  kelas placeholder yang jadi tidak terpakai, dan memperluas syarat bilah judul
  bila layarnya membawa bilah sendiri. Tidak ada yang lain.
- Provider baru ditaruh di berkas milik modul, bukan di `lib/data/providers.dart`.

Dua hal praktis yang perlu diketahui siapa pun yang meneruskan pekerjaan ini:
worktree baru belum punya konfigurasi paket, jadi tiap sesi harus menjalankan
`flutter pub get` lebih dulu; dan model dipilih lewat `opencode.json` di akar tiap
worktree, bukan lewat `orca agent launch --model`, karena host Orca ini menolak
pemilihan model OpenCode. Berkas itu dikecualikan dari git lewat
`.git/info/exclude`.

`modul_3` awalnya memakai GLM-5.3 Flash Free. Titik akhir penyedianya berulang
kali menjawab `Endpoint is unavailable`, jadi sesinya dialihkan ke DeepSeek V4.1
Flash Free. Ketiga sesi kini memakai model yang sama.

Penggabungan empat cabang itu belum dijadwalkan dan masih menjadi pekerjaan
pemilik proyek. `pubspec.lock` hampir pasti bentrok dan cukup dibangkitkan ulang.

**Langkah 6 (Rekap) selesai dibangun.** Tampilannya mengikuti susunan Sepran:
tab **Realtime**, **Bulanan**, dan **Custom**, lalu rincian per kategori dan per
judul dengan baris "Lainnya", rata-rata per hari, dan halaman **Tren Aset**.
Ikon gerigi di kanan atas membuka **Konfigurasi Rekap** yang hanya punya dua
setelan (Tanggal Mulai dan Saldo Akumulasi), persis SPEC L-7. Grafik memakai
**`fl_chart`** (MIT) — pilihan yang sudah dikunci di §1 di atas, dan diperiksa
lisensinya sesuai SPEC L-12.

Seluruh angka rekap mengalir dari satu sumber: `ReportRepository.watchDailyTotals()`
meringkas mutasi per hari di SQL, lalu `domain/` menghitung kartu bulanan,
rekap kustom, dan Tren Aset dari ringkasan yang sama. Karena itu pindah saldo
otomatis tidak pernah muncul sebagai pemasukan atau pengeluaran (SPEC M-2, L-10,
INV-6), dan satu pembayaran hutang tidak mungkin terhitung dua kali.

Yang tertinggal dari langkah 1: **tiga berkas bahasa**. Awalnya ditempatkan di
langkah 1, kini dipindahkan ke langkah 8 bersama tiga bahasa, karena seluruh teks
kini masih berbahasa Indonesia dan tidak ada pekerjaan lain yang terhambat
karenanya.

Langkah 1 sampai 5 **tidak terhambat** oleh verifikasi yang belum selesai.
Jadi pembangunan bisa jalan sambil kamu mengumpulkan screenshot A sampai G.

### Tambahan setelah inti: auto-capture, Scan AI, sinkronisasi, cold start

Empat pekerjaan menyusul setelah modul inti berdiri. Semuanya bersifat
**tambahan**: aplikasi tetap bisa dipakai penuh tanpa satu pun di antaranya.

1. **Auto-capture notifikasi Android** (SPEC §5.14). Layanan pendengar menulis
   draft lewat isolate latar, bertahan setelah reboot lewat `SpendlyBootReceiver`,
   dan halaman Pengaturan memberi panduan baterai/auto-start per merek. Inbox
   draft bisa ditarik untuk menyegarkan dan menyedot antrean mentah dari sisi
   Android.
2. **Scan AI** (SPEC §5.15). `image_picker` memilih gambar, ML Kit membaca teks
   di perangkat, `MutationTextParser` dan `CategoryGuesser` di `domain/`
   mengubahnya menjadi baris yang bisa disunting, lalu `createMany` menyimpan
   baris yang dicentang dalam satu transaksi basis data.
3. **Sinkronisasi opsional** (SPEC §5.16). Supabase hanya dinyalakan saat
   halaman Sinkronisasi dibuka. Skema cloud ada di `supabase/schema.sql`, mesin
   penggabungan di `lib/data/sync/`. Rincian pemasangan di
   `docs/SINKRONISASI.md`.
4. **Cold start dan navigasi.** Tab dibangun malas, riwayat dipaginasi dan
   dicari di SQL, mesin OCR/autentikasi tidak dimuat saat buka, dan Pengaturan
   pindah ke ikon roda gigi di header agar tab bawah memuat **Scan AI**.

## 4. Daftar layar

| Modul | Layar |
| --- | --- |
| Onboarding | Pilih tema, minta izin notifikasi, tur pengenalan |
| Kerangka | Lima tab: Transaksi, Rekening, Rekap, Hutang, Scan AI; Pengaturan lewat ikon roda gigi di header |
| Transaksi | Daftar harian (dengan pindah hari), form pemasukan, form pengeluaran, form pindah saldo, form koreksi saldo, ringkasan harian, salin transaksi |
| Rekening | Daftar rekening, form rekening, detail rekening |
| Hutang | Daftar hutang (dengan pencarian bersuara), form catatan, halaman detail dengan daftar entri, form entri |
| Rekap | Realtime, Bulanan, Custom, rincian, tren aset, pengaturan rekap |
| Notifikasi | Inbox draft, konfirmasi draft, pengaturan akses & pemetaan rekening |
| Scan AI | Pilih gambar/foto, pratinjau hasil baca, simpan massal |
| Pengaturan | Pengaturan utama, tema, bahasa, pengingat, backup & restore, hubungi, tentang, Notifikasi Otomatis, Sinkronisasi & Akun |

## 5. Lisensi pustaka

Semua pilihan di atas berlisensi permisif (MIT, BSD, Apache-2.0). Yang **tidak**
dipakai dan alasannya:

| Pustaka | Kenapa dihindari |
| --- | --- |
| Syncfusion (grafik, PDF, Excel) | Komersial. Ada lisensi Community gratis, tapi syaratnya membatasi |
| AdMob, in_app_purchase, Firebase | Menambah SDK besar dan urusan kepatuhan. Ditunda sesuai SPEC O-9 dan B-9 |
| easy_localization | Bukan lisensi masalah, tapi `gen-l10n` bawaan sudah cukup dan tidak menambah dependensi |

## 6. Pengujian

| Tingkat | Isi |
| --- | --- |
| Unit — `domain/` | Invarian SPEC §6. Termasuk property-based test untuk saldo: bangkitkan urutan operasi acak, bandingkan saldo hasil rumus ulang dengan saldo berjalan (SPEC INV-1, INV-4, INV-5) |
| Unit — `core/` | Format dan parse uang, termasuk kasus desimal nyala/mati |
| Unit — `core/` & `domain/` (Scan AI) | Parser teks mutasi: tanggal, jam, nominal, arah uang, dan tebakan kategori |
| Unit — `data/sync` | Paritas kolom `sync_tables.dart` dengan skema SQLite, aturan *last write wins* dijalankan langsung pada SQLite di memori, dan penjagaan konfigurasi |
| Widget | Form transaksi: validasi empat field wajib, perpindahan fokus, kalkulator. Pratinjau Scan AI: hanya baris dicentang yang tersimpan, dompet wajib dipilih |
| Integrasi — `data/` | Migrasi dari skema kosong ke versi terbaru, dan pemulihan berkas backup dari versi berbeda |

Jumlah test saat dokumen ini diperbarui: **447 lulus**, `flutter analyze`
bersih.

Prinsip: test yang mahal (integrasi) dibuat sedikit. Sebagian besar nilai ada di
`domain/` dan `core/`, dan keduanya murah diuji.

## 7. Konvensi penamaan

| Hal | Aturan |
| --- | --- |
| Berkas | `snake_case.dart` |
| Kelas | `PascalCase` |
| Nama tabel | jamak, `snake_case`: `wallets`, `transactions`, `debt_entries` |
| Nama kolom | `snake_case`, sesuai `DATA-MODEL.md` |
| Kode aturan | Selalu rujuk balik ke `SPEC.md`: mis. `// SPEC T-1` |
| Nominal | Selalu `int` dalam rupiah utuh. Tidak ada `double` di jalur uang |
