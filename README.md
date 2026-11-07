# Spendly — Smart Financial Tracker

<p align="center">
  <img src="assets/images/app_logo.png" alt="Spendly Logo" width="120" />
</p>

<p align="center">
  <b>Aplikasi pencatatan keuangan pribadi modern: Offline-First, bertenaga AI OCR, tangkap notifikasi otomatis, dan sinkronisasi cloud opsional.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Database-Drift%20(SQLite)-003B57?logo=sqlite" alt="SQLite" />
  <img src="https://img.shields.io/badge/Architecture-Riverpod-purple" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-success" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" />
</p>

---

## 📌 Sekilas Tentang Spendly

Spendly dibangun dengan filosofi **Offline-First & Data Privasi Penuh**. Pengguna
tidak dipaksa membuat akun untuk menggunakan aplikasi. Semua pencatatan
tersimpan aman di database lokal perangkat Anda, dengan opsi sinkronisasi cloud
multi-perangkat jika diinginkan.

- **Data milik pengguna** — tanpa akun wajib, tanpa iklan, tanpa pelacakan.
- **Bekerja tanpa internet** — seluruh fitur inti berjalan dari SQLite lokal.
- **Cloud opsional** — aktifkan Supabase + Google Login hanya bila perlu.
- **516 test otomatis** menjaga aturan saldo, migrasi, OCR, dan notifikasi.

---

## ✨ Fitur Unggulan

### 1. 🤖 AI Screenshot Scanner (OCR Mutasi)

- Pindai riwayat transaksi e-wallet (DANA, GoPay, OVO, ShopeePay) atau
  m-banking cukup dari satu atau beberapa screenshot sekaligus.
- Ekstraksi nominal, tanggal, jam, dan keterangan secara otomatis dengan
  Google ML Kit di perangkat — gambar tidak dikirim ke server.
- Pratinjau dan edit batch sebelum disimpan: kategori bisa ditulis bebas,
  arah masuk/keluar diatur per baris atau sekaligus, dompet sumber dideteksi
  otomatis, dan baris yang sudah tercatat ditandai sebagai duplikat.
- Tombol **Lihat foto sumber** membuka gambar asli untuk memeriksa detail.

### 2. 🔔 Auto-Capture Notifikasi Android

- Menangkap notifikasi transaksi masuk/keluar dari aplikasi perbankan dan
  e-wallet secara real-time lewat `NotificationListenerService`.
- Tetap aktif meski aplikasi ditutup atau HP baru dinyalakan
  (`BOOT_COMPLETED`).
- Notifikasi disimpan sebagai **Draft Transaksi** di Inbox dengan
  pull-to-refresh, lalu diverifikasi manual sebelum masuk buku kas.
- Parser mencakup DANA, GoPay, OVO, ShopeePay, blu, BCA, Livin Mandiri, dan
  BRImo (format baru selalu bisa berbeda; draft tetap perlu diperiksa).

### 3. 💼 Multi-Rekening & Manajemen Dompet

- Kelola rekening bank, dompet digital, dan uang tunai dalam satu tempat.
- Transfer antar dompet dengan **biaya admin opsional** yang otomatis
  dipotong dari rekening asal sebagai baris pengeluaran terpisah.
- Penyesuaian/koreksi saldo dan riwayat perubahan saldo.
- Wajib memilih dompet saat input transaksi, plus filter dompet di daftar
  transaksi agar tidak salah catat.

### 4. 📊 Rekap, Analitik, & Grafik Interaktif

- Visualisasi pemasukan vs pengeluaran lewat grafik lingkaran dan batang
  (`fl_chart`).
- Laporan per kategori, bulanan, mingguan, harian, hingga rentang tanggal
  kustom.
- Ringkasan tren aset dan kartu ringkasan yang mengikuti filter aktif.

### 5. 🎯 Pelacak Hutang & Piutang

- Pencatatan hutang/piutang dengan dua mode: **Normal** dan
  **Target/Cicilan**.
- Riwayat pembayaran terperinci, sisa tagihan, dan status pelunasan.

### 6. 🌐 Sinkronisasi Cloud & Akses Web Opsional

- Default berjalan 100% lokal tanpa koneksi internet.
- Opsi masuk dengan Google Account via Supabase untuk sinkronisasi dua arah
  ke versi Web.
- Build tanpa kredensial Supabase tetap berjalan normal sebagai aplikasi
  lokal.

### 7. 📄 Ekspor & Impor Data

- Ekspor laporan keuangan ke **Excel (.xlsx)** dan **PDF** untuk rentang
  tanggal pilihan.
- Impor riwayat transaksi dari Sepran dalam format Excel maupun JSON.
- Backup dan restore dalam aplikasi belum tersedia; gunakan ekspor berkala
  sampai fitur tersebut dirilis.

---

## 🛠️ Tech Stack

| Layer | Teknologi |
| --- | --- |
| Framework | Flutter (Dart SDK `^3.13.5`) |
| State Management | Flutter Riverpod |
| Local Database | Drift + SQLite (`drift_flutter`, `sqlite3`) |
| Navigation | GoRouter |
| Charts | FL Chart |
| AI / OCR | Google ML Kit Text Recognition (on-device) |
| Background Task | Android `NotificationListenerService` + `BOOT_COMPLETED` |
| Notifikasi Lokal | `flutter_local_notifications` + `timezone` |
| Cloud Sync (opsional) | Supabase + Google OAuth |
| Ekspor Berkas | `excel`, `pdf`, `share_plus`, `file_picker` |

---

## 🚀 Memulai (Local Setup)

### Prasyarat

- Flutter SDK `>= 3.13.5`
- Android Studio / Android SDK (platform 34/35, NDK)
- Git

### Langkah Instalasi

1. Clone repositori:

   ```bash
   git clone https://github.com/tazzz-dev/spendly.git
   cd spendly
   ```

2. Pasang dependensi:

   ```bash
   flutter pub get
   ```

3. Generate kode database (Drift):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Jalankan aplikasi:

   ```bash
   # Jalankan di Android device/emulator
   flutter run

   # Jalankan versi Web
   flutter run -d chrome
   ```

### (Opsional) Menjalankan dengan Cloud Sync

Jika ingin menyalakan fitur sinkronisasi Supabase + Google Login:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Panduan skema dan batasan sinkronisasi ada di
[docs/SINKRONISASI.md](docs/SINKRONISASI.md).

### Catatan Build Release Android

Release Android sengaja mematikan R8 (`isMinifyEnabled = false`) karena R8
memangkas kelas ML Kit yang dibaca lewat refleksi dan membuat OCR gagal dengan
`NullPointerException`. Konsekuensinya ukuran APK sedikit lebih besar, tetapi
Scan AI tetap stabil.

---

## 📱 Panduan Izin Aplikasi (Android)

Untuk menjalankan fitur otomatisasi penuh:

- **Akses Notifikasi (Notification Access):** aktifkan di
  *Pengaturan HP > Aplikasi > Akses Khusus > Akses Notifikasi* agar Spendly
  dapat membaca draft transaksi e-wallet/bank.
- **Izin Foto & Galeri:** diperlukan untuk fitur Scan AI / OCR tangkapan layar.
- **Optimasi Baterai:** matikan pembatasan baterai (*Don't optimize*) agar
  service background tidak dimatikan paksa oleh sistem.
- **Izin Notifikasi (Android 13+):** diperlukan untuk pengingat harian.

---

## 📂 Struktur Direktori

```text
lib/
├── app/                # Bootstrap, router GoRouter, tema, dan shell navigasi
├── core/               # Utilitas format uang/tanggal dan palet warna
├── data/
│   ├── db/             # Skema tabel Drift & migrasi SQLite
│   ├── ocr/            # Mesin OCR ML Kit dan penyusun ulang teks
│   └── sync/           # Klien sinkronisasi Supabase (opsional)
├── domain/             # Model, aturan saldo, parser notifikasi/mutasi
├── features/
│   ├── debts/          # Hutang & piutang (Normal dan Target/Cicilan)
│   ├── notifications/  # Inbox draft dan pengaturan auto-capture
│   ├── reports/        # Rekap, grafik, dan laporan kustom
│   ├── scan/           # Scan AI: pilih gambar, OCR, dan pratinjau
│   ├── settings/       # Pengaturan, pengingat, impor, dan sinkronisasi
│   ├── transactions/   # Transaksi, transfer, ekspor, dan riwayat
│   └── wallets/        # Daftar dan form rekening/dompet
└── l10n/               # Berkas terjemahan (ARB)
```

---

## 📚 Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [docs/SPEC.md](docs/SPEC.md) | Spesifikasi fungsional dan acuan utama |
| [docs/DATA-MODEL.md](docs/DATA-MODEL.md) | Skema SQLite, rumus saldo, dan aturan tulis |
| [docs/RENCANA-BUILD.md](docs/RENCANA-BUILD.md) | Keputusan teknis dan struktur folder |
| [docs/SINKRONISASI.md](docs/SINKRONISASI.md) | Menyalakan Supabase + Google dan batasannya |

Catatan verifikasi perangkat berisi data pengujian pribadi dan sengaja tidak
dipublikasikan.

---

## 📄 Lisensi

Didistribusikan di bawah lisensi **MIT**. Lihat berkas [LICENSE](LICENSE) untuk
informasi lebih lanjut.
