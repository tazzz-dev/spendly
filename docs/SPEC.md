# Spesifikasi Fungsional — Aplikasi Pencatatan Keuangan

Versi 1.1 · Dasar: analisis statis **Sepran 5.2.2** (Flutter 3.11.3) · Bukti lengkap: `_apk/_analysis/TEMUAN.md` · Fitur tambahan kita ada di §5.14–§5.16

## 0. Cara membaca dokumen ini

Versi ini bukan lagi kumpulan dugaan. Isinya berasal dari skema database,
struktur paket, daftar dependensi, dan inventaris teks UI aplikasi Sepran yang
dibaca langsung dari berkas APK-nya. Setiap butir punya penanda sumber:

| Penanda | Arti |
| --- | --- |
| `[x]` | **Terverifikasi dari APK Sepran.** Begini cara Sepran bekerja. Ikuti bila ingin paritas. |
| `[?]` | **Belum terverifikasi.** Terlihat jejaknya, tapi artinya perlu dipastikan dengan mengamati aplikasi di HP. |
| `[★]` | **Keputusan kita.** Sengaja menyimpang dari Sepran, dengan alasan yang ditulis di tempat itu. |

Aturan: jangan mengimplementasikan butir `[?]` sebagai keputusan final. Butir
`[★]` boleh diubah, tapi baca alasannya dulu.

Dokumen pendamping: `docs/DATA-MODEL.md` (rancangan tabel untuk aplikasi kita)
dan `docs/RENCANA-BUILD.md` (keputusan teknis dan urutan pekerjaan).

---

## 1. Tujuan dan prinsip

Aplikasi pencatatan keuangan pribadi yang **berperilaku sama** dengan Sepran,
lalu ditambah fitur sendiri.

| # | Prinsip | Asal |
| --- | --- | --- |
| P1 | Offline-first. Seluruh data di SQLite lokal. Tidak ada permintaan jaringan di jalur kritis. | `[x]` Sepran pakai `sqflite` |
| P2 | Catat cepat: jumlah, judul, kategori, rekening. Tidak lebih. | `[x]` pesan validasi Sepran hanya menyebut empat field itu |
| P3 | Rekening default selalu ada, sehingga pengguna tidak pernah "tidak bisa mencatat". | `[x]` ada rekening default yang tidak boleh dihapus |
| P4 | Uang pengguna milik pengguna: ekspor penuh, backup tanpa terkunci. | `[★]` |
| P5 | Fitur berbayar tidak boleh menyandera data. Iklan boleh, tapi mengekspor data sendiri harus selalu bisa. | `[★]` Sepran mengunci ekspor Excel/PDF di balik pembelian |

---

## 2. Glosarium

| Istilah | Definisi |
| --- | --- |
| **Rekening** | Wadah uang. Sepran menyebutnya "Rekening", bukan "Dompet". |
| **Transaksi** | Satu pencatatan pemasukan atau pengeluaran. |
| **Judul** | Nama singkat transaksi. **Wajib diisi.** `[x]` |
| **Kategori** | Pengelompokan transaksi. **Wajib diisi**, bersifat teks bebas dengan saran otomatis. `[x]` |
| **Keterangan** | Catatan bebas. Opsional. `[x]` |
| **Pindah Saldo** | Pemindahan uang antar rekening. Bukan pemasukan/pengeluaran. `[x]` |
| **Koreksi Saldo** | Penyesuaian manual terhadap saldo rekening. Jenis transaksi tersendiri. `[x]` |
| **Hutang Piutang** | Catatan uang yang dipinjam atau dipinjamkan. |
| **Cicilan** | Satu baris pembayaran pada catatan hutang. |
| **Rekap** | Laporan. Sepran punya tiga jenis: Realtime, Bulanan, Custom. `[x]` |
| **Saldo Awal / Saldo Akhir** | Saldo rekening di awal dan di akhir rentang rekap. `[x]` |
| **Selisih** | Pemasukan dikurangi pengeluaran dalam rentang. `[x]` |
| **Sisa Saldo** | Saldo akhir setelah seluruh pergerakan dalam rentang. `[x]` |
| **Tren Aset** | Grafik perkembangan total saldo sepanjang waktu. `[x]` |

---

## 3. Aturan global

| Kode | Aturan | Sumber |
| --- | --- | --- |
| G-1 | Nominal ditampilkan `Rp1.234.567`. Pemisah ribuan titik. | `[x]` |
| G-2 | Ada setelan **"Tampilkan Angka Desimal"** (nyala/mati), **aktif secara bawaan**. Format angka: ribuan dipisah **titik**, desimal dipisah **koma**, dua angka di belakang koma. Contoh `10.000,00`. | `[x]` |
| G-3 | Input nominal memakai kalkulator bawaan di dalam aplikasi, bukan sekadar keyboard angka. | `[x]` widget `calculator` |
| G-4 | Tanggal transaksi disimpan sebagai **teks lokal `YYYY-MM-DD`**. Alasannya: Indonesia tidak memakai DST, dan pengelompokan per hari serta pengurutan jadi sepele. Jam disimpan terpisah sebagai kolom `time` opsional. | `[★]` Sepran menyimpan epoch ms (`INTEGER`) plus kolom `time` terpisah |
| G-5 | Jam bersifat opsional; kolom `time` baru ditambahkan belakangan pada sebagian besar tabel. | `[x]` jejak migrasi |
| G-6 | Ada **empat tema berwarna**: Biru Terang, Mode Pink, Mode Ungu, Mode Gelap. Dipilih saat pertama membuka aplikasi. | `[x]` |
| G-7 | Bahasa: Indonesia, Inggris, Thailand. | `[x]` |
| G-8 | Harus selalu ada satu rekening default. Rekening itu hanya bisa diedit, tidak bisa dihapus. | `[x]` |
| G-9 | Nama rekening harus unik. | `[x]` |
| G-10 | Menekan tombol kembali sekali lagi untuk keluar dari aplikasi (bukan langsung keluar). | `[x]` |
| G-11 | Uang disimpan sebagai **bilangan bulat** dalam satuan rupiah utuh, bukan `REAL`. | `[★]` Sepran memakai `REAL` (floating point). Lihat §5.1 untuk alasan kita tidak meniru. |
| G-12 | Kolom **input** nominal memisahkan ribuan dengan titik saat pengguna mengetik, mulai dari seribu: `1000` tampil `1.000`, `1000000` tampil `1.000.000`. Pemisah yang ditempel (titik atau koma) dibuang lalu dikelompokkan ulang. Kursor dijaga di posisi relatif terhadap digit. Nilai tersimpan tetap bilangan bulat (G-11). | `[★]` |

---

## 4. Empat jenis pergerakan uang

Ini fondasi seluruh aplikasi. Sepran menyimpannya di **empat tabel terpisah**.

| Jenis | Field khas | Efek saldo | Tabel Sepran |
| --- | --- | --- | --- |
| **Pemasukan** | tanggal, jumlah, judul, kategori, keterangan, rekening | **+** pada rekening | `data_harian` (`jenisTransaksi=1`) `[x]` |
| **Pengeluaran** | sama seperti pemasukan | **−** pada rekening | `data_harian` (`jenisTransaksi=2`) `[x]` |
| **Pindah Saldo** | tanggal, jumlah, rekening asal, rekening tujuan, keterangan | **−** asal, **+** tujuan | `balance_transfer` `[x]` |
| **Koreksi Saldo** | tanggal, jumlah, rekening, keterangan | **±** menyesuaikan | `balance_correction` `[x]` |
| **Cicilan Hutang** | tanggal, jumlah, rekening (opsional), keterangan | **±** pada rekening | `hutang_detail` `[x]` |

Rumus saldo rekening — **terverifikasi** dari nama method di dalam aplikasi:

```
saldo(rekening) = saldo_awal
                + Σ pemasukan
                − Σ pengeluaran
                − Σ pindah saldo keluar
                + Σ pindah saldo masuk
                + Σ koreksi saldo
                + Σ cicilan hutang
```

Nama method aslinya: `getBalanceFromIncomes`, `getBalanceFromExpenses`,
`getBalanceFromBalanceTransferWalletSource`,
`getBalanceFromBalanceTransferWalletDestination`,
`getBalanceFromBalanceCorrection`, `getBalanceFromLoan`.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| M-1 | Saldo rekening dihitung dari rumus di atas, tidak disimpan sebagai angka yang diperbarui manual. | `[x]` ada method terpisah per komponen |
| M-2 | Pindah Saldo tidak pernah dihitung sebagai pemasukan atau pengeluaran di rekap. | `[x]` |
| M-3 | Rekening asal dan tujuan Pindah Saldo harus berbeda. | `[★]` pewarisan logika; Sepran tidak memvalidasi ini secara eksplisit di skema |
| M-4 | Rekening pada Cicilan Hutang **opsional**. Bila kosong, cicilan tidak memengaruhi saldo mana pun. | `[x]` "Pilih Rekening (tidak wajib diisi)" |
| M-5 | Menghapus rekening hanya boleh bila tidak ada pergerakan yang memakainya. | `[x]` pesan galat Sepran |

---

## 5. Modul fitur

### 5.1 Rekening

**Field Sepran:** `id, name, walletTypeDesc, balance, frequentlyUsed, currency, icon, createdAt, updatedAt`

| Kode | Aturan | Sumber |
| --- | --- | --- |
| R-1 | Field yang dilihat pengguna: Nama (wajib, unik), Saldo, Tipe, Ikon, Mata uang. | `[x]` |
| R-2 | Daftar rekening menampilkan **Total Saldo** di bagian atas. | `[x]` |
| R-3 | Urutan daftar mengikuti frekuensi pemakaian. Rekening yang baru dipakai melompat ke atas dengan jarak jauh (Sepran menambah `+11` pada penghitungnya, bukan `+1`). | `[x]` |
| R-4 | Rekening tidak dapat dihapus bila masih dipakai pergerakan apa pun. Pesannya mengarahkan pengguna menghapus transaksinya dulu. | `[x]` |
| R-5 | Rekening default tidak dapat dihapus, hanya diedit. | `[x]` |
| R-6 | Ada kolom `currency`, tetapi belum terlihat dipakai di UI. Kita siapkan fieldnya, tidak dipakai di versi pertama. | `[?]` |
| R-7 | Tipe rekening disimpan sebagai teks (`walletTypeDesc`) dan dipetakan lewat fungsi `walletTypeFromString`. | `[x]` |
| R-8 | Saldo disimpan `REAL` (floating point). | `[x]` |
| R-9 | **Kita simpan saldo sebagai integer rupiah utuh.** Alasannya: seluruh perhitungan saldo jadi aritmetika bilangan bulat, bebas dari galat pembulatan. Setelan "Tampilkan Angka Desimal" tetap kita sediakan untuk tampilan, tapi tidak mengubah cara penyimpanan. | `[★]` |
| R-10 | **Keunikan nama ditegakkan index unik parsial** (`WHERE deleted_at IS NULL`), bukan `unique()` pada kolomnya. Kalau keunikannya berlaku untuk seluruh baris, nama rekening yang sudah dihapus tidak akan pernah bisa dipakai lagi — padahal kita memakai hapus lunak. Lihat DATA-MODEL RW-13. | `[★]` |
| R-11 | Rekening mana yang berperan sebagai default **belum bisa dipilih pengguna**. Rekening bawaan dari pemasangan pertama yang memegang peran itu. Belum terlihat apakah Sepran punya pengaturan semacam itu. | `[?]` |

### 5.2 Transaksi (Pemasukan dan Pengeluaran)

**Field Sepran:** `id, tanggal, jumlah, judul, kategori, idWallet, keterangan, jenisTransaksi, time, createdAt, updatedAt`

| Kode | Aturan | Sumber |
| --- | --- | --- |
| T-1 | Empat field wajib: **jumlah, judul, kategori, rekening**. Pesan Sepran: "Jumlah, judul, kategori, dan rekening harus diisi." | `[x]` |
| T-2 | Keterangan opsional. Placeholder: "Keterangan (tidak wajib diisi)". | `[x]` |
| T-3 | `jenisTransaksi`: **1 = pemasukan, 2 = pengeluaran**. | `[x]` |
| T-4 | Jumlah harus > 0. Sepran menyimpan `jumlah` positif di kedua jenis; tanda ditentukan oleh `jenisTransaksi`. | `[x]` |
| T-5 | Ada fitur **Salin Transaksi** yang membuka form terisi dari transaksi yang ada. | `[x]` |
| T-6 | **Tiga field** dapat diisi dengan suara lewat ikon mikrofon di ujung kanannya: **Judul**, **Kategori**, dan **Keterangan**. Bukan hanya judul. | `[x]` |
| T-7 | Konfirmasi hapus: "Apakah Anda yakin akan menghapus transaksi ini?" | `[x]` |
| T-8 | Sepran tidak punya konsep hapus lunak. Penghapusan benar-benar menghapus baris. | `[★]` Kita pakai hapus lunak (`deleted_at`), agar bisa dibatalkan dan aman saat sinkronisasi. Tidak terlihat oleh pengguna, jadi paritas tetap terjaga. |
| T-9 | Urutan daftar: tanggal menurun, lalu waktu. | `[?]` belum dapat dipastikan — tiga baris pada tangkapan layar tidak cukup membedakan urutan waktu dari urutan masukan |
| T-10 | Halaman transaksi bisa dibaca per hari, dengan ringkasan harian dan tombol **Tambah Data**. | `[x]` |
| T-11 | Di daftar transaksi, **kategori** adalah baris utama (tebal, hitam) dan **judul** adalah baris kedua (abu-abu). Nominal pengeluaran bertanda minus. | `[x]` |
| T-12 | Kepala halaman: **`<` Min, 18 Okt 2026 `>`**. Kedua tanda kurung mengapit tanggal dan berfungsi pindah hari. Di bawahnya kartu tiga kolom: **Pemasukan** (hijau), **Pengeluaran**, **Selisih**. | `[x]` |
| T-13 | Dua ikon di kanan atas: **ekspor** (panah ke bawah) dan **ringkasan** (berkas bergaris). | `[x]` |
| T-14 | Tombol `+` membuka **tiga pilihan**, berurutan dari atas: **Pindah Saldo**, **Pemasukan**, **Pengeluaran**. | `[x]` |
| T-15 | **Koreksi Saldo tidak ada di menu ini.** Jadi jenis keempat itu dicapai dari tempat lain. Lihat K-6. | `[x]` |
| T-16 | Warna konsisten di seluruh aplikasi: **oranye = uang masuk**, **merah = uang keluar**, **abu-abu = netral** (pindah saldo). | `[x]` |
| T-17 | Arti **"Selisih"** belum pasti. Pada hari berisi Pemasukan 0,00 dan Pengeluaran 158.000,00 (empat, empat puluh satu, dan seratus tiga belas ribu), Selisih tertulis **158.000,00 tanpa tanda minus**. Jadi bukan sekadar Pemasukan dikurangi Pengeluaran, yang akan bernilai negatif. | `[?]` butuh satu hari yang punya pemasukan **dan** pengeluaran sekaligus |
| T-18 | Susunan form Tambah Transaksi, dari atas: **Tanggal + Jam** berdampingan, **Rekening**, **Jumlah**, **Judul**, **Kategori**, **Keterangan**, lalu tombol **Simpan** rata kanan. Tanggal diawali ikon kalender; jam terisi waktu sekarang. | `[x]` |
| T-19 | Hanya field **Jumlah** yang punya ikon **kalkulator** di ujung kanannya. | `[x]` |
| T-20 | Di bawah field Judul dan Kategori terdapat **deretan tombol saran** (biru penuh, teks putih) berisi nilai yang pernah dipakai. Deretan itu **satu baris** dan hanya menampilkan **tiga saran teratas** saat field kosong; begitu pengguna mengetik, saran menyempit mengikuti teks (pencarian sederhana, tanpa membedakan besar-kecil huruf). Menekan salah satunya mengisi field tersebut. | `[x]` |
| T-21 | Pemilih rekening berupa **panel bawah** (bukan menu tarik-turun di tempat). Kepalanya bertuliskan **"Pilih Rekening"** dengan ikon **pensil** di kanan untuk mengelola rekening. Isinya kotak rekening dalam **tiga kolom**. | `[x]` |
| T-22 | **Pemasukan dan Pengeluaran memakai form yang sama persis.** Yang berbeda hanya isi daftar saran. Terbukti dari dua tangkapan layar: susunan field identik, chip judul dan kategori berbeda. | `[x]` memperkuat C-3 |
| T-23 | Menekan satu baris membuka **halaman Detail Transaksi**, bukan lembar aksi. Bilah atas: kembali, judul "Detail Transaksi", ikon **salin**, **pensil**, dan **tempat sampah**. Isi: lingkaran ikon berwarna, sebutan jenis dalam huruf besar, nominal besar berwarna, `tanggal · jam`, lalu kartu berisi **Rekening, Judul, Kategori** (sebagai lencana), dan **Keterangan**. Warna kepala mengikuti jenis: pengeluaran merah, pemasukan hijau, pindah/koreksi abu-abu. | `[x]` |
| T-24 | Menghapus mengembalikan keadaan sebelum catatan itu dibuat: saldo rekening dan seluruh rekap dihitung ulang tanpa baris tersebut. Sesudah menghapus, tersedia **Urungkan** untuk memulihkannya. | `[★]` turunan dari T-8 (hapus lunak) |
| T-25 | Pensil membuka **form yang sama, terisi** dengan nilai sekarang, berjudul "Ubah Transaksi". Mengubah Pindah Saldo mengubah **kedua sisi** sekaligus supaya saldo tetap seimbang. | `[?]` judul layar ubah di Sepran belum terlihat |
| T-26 | Bila ada lebih dari satu rekening, daftar harian menampilkan **deretan chip filter rekening** (Semua, lalu nama tiap rekening). Memilih satu rekening menyaring baris **dan** kartu ringkasan hari itu; keadaan kosong menjelaskan bahwa tidak ada transaksi di rekening tersebut. | `[★]` tambahan kita |

### 5.3 Pindah Saldo

| Kode | Aturan | Sumber |
| --- | --- | --- |
| S-1 | Susunan form, dari atas: **Tanggal + Jam**, **Rekening asal** (tanpa label, langsung menampilkan nama rekening), **Tujuan** (berlabel), **Jumlah** (dengan ikon kalkulator), **Keterangan** (dengan ikon mikrofon), lalu **Simpan**. | `[x]` |
| S-9 | **Tidak ada field Judul dan tidak ada field Kategori.** Ini yang membedakannya dari form pemasukan dan pengeluaran. | `[x]` |
| S-10 | Judul halamannya tetap **"Tambah Transaksi"**, sama seperti pemasukan dan pengeluaran. | `[x]` |
| S-11 | Pemilih rekening memakai panel bawah yang sama seperti transaksi biasa (T-21). | `[x]` |
| S-2 | Pesan validasi: "Jumlah, rekening asal, dan rekening tujuan harus diisi." | `[x]` |
| S-3 | Disimpan sebagai **satu baris** dengan `idWalletSource` dan `idWalletDestination`. | `[x]` |
| S-4 | Tidak dihitung sebagai pemasukan/pengeluaran di rekap. | `[x]` |
| S-5 | Pindah saldo dapat dicari lewat nama rekening asal maupun tujuan. | `[x]` query pencarian memakai `wallet_source.name` dan `wallet_destination.name` |
| S-6 | Sepran tidak mengenal biaya admin pada pindah saldo. Kita menambahkannya sebagai **field opsional**: bila diisi, biaya dicatat sebagai baris **pengeluaran terpisah** di rekening asal dengan `transfer_group_id` yang sama, sehingga saldo asal berkurang sebesar jumlah transfer + biaya, sedangkan rekening tujuan tetap menerima jumlah transfer. Biaya ikut terhapus/dipulihkan bersama transfer dan tidak boleh melebihi jumlah transfer. | `[★]` tambahan kita |
| S-7 | **Kita simpan sebagai dua baris terhubung.** Perilaku pengguna sama persis, tapi rumus saldo cukup satu penjumlahan, dan rekap otomatis tidak menghitung pindah saldo sebagai pemasukan/pengeluaran. | `[★]` |
| S-8 | Dicapai dari tombol `+` di halaman Transaksi, sebagai **pilihan paling atas** di antara tiga pilihan. Ikon abu-abu berisi dua panah berlawanan arah. | `[x]` |

### 5.4 Koreksi Saldo

| Kode | Aturan | Sumber |
| --- | --- | --- |
| K-1 | Jenis transaksi tersendiri, terpisah dari pemasukan dan pengeluaran. | `[x]` |
| K-2 | Field: Jumlah, Rekening, Keterangan, Tanggal, Jam. | `[x]` |
| K-3 | Menghapus rekening yang punya koreksi saldo juga menghapus koreksinya (`on delete cascade`), berbeda dari pindah saldo yang diblokir (`on delete no action`). | `[x]` |
| K-4 | Ditampilkan di halaman transaksi bersama jenis lain, sehingga pengguna melihat riwayat saldo yang utuh. | `[x]` keduanya muncul di menu harian |
| K-5 | Nilai koreksi boleh positif (menambah) maupun negatif (mengurangi). | `[?]` kesimpulan dari field `amount REAL` dan tidak ada `jenisTransaksi` |
| K-6 | **Tidak dicapai dari tombol `+` di halaman Transaksi.** Menu itu hanya berisi Pindah Saldo, Pemasukan, dan Pengeluaran (T-14). Koreksi dibuat dari halaman Rekening: membuka sebuah rekening menampilkan **Saldo Saat Ini**; angka yang diubah menjadi saldo baru, dan selisihnya dicatat sebagai Koreksi Saldo. Saldo awal tidak ditulis ulang, sehingga riwayat lama tetap utuh. | `[x]` diterapkan dan diuji di perangkat; lihat VERIFIKASI.md |

### 5.5 Judul dan Kategori

Ini bagian paling khas dari Sepran, dan mudah salah tiru.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| C-1 | Judul dan kategori **bukan** pilihan dari daftar tetap. Keduanya **teks bebas**. | `[x]` kolom `judul TEXT` dan `kategori TEXT` |
| C-2 | Nilai yang pernah dipakai disarankan lewat **daftar saran** saat pengguna mengetik. | `[x]` tabel saran + widget `suggestions` |
| C-3 | Saran disimpan di tabel terpisah per jenis, dengan kunci unik `(nama, jenisTransaksi)`. Artinya judul "Gaji" untuk pemasukan berbeda entri dengan "Gaji" untuk pengeluaran. | `[x]` `UNIQUE(nama, jenisTransaksi)` |
| C-4 | Setiap saran mencatat `digunakan` (berapa kali dipakai) dan `terakhirDigunakan` (kapan terakhir dipakai). | `[x]` |
| C-5 | Saran yang sudah lama tidak dipakai dibersihkan otomatis. | `[x]` `delete from judul_data_harian where jenisTransaksi=? and terakhirDigunakan<?` |
| C-6 | Menghapus transaksi mengurangi penghitung `digunakan`, dengan batas bawah nol. | `[x]` `SET digunakan = digunakan - 1 WHERE digunakan > 0` |
| C-7 | Saat mengetik judul, Sepran dapat menyarankan kategorinya. | `[x]` ada method `getCategoryByTitle` |
| C-8 | Placeholder input kategori: "Ketik disini untuk kategori baru". | `[x]` |
| C-9 | **Kita pakai tabel saran yang sama**, tapi pengguna tetap boleh membuat kategori tetap yang bisa dipilih. Ini menghilangkan risiko salah ketik, tanpa menghilangkan kecepatan. | `[★]` |
| C-10 | Batas pembersihan saran (jumlah hari) kita tetapkan **30 hari** dan dibuat dapat diatur. | `[?]` angka asli Sepran belum terbaca |

### 5.6 Hutang Piutang

**Hasil pengamatan layar.** Kepala halaman menampilkan **dua total terpisah**:
"Menerima +5,876,833.00" (hijau) dan "Memberi 2,166,500.00" — bukan satu nilai
selisih. Di bawahnya kotak **Pencarian** dengan ikon mikrofon, lalu **daftar
datar**. Setiap baris berisi nama (tebal), nominal, dan keterangan. Bila
keterangan kosong, tertulis **"Tanpa keterangan"**.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| H-1 | Halaman "Hutang" punya dua total di kepala: **Menerima** (hijau, bertanda `+`) dan **Memberi** (tanpa tanda). Keduanya **tidak disatukan** menjadi satu selisih. | `[x]` |
| H-2 | Tombol `+` **tidak langsung membuka form**. Ia membuka **dua pilihan arah**, berurutan dari atas: **Memberi** (lingkaran merah, panah ganda ke bawah) dan **Menerima** (lingkaran oranye, panah ganda ke atas). Jadi arah dipilih lebih dulu, baru form entri terbuka. | `[x]` |
| H-12 | Isi form entri: **Nama** (baru, atau dipilih dari yang sudah pernah dipakai), Jumlah, Nomor HP, Keterangan, Tanggal. Rekening opsional. | `[?]` urutan dan field pasti di dalam form belum terlihat |
| H-3 | **Arah ditentukan oleh tanda nominal**, bukan kolom tersendiri. Tabel `hutang` tidak punya kolom arah. Nilai positif tampil hijau bertanda `+` (Menerima); nilai negatif tampil biasa (Memberi). | `[x]` `[?]` mekanisme tanda pastinya |
| H-4 | Nominal pada tiap baris adalah **jumlah seluruh entri** catatan itu, bukan angka yang disimpan utuh. Tabel `hutang` tidak punya kolom jumlah. | `[x]` method `getSumByIdHutang` |
| H-5 | Judul catatan ("Bayar Pinjaman", "Reimburse Blok M", "Fajar") berasal dari field **Nama**. Pengguna bebas mengisinya dengan nama orang atau keperluan. | `[x]` |
| H-6 | Setiap catatan punya **halaman detail** berisi daftar entri, ringkasan, dan tombol tambah entri. | `[x]` `loan_detail` |
| H-7 | Menghapus catatan hutang **ikut menghapus seluruh entrinya** (`on delete cascade`), konfirmasi: "Semua data transaksi pada halaman ini akan dihapus, apakah Anda yakin?" | `[x]` |
| H-8 | Ada kotak **Pencarian** di halaman Hutang, dengan ikon mikrofon (pencarian dengan suara). | `[x]` |
| H-9 | Status **ada**, tetapi hanya di halaman detail, sebagai **anak judul** di bilah atas: tertulis **"Belum lunas"**. Di daftar hutang tidak terlihat. | `[x]` |
| H-13 | Bilah atas halaman detail punya **tiga aksi**: **tandai lunas** (ikon orang bercentang), **edit** (pensil), **hapus** (tong sampah). | `[x]` |
| H-14 | Halaman detail punya **tiga sel ringkasan berikon tanpa label**: panah ke atas berwarna hijau, panah ke bawah, dan sebuah ikon bulat merah muda. Pada satu contoh, nilainya 0,00 · 200.000,00 · 200.000,00. Sel pertama dan kedua adalah Menerima dan Memberi; **sel ketiga paling mungkin sisa**, tetapi belum dapat dipastikan karena salah satu sisinya nol. | `[?]` butuh satu catatan hutang yang punya entri di **kedua** arah |
| H-10 | Tidak ada tanggal jatuh tempo. | `[x]` tidak ada kolomnya |
| H-11 | Buku besar tetap **dua arah** dan nominal baris tetap dihitung dari entri bertanda. **Target** (H-17) adalah metadata pokok yang terpisah dan tidak mengubah buku besar; kelebihan bayar diukur terhadap target (H-23), bukan terhadap `net`. | `[★]` koreksi dari versi sebelumnya dokumen ini |
| H-15 | Entri hutang yang diberi rekening **dicerminkan menjadi baris transaksi**, dan baris cermin itu **tidak boleh** disunting atau dihapus dari halaman Detail Transaksi — sumber kebenarannya ada di catatan hutang. Halaman detail menampilkan keterangan dan mematikan kedua tombolnya. | `[★]` keputusan kita; Sepran tidak memperlihatkan tautan ini |
| H-16 | Halaman Hutang punya **dua mode tampilan**: **Normal** dan **Target**, dengan pemilih di bawah bilah judul. Keduanya membaca data yang sama; yang berbeda adalah cara menyajikannya. Mode terakhir tidak perlu diingat lintas peluncuran. | `[★]` keputusan kita |
| H-17 | Catatan boleh punya target: `debts.target_amount` + `debts.target_direction` (`owe` = saya berutang, `owed` = orang berutang ke saya). Target adalah **metadata pokok utang**, bukan saldo dan bukan transaksi. | `[★]` |
| H-18 | Membuat atau mengubah target **tidak boleh** menulis `transactions`, tidak mengubah saldo rekening, dan tidak mengubah mutasi Rekap. | `[★]` |
| H-19 | Tab **Normal** menampilkan **semua** catatan (termasuk yang bertarget) dengan bentuk yang sudah ada: dua total Menerima/Memberi, pencarian, dan daftar datar. Catatan bertarget diberi badge kecil **"Target"**. | `[★]` |
| H-20 | Tab **Target** hanya menampilkan catatan dengan `target_amount > 0`. Header-nya **dua angka terpisah**: **Total sisa utang** (`owe`) dan **Total sisa piutang** (`owed`). Keduanya tidak pernah dijumlahkan (lanjutan H-1). | `[★]` |
| H-21 | Pembayaran adalah `debt_entries` bertanda seperti biasa. Di alur Target, **rekening wajib dipilih** supaya saldo benar-benar berkurang. Bila pengguna mengosongkannya, tombol Simpan menampilkan peringatan "Tanpa rekening, saldo tidak berkurang" dan tidak menyimpan sampai rekening dipilih. | `[★]` |
| H-22 | Progress dihitung di domain, bukan di UI: `paid = paid_opening + jumlah entri arah pembayaran`; `remaining = max(0, target − paid)`; `overpaid = max(0, paid − target)`; `fraction = (paid / target)` dibatasi 0..1. Entri arah berlawanan tidak menambah progress. Entri yang diedit/dihapus otomatis mengubah progress. | `[★]` |
| H-23 | Kelebihan bayar **diizinkan**. Tampilkan **"Lunas, lebih Rp X"**. Jangan memblokir pembayaran nyata. | `[★]` |
| H-24 | Status Lunas otomatis muncul saat `remaining = 0`. Flag `is_settled` yang sudah ada tetap bisa dipakai untuk **utang yang dihapuskan** tanpa pembayaran; detail menampilkan "Sisa dihapuskan Rp X". Menandai Lunas **tidak** membuat entri atau transaksi. | `[★]` |
| H-25 | Target boleh diedit. Bila target baru < `paid`, tampilkan peringatan sebelum menyimpan; setelah disimpan, tampilkan "Lunas, lebih Rp X". Utang tambahan diselesaikan dengan **menaikkan target** (bukan entri pokok otomatis), supaya rumusnya tetap satu. | `[★]` |
| H-26 | Konfirmasi hapus catatan harus menyebut bahwa **seluruh cicilan dan transaksi cerminnya ikut terhapus** dan **saldo rekening akan kembali**. Ini memperjelas perilaku H-7 yang sudah ada. | `[★]` |
| H-27 | Saat membuat target, sediakan field opsional **"Sudah dibayar"**. Nilainya masuk ke `paid_opening`, **bukan** ke `debt_entries`, sehingga tidak mengubah saldo maupun Rekap. | `[★]` |
| H-28 | Progress bersifat **sepanjang waktu**, bukan per bulan. Filter periode milik Rekap tidak berlaku di tab Target. | `[★]` |
| H-29 | Pencarian (H-8) tetap berlaku di kedua mode. Urutan tab Target: sisa terbesar lebih dulu, lalu tanggal terbaru. Catatan Lunas tetap tampil dengan badge, di bawah catatan aktif. | `[★]` |

**Tambahan kita.** Mode **Normal | Target** (H-16 sampai H-29) adalah fitur
pembeda, bukan tiruan Sepran. Bentuk dan alasan lengkapnya ada di
`USULAN-HUTANG-TARGET.md`; ringkasnya: tab Normal tetap seperti di atas,
sedangkan tab Target menyajikan catatan bertarget sebagai progress pokok yang
terpisah dari saldo dan Rekap.

### 5.7 Anggaran

**Jawaban: fitur Anggaran tidak ada di antarmuka aplikasi.**

Menu bawah hanya berisi lima tab: **Transaksi, Rekening, Rekap, Hutang, Setting**.
Menu Setting berisi delapan butir (lihat §5.12), dan tidak ada Anggaran di
antaranya. Jadi dugaan pada versi sebelumnya dokumen ini salah.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| A-1 | Teks antarmuka Anggaran **memang ada** di berkas bahasa aplikasi. | `[x]` `id-ID.json` |
| A-2 | Tetapi **tidak ada menu, tab, maupun tombol Anggaran** di versi 5.2.2. | `[x]` |
| A-3 | **Tidak ada tabel `budget` di SQLite.** | `[x]` |
| A-4 | Kesimpulan: fitur ini **belum dirilis** — teksnya sudah disiapkan di kode, tapi belum dipasang ke antarmuka. | `[x]` |
| A-5 | Karena itu anggaran **bukan bagian dari paritas**. Kita pindahkan ke §11 sebagai fitur pembeda. | `[★]` |
| A-6 | Bila dibangun: disimpan di SQLite bersama data lain, bukan di penyimpanan terpisah. | `[★]` |

### 5.8 Rekap dan Laporan

**Tiga jenis rekap:** Realtime · Bulanan · Custom. `[x]`

| Kode | Aturan | Sumber |
| --- | --- | --- |
| L-1 | Kartu ringkasan bulanan berisi **lima baris berurutan**: Pengeluaran, Pemasukan (bertanda `+`, hijau), Selisih, **Hutang Piutang**, **Koreksi Saldo**. | `[x]` |
| L-1b | **Hutang Piutang dan Koreksi Saldo ikut tampil di rekap** sebagai baris tersendiri. Ini koreksi dari versi sebelumnya dokumen ini, yang tidak menyebutkannya sama sekali. | `[x]` |
| L-1c | Saldo Awal, Saldo Akhir, dan Sisa Saldo tidak muncul pada kartu bulanan. Kemungkinan ada di tab **Realtime**. | `[?]` perlu tangkapan layar tab Realtime |
| L-2 | Rincian disajikan dalam tiga cara: **Grafik**, **per Kategori**, **per Judul**. | `[x]` |
| L-3 | Empat daftar rincian: Pengeluaran per Kategori, Pengeluaran per Judul, Pemasukan per Kategori, Pemasukan per Judul. | `[x]` |
| L-4 | Ada baris **"Pengeluaran Lainnya"** untuk pengelompokan sisa. | `[x]` |
| L-5 | Ada **rata-rata per hari**. | `[x]` |
| L-6 | Ada halaman **Tren Aset**. | `[x]` |
| L-7 | Halaman **"Konfigurasi Rekap"** berisi **tepat dua setelan**: **Tanggal Mulai** (pilihan hari dalam bulan, nilai bawaan **1**) dan **Saldo Akumulasi** (sakelar, bawaan **mati**), lalu sebuah tombol **Simpan**. Tidak ada setelan lain. | `[x]` |
| L-7b | **Tanggal Mulai** adalah hari dimulainya periode rekap. Nilai 1 berarti periode mengikuti awal bulan; nilai 25 berarti periode berjalan dari tanggal 25 sampai tanggal 24 bulan berikutnya, yang berguna untuk siklus gaji. | `[★]` tafsiran kita, perlu satu tangkapan layar bernilai selain 1 untuk memastikan |
| L-8 | Rekap kustom dapat **disimpan** dengan nama dan rentang tanggal, lalu diedit dan dihapus. Validasi: tanggal akhir tidak boleh lebih kecil dari tanggal awal. | `[x]` |
| L-9 | Bila menyertakan Saldo Akumulasi, rekap menghitung Saldo Awal dari seluruh pergerakan sebelum rentang. | `[x]` nama fungsi `getFirstAndLastDate`, `getBalance` |
| L-10 | Rekap tidak boleh menghitung Pindah Saldo sebagai pemasukan/pengeluaran. | `[x]` |
| L-11 | Grafik memakai pie/bar/line. | `[?]` jenis tepatnya belum dibaca |
| L-12 | Bila kita memakai pustaka grafik pihak ketiga, **periksa lisensinya lebih dulu**. Sepran memakai Syncfusion yang berlisensi komersial. | `[★]` |
| L-13 | Tab **Bulanan** menampilkan **daftar kartu per bulan** (Okt, Sep, Agu, Jul, …) dalam satu gulir ke bawah — bukan satu bulan dengan tombol pindah bulan. | `[x]` |
| L-14 | Ikon **gerigi** di kanan atas halaman Rekap membuka halaman **"Konfigurasi Rekap"**. | `[x]` |

### 5.9 Riwayat dan Pencarian

| Kode | Aturan | Sumber |
| --- | --- | --- |
| F-1 | Ada halaman **Riwayat** dengan input kata kunci. | `[x]` ikon dokumen di bilah judul Transaksi |
| F-2 | Pencarian mencakup **keterangan**, **nama rekening asal**, dan **nama rekening tujuan**. | `[x]` |
| F-3 | Tidak ditemukan pencarian berdasarkan judul, kategori, atau rentang nominal. | `[x]` tidak ada di Sepran |
| F-4 | **Kita tambahkan** pencarian pada **judul** dan **kategori**. | `[x]` murah untuk ditambahkan dan sangat terasa manfaatnya |

### 5.10 Ekspor

| Kode | Aturan | Sumber |
| --- | --- | --- |
| X-1 | Dua format: **Excel** dan **PDF**. | `[x]` |
| X-2 | Pengguna memilih rentang **Dari** sampai **Sampai**. | `[x]` |
| X-3 | Kolom ekspor: **TANGGAL, JUDUL, KATEGORI, PEMASUKAN, PENGELUARAN, KETERANGAN**. | `[x]` persis dari berkas bahasa Sepran |
| X-4 | Di Sepran, ekspor adalah fitur berbayar. Ada alur pembayaran di dalam dialog ekspor, dan pesan "Pembayaran berhasil! Tekan tombol Export lagi untuk mengexport data Anda". | `[x]` |
| X-5 | **Kita jadikan ekspor gratis dan tanpa batas**: Excel maupun PDF, tanpa alur bayar. Data pengguna tidak boleh disandera. | `[★]` |
| X-6 | Tidak ada fitur impor. | `[x]` |
| X-7 | **Kita tambahkan Impor dari Sepran**: satu arah, lewat berkas Excel ekspor, dibuka dari Pengaturan → "Impor dari Sepran". Hasilnya **salinan**, bukan tautan — mengubah data di sini tidak mengubah Sepran, dan sebaliknya. | `[★]` jalan keluar dari Sepran tanpa mengetik ulang |

Aturan impor (X-7 dan X-12):

| Kode | Aturan | Sumber |
| --- | --- | --- |
| X-8 | Berkas `.xlsx` dipilih lewat pemilih berkas Android. Kolom dikenali lewat **nama**, bukan urutan: TANGGAL, JUDUL, KATEGORI, PEMASUKAN, PENGELUARAN, KETERANGAN, dan REKENING bila ada. | `[★]` tahan terhadap kolom yang bergeser |
| X-9 | Tanggal terbaca sebagai `dd/MM/yyyy`, `yyyy-MM-dd`, teks berbulan (`20 Okt 2026`), atau seri Excel. Nominal terbaca dengan pemisah ribuan titik dan desimal koma. Baris tanpa tanggal atau bernominal nol dilewati dan dihitung. | `[★]` |
| X-10 | Setiap nama rekening di berkas dipetakan ke rekening di aplikasi ini; baris tanpa rekening memakai satu rekening tujuan pilihan. | `[★]` |
| X-11 | Impor **tidak** menaikkan penghitung saran judul/kategori — seratus baris lama bukan bukti judul itu sering dipakai sekarang. Pemakaian rekening tetap naik sekali per rekening. | `[★]` |
| X-12 | **Impor JSON dari HP**: selain `.xlsx`, Pengaturan → Impor dari Sepran menerima `.json` dengan `wallet_balances` (nama dan saldo akhir) dan `transactions` (`date`, `time` opsional, `type` `expense`/`income`/`transfer`, `amount`, `title`, `category`, `wallet`, `counter_wallet` untuk transfer). | `[★]` saldo akhir ikut terbawa, tidak perlu koreksi manual |
| X-13 | Saldo pada `wallet_balances` boleh berupa teks desimal dan dibulatkan ke rupiah utuh. **Saldo awal** tiap rekening = saldo target dikurangi jumlah mutasi bertanda rekening itu; pindah saldo mengurangi asal dan menambah tujuan. Dengan begitu saldo akhir sesudah impor sama dengan target. | `[★]` |
| X-14 | Setiap rekening di berkas dipetakan ke rekening lama **atau** dibuat baru (bawaan: buat baru dengan saldo awal hasil hitung; bila nama itu sudah ada, rekening lama yang dipilih supaya tidak bentrok). Saldo awal rekening lama tidak diubah. Nama rekening dibandingkan tanpa memandang besar-kecil huruf. | `[★]` |
| X-15 | Pratinjau JSON menampilkan jumlah transaksi, rentang tanggal, pemasukan, pengeluaran, jumlah transfer, serta per rekening: saldo target, saldo awal hitung, dan jumlah transaksi. Baris tidak valid dilewati dan dihitung; transfer tanpa rekening tujuan yang berbeda ditolak. Seluruh impor berada dalam **satu transaksi basis data**; kedua baris transfer masuk dengan `transfer_group_id` unik. | `[★]` aman untuk berkas besar |

### 5.11 Backup dan Restore

| Kode | Aturan | Sumber |
| --- | --- | --- |
| B-1 | Backup memerlukan login: **Masuk dengan Google** atau **Masuk dengan Apple**. | `[x]` |
| B-2 | Ada **backup otomatis** dengan pilihan: Tidak aktif, Setiap hari, Seminggu sekali. | `[x]` |
| B-3 | Ada **pulihkan dari** daftar backup yang tersedia. Pesannya: "Tidak ada data backup ditemukan." | `[x]` |
| B-4 | Restore memakai konfirmasi tegas: "Klik Ok untuk memulihkan data. Aksi ini tidak dapat diurungkan". | `[x]` |
| B-5 | Ada **Hapus Akun**, yang menghapus data akun dan backup secara permanen. | `[x]` |
| B-6 | Ada pengingat berkala untuk segera backup. | `[x]` |
| B-7 | Ada **Hapus Semua Data** yang mengosongkan basis data lokal. | `[x]` |
| B-8 | Backup memakai penyimpanan awan (Firebase Storage) dan autentikasi (Firebase Auth). | `[x]` |
| B-9 | **Versi pertama kita: backup lokal ke berkas**, tanpa akun dan tanpa awan. Opsi awan ditambahkan kemudian. Alasannya: prinsip P4, dan bagian tersulit dari sebuah aplikasi pencatatan adalah membuatnya selesai, bukan menambahkan login. | `[★]` |
| B-10 | Berkas backup diberi versi skema, dan pemulihan dari versi lebih baru ditolak dengan pesan jelas. | `[★]` |

### 5.12 Pengaturan

**Isi menu Setting, persis seperti terlihat di layar. Hanya delapan butir:**

1. Pulihkan Pembayaran Sebelumnya
2. Hapus Iklan
3. Tampilkan Angka Desimal — sakelar, dengan contoh format `10.000,00`
4. Backup dan Restore Data
5. Hapus Semua Data
6. Pengingat
7. Warna Tema
8. Bahasa/Language

| Kode | Aturan | Sumber |
| --- | --- | --- |
| ST-1 | Menu Setting berisi **tepat delapan butir** di atas, tidak lebih. | `[x]` |
| ST-2 | **Tidak ada menu PIN Login**, meski teksnya ada di berkas bahasa. Sama seperti Anggaran, fitur ini belum dirilis ke antarmuka. | `[x]` |
| ST-3 | **Tampilkan Angka Desimal** berupa sakelar dan **aktif secara bawaan**. Format angka: ribuan dipisah **titik**, desimal dipisah **koma**, dua angka di belakang koma. | `[x]` |
| ST-4 | **Warna Tema**: Biru Terang, Mode Pink, Mode Ungu, Mode Gelap. Dipilih juga saat pertama membuka aplikasi. | `[x]` |
| ST-5 | **Bahasa**: Indonesia, Inggris, Thailand. | `[x]` |
| ST-6 | **Pengingat**: aktifkan + pilih jam ("Kapan"). | `[x]` |
| ST-7 | Tidak ada "Beri penilaian" maupun "Ikuti kami" di daftar Setting. | `[x]` |
| ST-8 | Tidak ada pengaturan awal minggu, format tanggal, atau mata uang utama. | `[x]` |
| ST-9 | **Kita tetap sediakan PIN** meski Sepran tidak punya. Mengunci aplikasi keuangan adalah kebutuhan nyata, dan ongkosnya murah. | `[★]` |
| ST-10 | Menu Pengaturan dibuka lewat **ikon roda gigi di kiri atas header**, bukan tab bawah. Tab bawah: Transaksi, Rekening, Rekap, Hutang, **Scan AI**. | `[★]` |
| ST-11 | Selain delapan butir Sepran, halaman Pengaturan memuat tambahan kita: **Sinkronisasi & Akun** (§5.16), **Notifikasi Otomatis** (§5.14), dan impor dari Sepran. Tambahan diletakkan terpisah agar paritas tetap mudah diperiksa. | `[★]` |

### 5.13 Onboarding, Iklan, dan Versi Pro

| Kode | Aturan | Sumber |
| --- | --- | --- |
| O-1 | Saat pertama membuka, pengguna diminta memilih warna tema. Judulnya "Pilih warna tema kesukaanmu". | `[x]` |
| O-2 | Setelah itu, diminta mengizinkan notifikasi, dengan penjelasan: "Izinkan notifikasi untuk mendapatkan pengingat harian". Ada tombol **Izinkan** dan **Tidak**. | `[x]` |
| O-3 | Ada tur pengenalan antarmuka. | `[x]` |
| O-4 | Iklan: app-open ad (saat membuka aplikasi), banner, dan collapsible banner. | `[x]` |
| O-5 | Versi Pro menghapus iklan dan membuka ekspor Excel/PDF serta backup. Teksnya: "Beralih ke SepranPro!". | `[x]` |
| O-6 | Ada program referral: bagikan tautan, 5 orang menginstal, dapat Pro gratis. | `[x]` |
| O-7 | Ada pemulihan pembelian sebelumnya. | `[x]` |
| O-8 | Ada paksa pembaruan versi lewat konfigurasi jarak jauh, dengan judul "Waktunya Update". | `[x]` |
| O-9 | **Kita lewati iklan dan referral di versi pertama.** Keduanya menambah kerumitan besar (SDK iklan, kepatuhan, penagihan) dan tidak berhubungan dengan inti pencatatan keuangan. | `[★]` |

### 5.14 Auto-Capture Transaksi dari Notifikasi (Android)

Fitur ini **tidak ada di Sepran**. Tujuannya mengurangi pekerjaan mengetik:
notifikasi pembayaran dari bank atau dompet digital diubah menjadi **draft**
yang tetap harus dikonfirmasi pengguna. Tidak ada transaksi yang ditulis
otomatis.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| N-1 | Hanya Android. Pengguna menyalakan **Akses Notifikasi** sendiri di Setting Android; tanpa izin itu fitur tidak aktif. | `[★]` |
| N-2 | Aplikasi yang didukung: BCA, Livin Mandiri, BRImo, GoPay, OVO, DANA, ShopeePay, dan blu (BCA Digital). Nama paket yang dikenali ada di `NotificationSource`; paket lama blu tetap diterima. | `[★]` |
| N-3 | Notifikasi dari paket lain, notifikasi ringkasan grup, dan notifikasi tanpa judul/isi dibuang sebelum disimpan. | `[★]` |
| N-4 | Filter teks membuang OTP, kode verifikasi, login, promo, cashback, diskon, peringatan keamanan, PIN/password, dan kadaluwarsa. Frasa "dana masuk" atau "uang masuk" tetap diterima sebagai pemasukan. | `[★]` |
| N-5 | Nominal dibaca dari `Rp` atau `IDR`, disimpan sebagai **bilangan bulat rupiah**. Bila ada beberapa nominal, nominal transaksi dipilih; nominal setelah kata saldo/sisa/limit dilewati. Pengecualian: "saldo masuk", "top up saldo", "isi saldo", dan "tambah saldo" adalah nominal transaksi, bukan saldo akhir. Notifikasi tanpa nominal atau bernominal nol ditolak. | `[★]` |
| N-6 | Arah uang ditentukan dari kata kerja/frasa: transfer/pembayaran/QRIS/debit menjadi pengeluaran; transfer masuk/dana masuk/kredit/refund/top up saldo/telah diterima menjadi pemasukan. Bila arah tidak dapat dipastikan, notifikasi dibuang. Aturan ini konservatif: lebih baik tidak ada draft daripada nominal atau arah yang salah. | `[★]` |
| N-7 | Hasil parsing menjadi **draft pending**. Draft menampung aplikasi, judul/isi asli, nominal positif, arah, tanggal lokal `YYYY-MM-DD`, jam opsional, dan rekening hasil pemetaan (bila ada). | `[★]` |
| N-8 | Inbox Notifikasi menampilkan draft pending terbaru lebih dulu, dengan badge jumlah pada ikon lonceng. Draft dapat digeser ke kiri untuk diabaikan. | `[★]` |
| N-9 | Konfirmasi mewajibkan **judul**, **kategori**, dan **rekening**. Tanggal, jam, nominal, dan arah mengikuti notifikasi dan tidak diubah di layar ini. | `[★]` |
| N-10 | Setelah disetujui, satu baris `transactions` dibuat lewat `TransactionRepository.createSimple`, dengan keterangan `Dari notifikasi <aplikasi>`. Draft menjadi `approved` dan menyimpan ID transaksi. | `[★]` |
| N-11 | Mengabaikan draft mengisi status `ignored` dan `deleted_at`; baris tidak dihapus permanen. Draft `approved` tetap tersimpan sebagai jejak. | `[★]` |
| N-12 | Pemetaan paket aplikasi ke rekening disimpan di `account_notification_mappings`. Satu paket hanya punya satu pemetaan aktif; mengganti rekening memakai baris yang sama, melepas pemetaan mengisi `deleted_at`. | `[★]` |
| N-13 | Pemetaan yang dibuat setelah draft masuk ikut mengisi draft pending yang belum punya rekening. Beberapa nama paket untuk satu aplikasi (mis. GoPay) dipetakan bersama. | `[★]` |
| N-14 | Setiap notifikasi punya `source_key` unik (`paket|waktu|judul|isi`). Notifikasi yang diposting ulang tidak menjadi draft ganda, termasuk bila mesin utama dan mesin latar memproses bersamaan. | `[★]` |
| N-15 | Antrean mentah disimpan sementara di penyimpanan privat aplikasi, maksimal 200 event. Event baru dihapus setelah Dart menyatakan berhasil diolah; bila mesin latar gagal, aplikasi utama menyedot antrean saat dibuka/dilanjutkan. | `[★]` |
| N-16 | Teks notifikasi tidak pernah dikirim ke server dan tidak ditulis ke log. Parsing berjalan luring di perangkat. | `[★]` |
| N-17 | Fitur hanya membaca notifikasi **baru** yang masuk setelah akses diberikan; notifikasi lama tidak diambil dari riwayat sistem. | `[★]` |
| N-18 | Basis data memakai WAL dan `busy_timeout` agar aplikasi utama dan mesin latar dapat menulis ke SQLite yang sama tanpa saling mengunci. | `[★]` |
| N-19 | Layanan pendengar berjalan **tanpa** halaman aplikasi terbuka. Notifikasi yang masuk diproses di isolate latar (`notificationCaptureMain`), sehingga tidak bergantung pada siklus hidup UI. | `[★]` |
| N-20 | Setelah ponsel menyala ulang, `SpendlyBootReceiver` menyambungkan kembali layanan dan membangunkan mesin latar. Tanpa ini, merek Android yang agresif mematikan layanan akan memutus auto-capture tanpa gejala. | `[★]` |
| N-21 | Halaman Pengaturan › Notifikasi Otomatis menampilkan panduan baterai dan **auto-start** per merek (Xiaomi, Oppo, Vivo, Samsung, dan seterusnya), dengan tombol yang membuka setelan sistem terkait. | `[★]` |
| N-22 | Daftar draft dapat ditarik ke bawah (**pull to refresh**) atau disegarkan lewat ikon di AppBar. Menyegarkan berarti membaca ulang basis data **dan** menyedot antrean mentah dari sisi Android, sehingga draft yang dibuat saat aplikasi tertutup langsung muncul. | `[★]` |

Batasan yang diketahui: variasi teks notifikasi tiap bank/aplikasi dapat berubah
tanpa pemberitahuan. Karena itu layar konfirmasi selalu ditampilkan dan nominal
tidak pernah langsung masuk ke saldo. BCA, Mandiri, dan BRImo belum tersedia di
perangkat uji, sehingga contoh teksnya baru diuji lewat unit test parser.

### 5.15 Scan AI — Membaca Transaksi dari Tangkapan Layar

Fitur ini **tidak ada di Sepran**. Tujuannya memindahkan riwayat mutasi dari
tangkapan layar e-wallet atau m-banking menjadi transaksi, tanpa mengetik satu
per satu. Semua pembacaan berjalan di perangkat dan hasilnya selalu berupa
**pratinjau yang harus dikonfirmasi**.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| SC-1 | Hanya Android dan iOS. Di web, tab Scan AI tetap ada tetapi menjelaskan bahwa mesin OCR lokal tidak tersedia di peramban. | `[★]` |
| SC-2 | Sumber gambar: galeri (boleh banyak sekaligus, termasuk satu tangkapan layar panjang) atau kamera untuk satu foto. | `[★]` |
| SC-3 | OCR memakai Google ML Kit **di perangkat**. Gambar dan teks tidak pernah diunggah ke server mana pun. | `[★]` |
| SC-4 | Teks hasil OCR dipecah baris demi baris. Parser mengenali tanggal (`18/10/2026`, `18 Okt 2026`, `2026-10-18`), jam `HH:mm`, nominal `Rp`/`IDR` dengan pemisah ribuan titik atau koma, serta arah uang dari kata kunci (masuk/kredit/terima melawan keluar/debit/bayar). | `[★]` |
| SC-5 | Bila tanggal tidak ditemukan, dipakai tanggal hari ini dan baris ditandai "tanggal tidak terbaca" agar pengguna memeriksanya. | `[★]` |
| SC-6 | Kategori ditebak dari judul dengan daftar kata kunci (`CategoryGuesser`). Tebakan selalu dapat diubah, dan field kategori menerima **teks bebas** seperti form transaksi — pengguna tidak dipaksa memilih dari daftar. Chip saran tetap tersedia dan ikut menyempit saat diketik. | `[★]` |
| SC-7 | Pratinjau menampilkan setiap baris dengan centang, judul, nominal, tanggal, arah (Keluar/Masuk), kategori, dan dompet. Arah dapat diubah **per baris** atau sekaligus lewat pemilih **"Arah untuk semua"**. Tidak ada baris yang tersimpan otomatis. | `[★]` |
| SC-8 | Dompet wajib dipilih, baik per baris maupun lewat "Dompet untuk semua". Menyimpan tanpa dompet ditolak dengan pesan yang terlihat. | `[★]` |
| SC-9 | Baris yang dicentang ditulis sekaligus dalam **satu transaksi basis data** lewat `TransactionRepository.createMany`, dengan keterangan `Dari Scan AI`. Bila satu baris tidak sah, tidak ada yang tersimpan. | `[★]` |
| SC-10 | Gambar tidak disalin ke penyimpanan aplikasi; hanya teks hasil OCR yang dipakai selama layar terbuka. | `[★]` |
| SC-11 | Bila teks terbaca tetapi tidak ada transaksi yang dikenali, pengguna diberi pilihan melihat teks aslinya untuk mendiagnosis gambar. | `[★]` |
| SC-12 | Mesin OCR dimuat **malas**, saat tab Scan AI dipakai pertama kali. Cold start tidak menunggu model. | `[★]` |
| SC-13 | Sumber mutasi (mis. DANA, OVO, GoPay, ShopeePay, BCA, Mandiri, BRImo, Blu) dideteksi dari teks OCR. Karena tangkapan layar Activity DANA tidak selalu memuat kata "DANA", frasa khas `Search send money` juga dipakai sebagai penandanya. Bila pengguna punya rekening dengan nama yang cocok, rekening itu dipilih otomatis untuk semua baris; pengguna tetap bisa menggantinya. Deteksi sumber **tidak** membuat baris dianggap baru. | `[★]` |
| SC-14 | Saat pratinjau dibuka, aplikasi membaca transaksi yang sudah tercatat pada rentang tanggal hasil scan. Baris dengan tanggal, arah, dan nominal yang sama dianggap **kemungkinan duplikat**, lalu dilepas centangnya. Pencocokan dibatasi ke dompet yang dipilih atau terdeteksi bila diketahui, supaya nominal sama di dompet lain tidak salah dianggap duplikat; pindah saldo ikut dihitung, koreksi saldo tidak. Judul tidak dipakai sebagai syarat karena judul hasil OCR sering berbeda dari judul yang diketik pengguna. Setiap transaksi lama hanya dipasangkan dengan satu baris scan. Pengguna tetap boleh mencentang ulang bila yakin. | `[★]` |
| SC-15 | Tepat sebelum menyimpan, riwayat dibaca ulang dari basis data. Bila baris yang dipilih masih cocok dengan transaksi lama, muncul konfirmasi "Mungkin sudah tercatat"; membatalkan konfirmasi melepas centang baris tersebut. | `[★]` |
| SC-16 | Tombol **Lihat foto sumber** membuka foto yang dipakai untuk scan. Beberapa gambar bisa digeser dan masing-masing bisa diperbesar. Gambar tetap tidak disalin ke penyimpanan aplikasi. | `[★]` |

### 5.16 Sinkronisasi Opsional (Supabase + Google)

Fitur ini **tidak ada di Sepran**. Sifatnya tambahan: aplikasi tetap 100% lokal
dan tidak meminta akun. Login Google hanya menambahkan salinan cloud agar data
yang sama bisa dibuka di perangkat lain dan di versi web.

| Kode | Aturan | Sumber |
| --- | --- | --- |
| SY-1 | Tanpa login, seluruh fitur berjalan seperti biasa. Tidak ada permintaan jaringan, tidak ada plugin autentikasi yang dimuat, dan tidak ada data yang dikirim. | `[★]` |
| SY-2 | Kredensial Supabase diberikan saat membangun aplikasi (`--dart-define=SUPABASE_URL`, `--dart-define=SUPABASE_ANON_KEY`). Tidak ada kunci di dalam kode. Build tanpa kredensial menampilkan "belum aktif di build ini". | `[★]` |
| SY-3 | Login memakai OAuth Google lewat Supabase dengan alur PKCE. Di Android/iOS halaman login dibuka di peramban dan kembali lewat skema `io.supabase.spendly://login-callback`; di web kembali ke asal halaman. | `[★]` |
| SY-4 | Sinkronisasi dua arah, dipicu manual dari halaman Sinkronisasi. Tidak ada sinkronisasi latar diam-diam. | `[★]` |
| SY-5 | Tabel yang disinkronkan: `wallets`, `debts`, `budgets`, `custom_reports`, `transactions`, `debt_entries`. `app_settings` tidak ikut (pilihan perangkat), begitu pula draft notifikasi (hanya milik ponsel yang menerimanya). | `[★]` |
| SY-6 | Tarik dan kirim bersifat inkremental memakai penanda `updated_at` per tabel yang disimpan di `app_settings`, dengan tumpang tindih 120 detik untuk jam perangkat yang sedikit mundur. | `[★]` |
| SY-7 | Konflik diselesaikan **last write wins** menurut `updated_at`: versi cloud hanya menimpa baris lokal bila lebih baru. Penghapusan tetap hapus lunak, sehingga `deleted_at` ikut tersinkron. | `[★]` |
| SY-8 | Bila perangkat ini terakhir disinkronkan dengan akun Google lain, data **tidak** digabung diam-diam. Pengguna diminta memilih "Pakai akun ini" (data lokal diunggah ke akun baru) atau keluar. | `[★]` |
| SY-9 | Sisi cloud membatasi akses dengan Row Level Security: setiap baris milik `auth.uid()` pembuatnya. Kunci anon yang tertanam di aplikasi tidak membuka data pengguna lain. | `[★]` |
| SY-10 | Sinkronisasi tidak menyentuh berkas SQLite lokal secara langsung selain lewat SQL `INSERT ... ON CONFLICT(id) DO UPDATE`. Stream lokal ikut diperbarui setelah penulisan. | `[★]` |
| SY-11 | Versi web memakai SQLite yang sama lewat WebAssembly (OPFS/IndexedDB). Basis data itu **lokal untuk peramban tersebut**; perpindahan antarperangkat tetap lewat sinkronisasi. | `[★]` |
| SY-12 | Pemeriksaan waktu memakai jam perangkat. Halaman Sinkronisasi mengingatkan agar jam ponsel benar. | `[★]` |

Rincian pemasangan Supabase, URL balik OAuth, dan batasan versi web ada di
[`docs/SINKRONISASI.md`](SINKRONISASI.md).

---


## 6. Invarian (wajib, harus punya test otomatis)

| Kode | Invarian |
| --- | --- |
| INV-1 | Untuk setiap rekening: `saldo == rumus §4` dengan seluruh baris non-terhapus. |
| INV-2 | Total Saldo pada halaman rekening sama dengan jumlah saldo seluruh rekening non-arsip. |
| INV-3 | Setiap Pindah Saldo punya rekening asal dan tujuan yang berbeda, dan keduanya ada. |
| INV-4 | Nilai dampak pada kedua sisi Pindah Saldo selalu sama besar dan berlawanan tanda. |
| INV-5 | Menghapus lalu memulihkan pergerakan apa pun mengembalikan seluruh saldo ke nilai semula, persis. |
| INV-6 | Pindah Saldo dan Koreksi Saldo tidak pernah masuk hitungan Pemasukan maupun Pengeluaran di rekap mana pun. |
| INV-7 | Jumlah Pemasukan pada satu rentang rekap sama dengan jumlah seluruh baris pemasukan non-terhapus pada rentang itu. Tidak ada baris yang hilang. |
| INV-8 | Tidak ada nilai uang yang disimpan sebagai floating point. Lihat G-11. |
| INV-9 | Jumlah pada Pemasukan dan Pengeluaran selalu > 0. Tanda ditentukan oleh jenis. |
| INV-10 | Jumlah entri bertanda pada satu catatan hutang, dijumlahkan ulang, selalu sama dengan nominal yang ditampilkan pada daftar. Lihat H-4 dan H-11. |

Pengujian yang disarankan untuk INV-1, INV-4, INV-5: **property-based test** —
bangkitan urutan operasi acak (tambah, sunting, hapus, pindah saldo, koreksi,
pulihkan), lalu bandingkan saldo hasil rumus ulang dengan saldo berjalan.

---

## 7. Alur utama

| Alur | Langkah |
| --- | --- |
| **Catat pengeluaran** | Buka → menu Transaksi → tombol Tambah → Pengeluaran → jumlah → judul → kategori → rekening → Simpan |
| **Catat dengan suara** | Form transaksi → tekan tombol mikrofon → ucapkan judul |
| **Pindah uang ke bank** | Tambah → Pindah Saldo → jumlah → Dari → Tujuan → Simpan |
| **Betulkan saldo yang tidak cocok** | Tambah → Koreksi Saldo → rekening → jumlah selisih → Simpan |
| **Uang ke mana bulan ini** | Menu Rekap → Bulanan → lihat ringkasan dan rincian per kategori |
| **Cari transaksi lama** | Menu Riwayat → ketik kata kunci |
| **Catat pinjaman teman** | Menu Hutang → Memberi → nama, jumlah, HP → simpan → saat dibayar, buka detail → tambah cicilan |
| **Catat dari notifikasi** | Nyalakan Akses Notifikasi → bayar dari aplikasi bank/dompet yang didukung → buka Inbox Notifikasi → pilih draft → isi judul, kategori, rekening → Simpan |

---

## 8. Kasus tepi

| Kasus | Perilaku yang diharapkan |
| --- | --- |
| Menghapus rekening yang dipakai Pindah Saldo | Ditolak, arahkan pengguna ke daftar transaksi. |
| Menghapus rekening yang dipakai Koreksi Saldo | Sepran mengizinkan (cascade) dan ikut menghapus koreksinya. **Kita tolak juga**, demi konsistensi dengan INV-5. `[★]` |
| Menghapus rekening default | Ditolak tanpa syarat. |
| Nama rekening sama | Ditolak: "Nama Rekening sudah digunakan". |
| Pindah Saldo dengan asal = tujuan | Ditolak. |
| Entri hutang dengan arah berlawanan | Diperbolehkan. Keduanya dijumlahkan bertanda, dan tanda hasilnya menentukan arah catatan. Lihat H-3 dan H-11. |
| Menyunting judul transaksi lama | Tabel saran tidak berubah; saran hanya bertambah saat transaksi baru disimpan. |
| Backup dari versi aplikasi lebih baru | Ditolak dengan pesan jelas. |
| Menampilkan angka desimal, lalu dimatikan | Pembulatan hanya pada tampilan; nilai tersimpan tidak berubah. |
| Nominal sangat besar | Batasi input maksimum agar tidak melampaui batas bilangan bulat. |
| Tema diubah setelah onboarding | Berlaku seketika di seluruh aplikasi. |

---

## 9. Non-fungsional

| Aspek | Target |
| --- | --- |
| Waktu buka | < 1 detik sampai halaman transaksi tampil. Tab lain dibangun **malas** saat pertama dibuka, dan mesin OCR, autentikasi, serta Supabase tidak dimuat saat cold start. |
| Daftar transaksi | Lancar pada 10.000+ baris, dengan paginasi. Pencarian riwayat berjalan di SQL, bukan dengan memuat seluruh riwayat ke memori. |
| Jaringan | Tidak ada permintaan jaringan wajib. Satu-satunya jalur jaringan adalah sinkronisasi opsional (§5.16), dan hanya berjalan setelah pengguna menekan tombol. |
| Izin perangkat | Notifikasi, akses notifikasi (Notification Listener) untuk auto-capture, kamera/galeri untuk Scan AI, dan mikrofon (untuk input suara). Tidak ada izin penyimpanan untuk versi pertama. |
| Platform | Android, iOS, dan web. Di web, OCR tidak tersedia dan basis data SQLite berjalan lewat WebAssembly di peramban tersebut. |
| Aksesibilitas | Pembesaran font sistem sampai 200% tanpa tata letak rusak. |
| Migrasi data | Setiap perubahan skema punya skrip migrasi; tidak ada kehilangan data. |

---

## 10. Yang sengaja TIDAK dibangun

Sepran tidak punya ini. Jangan bangun bila tujuanmu paritas.

- Transaksi berulang / terjadwal
- Tujuan tabungan
- Tag
- Lampiran foto atau struk
- Subkategori (kategori Sepran datar)
- Kalender transaksi
- Multi mata uang di antarmuka
- Tanggal jatuh tempo pada hutang
- Impor dari CSV atau berkas lain selain Excel dan JSON Sepran

Tambahan yang juga kita tunda meski Sepran punya: iklan dan referral. Akun awan
kini **opsional** (§5.16): aplikasi tetap berjalan penuh tanpanya, dan data
lokal tidak pernah diunggah tanpa tindakan pengguna.

---

## 11. Fitur pembeda (slot kita)

Diisi setelah paritas MVP tercapai. Kandidat yang relevan dengan temuan:

- Pencarian yang lebih kuat (judul dan kategori sudah; rentang nominal dan tanggal belum).
- Ekspor Excel/PDF gratis tanpa batas — **sudah ada** (§5.10).
- Impor satu arah dari Sepran lewat berkas Excel — **sudah ada** (X-7).
- Impor satu arah dari HP Sepran lewat berkas JSON, lengkap dengan saldo tiap rekening — **sudah ada** (X-12).
- **Auto-capture transaksi dari notifikasi Android** untuk BCA, Livin Mandiri, BRImo, GoPay, OVO, DANA, ShopeePay, dan blu — **sudah ada** (§5.14).
- **Scan AI: membaca transaksi dari tangkapan layar** dengan OCR lokal, lalu menyimpannya massal setelah dikonfirmasi — **sudah ada** (§5.15).
- **Sinkronisasi opsional ke cloud dengan login Google** dan versi web yang memakai akun yang sama — **sudah ada** (§5.16).
- Ringkasan bulanan otomatis yang dikirim sebagai notifikasi di akhir bulan.
- Koreksi otomatis usulan kategori saat mengetik judul, dilatih dari riwayat pengguna sendiri.
- Backup lokal terenkripsi yang dapat dipindahkan antar perangkat tanpa akun.
- **Anggaran**, lengkap dengan sisa yang terbawa antar periode. Teksnya sudah ada di Sepran tapi fiturnya belum dirilis (§5.7), jadi ini lapangan yang masih kosong.

---

## 12. Definisi selesai untuk MVP

- [ ] Modul 5.1 sampai 5.6 berjalan penuh, termasuk empat jenis pergerakan uang.
- [ ] Rekap Realtime dan Bulanan berjalan, dengan tiga cara penyajian (grafik, kategori, judul).
- [ ] Riwayat dan pencarian berjalan.
- [ ] Ekspor Excel dan PDF berjalan dan gratis.
- [ ] Impor dari Sepran berjalan lewat berkas Excel dan JSON.
- [ ] Backup dan pemulihan lokal berjalan.
- [ ] Pengaturan 5.12 berjalan, termasuk empat tema, tiga bahasa, PIN, dan pengingat.
- [ ] Seluruh invarian §6 punya test otomatis yang lulus.
- [ ] Aplikasi dapat dipakai satu bulan penuh tanpa data hilang atau saldo meleset.
- [ ] Tidak ada kerusakan pada uji kasus tepi §8.

---

## 13. Yang masih perlu kamu verifikasi di HP

Beberapa butir sudah terjawab dari tangkapan layar. Sisanya masih terbuka.

**Lembar kerja langkah demi langkah ada di [`docs/VERIFIKASI.md`](VERIFIKASI.md).**

### Sudah terjawab

| # | Pertanyaan | Jawaban |
| --- | --- | --- |
| 1 | Arti "Memberi" dan "Menerima" | Dua total terpisah di kepala halaman, tidak disatukan. Arah ditentukan oleh tanda nominal. Lihat §5.6 |
| 2 | Fitur Anggaran | **Tidak ada di antarmuka.** Teksnya ada, menunya tidak. Lihat §5.7 |
| 5 | Data bawaan | Sebagian: daftar rekening pada aplikasi yang sudah dipakai berisi rekening buatan pengguna sendiri (BLU, BNI, BSI, Dana, Gopay, OVO, ShopeePay, Uang Tunai Dompet, Uang Tunai Simpan). Belum jelas mana yang dibuat otomatis saat instal |
| 7 | Realtime vs Bulanan | Sebagian: **Bulanan** = daftar kartu per bulan dalam satu gulir. **Realtime** belum dilihat |
| 9 | Apakah judul dan kategori tidak tertukar | **Terjawab.** Di daftar, **kategori** adalah baris tebal dan **judul** baris abu-abu di bawahnya (T-11). Terlihat pada "Makan dan Minum" sebagai kategori dengan judul "Kopi Kenangan" dan "AW" |
| 10 | Status Lunas pada hutang | **Terjawab.** Ada, tetapi hanya di halaman detail, sebagai anak judul "Belum lunas" (H-9) |
| 11 | Field dan urutan form transaksi baru | **Terjawab.** Tombol `+` membuka tiga pilihan, bukan satu form (T-14). Susunan formnya ada di T-18 sampai T-21 |
| 12 | Di mana Koreksi Saldo berada | **Terjawab.** Bukan di menu `+` halaman Transaksi (T-15). Dibuat dari halaman Rekening dengan mengubah **Saldo Saat Ini**; selisihnya menjadi Koreksi Saldo (K-6) |
| 13 | Isi form Pemasukan, Pengeluaran, dan Pindah Saldo | **Terjawab.** Pemasukan dan Pengeluaran memakai form yang sama persis, berbeda hanya pada daftar saran (T-22). Pindah Saldo tidak punya Judul dan tidak punya Kategori (S-9) |

### Masih terbuka

| # | Pertanyaan | Memengaruhi | Cara cepat |
| --- | --- | --- | --- |
| 1 | Kolom hasil ekspor Excel dan PDF | X-3 | Terkunci pembayaran. Lewati saja, pakai enam kolom yang sudah tertera di berkas bahasa |
| 2 | Restore menimpa atau menggabung | B-4 | Butuh akun. Sudah kita putuskan sendiri di VERIFIKASI.md |
| 3 | Tren Aset: saldo atau akumulasi | L-6 | Tangkapan layar halaman Tren Aset |
| 4 | Isi tab Realtime | L-1c | Tangkapan layar tab Realtime |
| 5 | Urutan daftar transaksi dalam satu hari | T-9 | Butuh daftar hari berisi transaksi yang jamnya berbeda |
| 6 | Isi form entri hutang | H-12 | Tangkapan layar setelah memilih Memberi atau Menerima |
| 8 | Arti "Selisih" | T-17 | Tangkapan layar satu hari yang punya pemasukan **dan** pengeluaran |
| 9 | Sel ketiga pada ringkasan detail hutang | H-14 | Tangkapan layar catatan hutang yang punya entri di kedua arah |
| 10 | Arti Tanggal Mulai selain 1 | L-7b | Tangkapan layar Konfigurasi Rekap dengan nilai bukan 1 |

Untuk butir 5 dan 8: masukkan data uji terkontrol ke Sepran (nominal kecil),
lalu hitung sendiri hasil yang seharusnya. Bila angkanya sama dengan yang
ditampilkan, aturannya sudah benar. Untuk sisanya, tangkapan layar sudah cukup.

---

## 14. Lampiran: skema asli Sepran

Untuk rujukan. Rancangan tabel versi kita ada di `docs/DATA-MODEL.md`.

```sql
CREATE TABLE wallet (
  id TEXT PRIMARY KEY, name TEXT, walletTypeDesc STRING not null,
  balance REAL, frequentlyUsed INTEGER, currency TEXT, icon TEXT,
  createdAt INTEGER, updatedAt INTEGER)

CREATE TABLE data_harian (
  id INTEGER PRIMARY KEY, tanggal INTEGER, jumlah REAL, judul TEXT,
  kategori TEXT, keterangan TEXT, jenisTransaksi INTEGER,
  createdAt INTEGER, updatedAt INTEGER)
-- migrasi: ADD COLUMN idWallet TEXT, ADD COLUMN time INTEGER

CREATE TABLE balance_transfer (
  id TEXT PRIMARY KEY, date INTEGER, idWalletSource TEXT not null,
  idWalletDestination TEXT not null, amount REAL not null, note TEXT,
  createdAt INTEGER not null, updatedAt INTEGER not null)

CREATE TABLE balance_correction (
  id TEXT PRIMARY KEY, date INTEGER, idWallet TEXT not null,
  amount REAL not null, note TEXT, time INTEGER,
  createdAt INTEGER not null, updatedAt INTEGER not null)

CREATE TABLE hutang (
  id TEXT PRIMARY KEY, tanggal INTEGER, nama TEXT, noHp TEXT,
  isDone INTEGER, keterangan TEXT, createdAt INTEGER, updatedAt INTEGER)

CREATE TABLE hutang_detail (
  id TEXT PRIMARY KEY, idHutang TEXT, idWallet TEXT, tanggal INTEGER,
  jumlah REAL, keterangan TEXT, time INTEGER,
  createdAt INTEGER, updatedAt INTEGER)

CREATE TABLE kategori_data_harian (
  id INTEGER PRIMARY KEY, nama TEXT, jenisTransaksi INTEGER,
  terakhirDigunakan INTEGER, digunakan INTEGER,
  createdAt INTEGER, updatedAt INTEGER, UNIQUE(nama, jenisTransaksi))
-- judul_data_harian: struktur identik

CREATE TABLE laporan_data_harian (
  id INTEGER PRIMARY KEY, nama TEXT, tanggalMulai INTEGER,
  tanggalSelesai INTEGER, createdAt INTEGER, updatedAt INTEGER)
```
