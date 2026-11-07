# Usulan Delta SPEC — Mode **Normal | Target** pada Tab Hutang

Status: **diterapkan**. Aturan H-16 sampai H-29 sudah dipindahkan ke
`docs/SPEC.md` §5.6, kolomnya ke `docs/DATA-MODEL.md`, dan bukti perangkatnya ke
`docs/VERIFIKASI.md`. Dokumen ini disimpan sebagai catatan usulan aslinya,
bukan pengganti SPEC.

Pemilik implementasi: **modul_4** (`lib/features/debts/**`,
`lib/domain/debt_*`, `lib/data/debt_repository.dart`, dan migrasi di
`lib/data/db/app_database.dart`). Sesi modul_1 hanya menulis usulan ini; tidak
menyentuh kode Hutang.

---

## 1. Ringkasan keputusan

| # | Pertanyaan | Keputusan |
| --- | --- | --- |
| 1 | 5 juta itu pokok utang atau target menabung? | **Pokok utang** (yang harus dibayar). Bukan tujuan tabungan, jadi tidak bertabrakan dengan SPEC §10. |
| 2 | Custom hanya "saya berutang", atau dua arah? | **Dua arah**: `owe` (saya berutang) dan `owed` (orang berutang ke saya). Totalnya **wajib dipisah**. |
| 3 | Pembayaran dicatat sebagai apa? | **Entri hutang** (`debt_entries` bertanda), otomatis tercermin ke `transactions` dan Rekap. Bukan transaksi biasa yang dicocokkan otomatis. |

Seluruh rekomendasi pada diskusi sebelumnya ikut disetujui: label
**Normal | Target**, target hanya metadata, pembayaran wajib/default berekening,
kelebihan bayar diizinkan, utang dihapuskan lewat flag Lunas, peringatan saat
menghapus catatan, field "Sudah dibayar" saat membuat target, dan progress
sepanjang waktu.

---

## 2. Perubahan model data

### 2.1 Kolom baru pada `debts`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `target_amount` | INTEGER NULL | Pokok/target, selalu ≥ 0. `NULL` = catatan biasa (hanya tampil di Normal) |
| `target_direction` | TEXT NULL | `owe` = saya berutang; `owed` = orang berutang ke saya. `NULL` bila `target_amount` NULL |
| `paid_opening` | INTEGER NOT NULL DEFAULT 0 | Jumlah yang **sudah dibayar sebelum aplikasi dipakai**. Tidak pernah menyentuh rekening atau Rekap |

Aturan:

- `target_amount` **bukan** pergerakan uang. Ia tidak menulis `transactions` dan
  tidak masuk mutasi Rekap.
- `paid_opening` juga bukan pergerakan uang. Ia hanya titik awal progress.
- Bila `target_amount` NULL, `target_direction` harus NULL dan `paid_opening`
  harus 0. Ditegakkan di domain/repository.
- `target_amount = 0` diperlakukan sebagai "tanpa target" dan tidak muncul di
  tab Target.

### 2.2 Migrasi

- Naikkan `currentSchemaVersion` dari 1 ke 2.
- `ALTER TABLE debts ADD COLUMN ...` untuk ketiga kolom.
- Tulis baris `schema_migrations` (RW-10). Tidak ada penghapusan data.
- Uji migrasi dari basis data versi 1 yang sudah berisi catatan hutang.

### 2.3 Yang **tidak** berubah

- `debt_entries.amount` tetap bertanda dan tidak boleh 0.
- `debt_entries.wallet_id` tetap opsional secara skema (SPEC M-4). Kewajiban
  rekening hanya berlaku di **alur pembayaran Target** (lihat H-21).
- `debts` tetap tidak punya kolom jumlah/arah untuk buku besar. Target adalah
  kolom terpisah, bukan pengganti `net`.

---

## 3. Delta aturan SPEC

Kode H-16 dan seterusnya adalah tambahan. Aturan lama tetap berlaku kecuali
disebut eksplisit.

| Kode | Aturan |
| --- | --- |
| **H-16** | Halaman Hutang punya **dua mode tampilan**: **Normal** dan **Target**. Keduanya membaca data yang sama; yang berbeda adalah cara menyajikannya. Mode terakhir tidak perlu diingat lintas peluncuran. |
| **H-17** | Catatan boleh punya target: `debts.target_amount` + `debts.target_direction`. Target adalah **metadata pokok utang**, bukan saldo dan bukan transaksi. |
| **H-18** | Membuat atau mengubah target **tidak boleh** menulis `transactions`, tidak mengubah saldo rekening, dan tidak mengubah mutasi Rekap. |
| **H-19** | Tab **Normal** menampilkan **semua** catatan (termasuk yang bertarget) dengan bentuk yang sudah ada: dua total Menerima/Memberi, pencarian, dan daftar datar. Catatan bertarget diberi badge kecil **"Target"**. |
| **H-20** | Tab **Target** hanya menampilkan catatan dengan `target_amount > 0`. Header-nya **dua angka terpisah**: **Total sisa utang** (`owe`) dan **Total sisa piutang** (`owed`). Keduanya tidak pernah dijumlahkan (lanjutan H-1). |
| **H-21** | Pembayaran adalah `debt_entries` bertanda seperti biasa. Di alur Target, **rekening wajib dipilih** (atau terisi otomatis dari rekening terakhir) supaya saldo benar-benar berkurang. Bila pengguna mengosongkannya, tombol Simpan menampilkan peringatan "Tanpa rekening, saldo tidak berkurang" dan tidak menyimpan sampai rekening dipilih. |
| **H-22** | Progress dihitung di domain, bukan di UI: `paid = paid_opening + jumlah entri arah pembayaran`; `remaining = max(0, target − paid)`; `overpaid = max(0, paid − target)`; `fraction = (paid / target)` dibatasi 0..1. Entri yang diedit/dihapus otomatis mengubah progress. |
| **H-23** | Kelebihan bayar **diizinkan**. Tampilkan **"Lunas, lebih Rp X"**. Jangan memblokir pembayaran nyata. |
| **H-24** | Status Lunas otomatis muncul saat `remaining = 0`. Flag `is_settled` yang sudah ada tetap bisa dipakai untuk **utang yang dihapuskan** tanpa pembayaran. Menandai Lunas **tidak** membuat entri atau transaksi. |
| **H-25** | Target boleh diedit. Bila target baru < `paid`, tampilkan peringatan sebelum menyimpan; setelah disimpan, tampilkan "Lunas, lebih Rp X". Utang tambahan diselesaikan dengan **menaikkan target** (bukan entri pokok otomatis), supaya rumusnya tetap satu. |
| **H-26** | Konfirmasi hapus catatan harus menyebut bahwa **seluruh cicilan dan transaksi cerminnya ikut terhapus** dan **saldo rekening akan kembali**. Ini memperjelas perilaku H-7 yang sudah ada. |
| **H-27** | Saat membuat target, sediakan field opsional **"Sudah dibayar"**. Nilainya masuk ke `paid_opening`, **bukan** ke `debt_entries`, sehingga tidak mengubah saldo maupun Rekap. |
| **H-28** | Progress bersifat **sepanjang waktu**, bukan per bulan. Filter periode milik Rekap tidak berlaku di tab Target. |
| **H-29** | Pencarian (H-8) tetap berlaku di kedua mode. Urutan tab Target: sisa terbesar lebih dulu, lalu tanggal terbaru. Catatan Lunas tetap tampil dengan badge, di bawah catatan aktif. |

### 3.1 Hubungan dengan aturan lama

- **H-1** tetap: Menerima dan Memberi tidak disatukan. Tab Target menambah
  pemisahan yang sama untuk utang/piutang.
- **H-3/H-4** tetap: nominal baris Normal tetap `net` dari entri, bukan target.
- **H-11** **berubah secara sengaja**. SPEC lama menolak konsep "pokok plus
  cicilan"; fitur ini memperkenalkannya. Karena itu H-11 perlu ditandai `[★]`
  dan ditulis ulang: "Buku besar tetap dua arah; **target** adalah metadata
  pokok yang terpisah dan tidak mengubah buku besar."
- **M-4** tetap untuk form entri umum. Kewajiban rekening hanya di alur
  pembayaran Target (H-21).

---

## 4. Model domain

### 4.1 `DebtTargetDirection`

```dart
enum DebtTargetDirection {
  owe('owe'),   // saya berutang: pokok diterima, pembayaran = entri negatif
  owed('owed'); // orang berutang: pokok diberikan, pembayaran = entri positif
}
```

### 4.2 `DebtProgress`

Objek murni (tanpa Flutter/drift) dengan medan:

| Medan | Arti |
| --- | --- |
| `target` | `target_amount`, ≥ 0 |
| `paidOpening` | `paid_opening` |
| `paidEntries` | Jumlah besar entri arah pembayaran |
| `paid` | `paidOpening + paidEntries` |
| `remaining` | `max(0, target − paid)` |
| `overpaid` | `max(0, paid − target)` |
| `fraction` | `target == 0 ? 0 : (paid / target).clamp(0, 1)` |
| `isSettled` | flag manual atau `remaining == 0` |
| `isForgiven` | `is_settled == true && remaining > 0` |

Arah pembayaran:

- `owe` → entri dengan `amount < 0` (Memberi).
- `owed` → entri dengan `amount > 0` (Menerima).

**Jangan memakai `DebtSummary.remaining` yang sekarang** untuk progress. Getter
itu memakai `net.abs()`, sehingga kelebihan bayar justru tampil sebagai sisa.
`DebtProgress` harus punya rumus sendiri dan diuji terpisah.

### 4.3 `DebtRecord`

Tambahkan `targetAmount`, `targetDirection`, `paidOpening`, dan getter
`progress` (atau objek `DebtProgress` yang dihitung di repository). `net` dan
`magnitude` tetap seperti sekarang untuk tab Normal.

---

## 5. Repository

Tambahan operasi:

| Operasi | Perilaku |
| --- | --- |
| `createTarget(...)` | Menulis satu baris `debts` dengan target. **Tidak** menulis `debt_entries` atau `transactions`. |
| `updateTarget(...)` | Mengubah nama/tanggal/catatan/target/arah/`paid_opening`. Tidak menyentuh entri. |
| `clearTarget(id)` | Mengosongkan target; catatan kembali menjadi catatan Normal biasa. |
| `addPayment(...)` | Membungkus `addEntry` dengan tanda sesuai arah target, **mewajibkan** `walletId`, dan menulis cermin `transactions`. |
| `watchRecords()` | Ikut membaca `target_amount`, `target_direction`, `paid_opening`. |

`addPayment` harus menolak `walletId == null` dengan pesan yang bisa ditampilkan
ke pengguna, bukan `ArgumentError` mentah.

---

## 6. Tampilan

### 6.1 Pemilih mode

Pakai pola yang sama dengan Rekap (`_ReportTabs`): bingkai biru tipis di bawah
bilah judul, pilihan aktif terisi biru penuh. Label: **Normal | Target**.

### 6.2 Tab Normal

Tidak berubah dari sekarang, ditambah:

- Badge kecil **"Target"** pada baris yang punya target.
- Nominal trailing tetap `net` entri (H-4), bukan sisa target.
- Header tetap Menerima/Memberi.

### 6.3 Tab Target

Kepala:

- **Total sisa utang** (hanya `owe`, catatan yang belum Lunas).
- **Total sisa piutang** (hanya `owed`, catatan yang belum Lunas).
- Keduanya kartu terpisah, tidak dijumlahkan.

Kartu per catatan:

```text
Kakak                          [Lunas?]
Terbayar Rp200.000 dari Rp5.000.000
[========------------------]  4%
Sisa Rp4.800.000
[ Bayar ]
```

- Nama panjang dipangkas elipsis (maksimal 1 baris).
- Angka memakai `MoneyFormat` yang sedang aktif.
- `fraction` mengisi progress bar.
- Tombol **Bayar** membuka form entri dengan arah otomatis dan rekening wajib.
- Badge **Lunas** bila `isSettled`; bila `isForgiven`, detail menampilkan
  "Sisa dihapuskan Rp X".
- Bila `overpaid > 0`: **"Lunas, lebih Rp X"**.

Keadaan kosong: "Belum ada target utang" + ajakan membuat target.

FAB tab Target: **"Target Baru"**. FAB tab Normal tetap membuka menu dua arah
H-2.

### 6.4 Form target

Field berurutan:

1. Nama
2. Arah: **Saya berutang** / **Orang berutang ke saya**
3. Total target
4. Sudah dibayar (opsional; hanya mengisi `paid_opening`)
5. Tanggal
6. Catatan

Tidak ada field rekening di form target, karena target bukan pergerakan uang.
Teks bantuan: "Target tidak mengurangi saldo. Saldo baru berkurang saat kamu
mencatat pembayaran."

### 6.5 Halaman detail

- Tambahkan kartu progress di atas tiga sel ringkasan yang sudah ada (H-14).
- Tiga sel lama **tetap**: Menerima, Memberi, Sisa.
- Tombol **Bayar** di dekat kartu progress.
- Baris entri tetap seperti sekarang; entri pembayaran tampil sebagai Memberi
  (untuk `owe`) atau Menerima (untuk `owed`).

---

## 7. Acceptance criteria

1. **Membuat target tidak mengubah uang.** Given saldo BCA Rp1.000.000, when
   membuat target "Kakak" Rp5.000.000 arah `owe`, then tidak ada baris
   `transactions` baru, saldo BCA tetap Rp1.000.000, dan Rekap tidak berubah.
2. **Target tampil benar.** Then tab Target menampilkan "Terbayar Rp0 dari
   Rp5.000.000" dan "Sisa Rp5.000.000".
3. **Pembayaran mengurangi rekening dan progress.** Given target di atas, when
   membayar Rp200.000 dari BCA, then: satu `debt_entries` −200.000, satu
   `transactions` pengeluaran −200.000 kategori "Hutang Piutang", saldo BCA
   Rp800.000, baris Hutang Piutang di Rekap −200.000, dan kartu menampilkan
   "Terbayar Rp200.000 dari Rp5.000.000" serta "Sisa Rp4.800.000".
4. **Rekening wajib di alur Target.** When menekan Simpan tanpa memilih
   rekening, then muncul peringatan "Tanpa rekening, saldo tidak berkurang" dan
   data tidak tersimpan.
5. **Kelebihan bayar.** When total pembayaran Rp5.200.000, then tampil
   "Lunas, lebih Rp200.000" dan saldo tetap berkurang penuh Rp5.200.000.
6. **Utang dihapuskan.** When menandai Lunas saat sisa Rp4.800.000, then tidak
   ada entri/transaksi baru, saldo tidak berubah, badge Lunas muncul, dan
   detail menampilkan "Sisa dihapuskan Rp4.800.000".
7. **Menghapus catatan.** When menghapus catatan yang punya pembayaran, then
   konfirmasi menyebut cicilan + transaksi cermin + saldo kembali; setelah
   dihapus, transaksi cermin ikut terhapus dan saldo BCA naik Rp200.000.
8. **Dua arah tidak digabung.** Given target `owe` Rp5.000.000 dan `owed`
   Rp2.000.000, then header menampilkan dua angka terpisah, bukan Rp7.000.000
   atau Rp3.000.000.
9. **Edit target di bawah paid.** Given sudah dibayar Rp4.500.000, when
   mengubah target menjadi Rp4.000.000, then muncul peringatan; bila
   dilanjutkan, tampil "Lunas, lebih Rp500.000".
10. **Target nol/kosong.** When `target_amount` NULL atau 0, then catatan tidak
    muncul di tab Target tetapi tetap muncul di Normal.
11. **Normal tetap utuh.** Catatan bertarget muncul di Normal dengan badge
    "Target" dan nominal `net` entri, bukan sisa target.
12. **Pencarian.** Pencarian bekerja di kedua mode dan menyaring daftar tanpa
    mengubah total header.
13. **Edit/hapus entri.** When entri pembayaran diedit atau dihapus, then
    progress dan sisa langsung dihitung ulang.
14. **Format uang.** When pengaturan desimal diubah, then semua angka progress
    mengikuti format yang sama.
15. **Font 200%.** When ukuran font sistem 200%, then tidak ada teks yang
    terpotong; nama panjang memakai elipsis.

---

## 8. Rencana pengujian

### Domain (`test/domain/debt_progress_test.dart`)

- `owe` dan `owed` dengan pembayaran sebagian.
- `paid_opening` ikut dihitung.
- Target 0 / negatif.
- Kelebihan bayar.
- `is_settled` tanpa pembayaran (forgiven).
- Entri arah berlawanan tidak mengurangi progress.
- `fraction` dibatasi 0..1.

### Repository (`test/data/debt_repository_test.dart`)

- `createTarget` tidak menulis `transactions`.
- `createTarget` menulis ketiga kolom target.
- `addPayment` menolak tanpa rekening.
- `addPayment` menulis entri bertanda benar untuk `owe` dan `owed`.
- `addPayment` menulis satu cermin `transactions` dan Rekap ikut berubah.
- `updateTarget` tidak menyentuh entri.
- `clearTarget` mengembalikan catatan ke Normal.
- Migrasi v1 → v2 mempertahankan data lama.

### Widget (`test/features/debts/...`)

- Dua tab muncul dan bisa berpindah.
- Total utang dan piutang terpisah.
- Kartu menampilkan "Terbayar … dari …", "Sisa …", progress bar.
- Peringatan rekening kosong.
- Badge Lunas dan "lebih Rp X".
- Keadaan kosong.

---

## 9. Kasus tepi

| Kasus | Perilaku |
| --- | --- |
| Target diubah beberapa kali | Selalu dihitung ulang dari `target` + entri saat ini |
| Pembayaran mundur tanggalnya | Tetap dihitung; progress sepanjang waktu |
| Beberapa catatan untuk orang yang sama | Boleh; masing-masing punya target sendiri |
| Pembayaran dari beberapa rekening | Boleh; tiap entri punya rekeningnya sendiri |
| Entri arah pokok (mis. pinjam tambahan) | Tidak menambah progress otomatis; naikkan target (H-25) |
| Catatan Lunas | Tetap tampil di bawah, bisa dicari, tidak masuk total sisa |
| Rekening pembayaran dihapus | Ditolak oleh R-4/RW-14 yang sudah ada |
| Menghapus catatan | Peringatan H-26; saldo kembali karena cermin ikut terhapus |
| Target sangat besar | Batas yang sama dengan nominal transaksi |

---

## 10. Di luar lingkup

- Tujuan tabungan (SPEC §10).
- Bunga, denda, tanggal jatuh tempo.
- Pencocokan otomatis transaksi biasa ke target.
- Multi mata uang.
- Grafik tren utang.
- Pengingat/notifikasi pembayaran.

---

## 11. Catatan untuk modul_4

1. **Jangan** membuat entri pokok otomatis saat membuat target. Itu akan
   memunculkan 5 juta di Rekap dan melanggar H-18.
2. **Jangan** memakai `DebtSummary.remaining` untuk progress (lihat §4.2).
3. **Wajibkan rekening** hanya di alur pembayaran Target; form entri umum tetap
   mengikuti M-4.
4. **Pisahkan total** `owe` dan `owed`; jangan pernah menjumlahkannya.
5. **Migrasi** harus diuji dari basis data v1 yang sudah berisi data.
6. Pola pemilih mode bisa disalin dari `_ReportTabs` di
   `lib/features/reports/report_screen.dart`. Bila ingin dijadikan widget
   bersama, koordinasikan dengan pemilik `lib/core`.

### Temuan terpisah (bukan bagian fitur ini)

`lib/data/report_repository.dart` menghitung baris Hutang Piutang dari **semua**
`debt_entries`, termasuk yang `wallet_id`-nya NULL, lalu `DailyTotals.movement`
memasukkannya ke Saldo Akhir Rekap. Akibatnya entri hutang tanpa rekening
menggeser Saldo Akhir Rekap tetapi tidak menggeser Total Saldo Rekening. Fitur
ini tidak memicunya karena target bukan entri dan pembayaran wajib berekening,
tetapi sebaiknya diperbaiki terpisah dengan menambahkan
`AND wallet_id IS NOT NULL` pada subquery `debt` di Rekap.
