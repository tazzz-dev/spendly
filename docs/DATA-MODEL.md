# Rancangan Model Data

Versi 1.0 · Selaras dengan `docs/SPEC.md` versi 1.0 · Flutter + SQLite (disarankan `drift`)

## Keputusan desain yang mengunci sisanya

| # | Keputusan | Alasan |
| --- | --- | --- |
| D1 | Uang disimpan sebagai `INTEGER` rupiah utuh. Dilarang `REAL`. | Menghindari galat pembulatan. Sepran memakai `REAL`; lihat SPEC G-11. |
| D2 | Satu tabel `transactions` untuk semua jenis pergerakan uang, dibedakan kolom `kind`. | Rumus saldo menjadi satu penjumlahan. Sepran memakai empat tabel terpisah; lihat SPEC S-7. |
| D3 | `amount` disimpan **ber-tanda** dan tidak pernah 0. Pemasukan positif, pengeluaran negatif. | Rumus saldo jadi `opening_balance + SUM(amount)`, tanpa `CASE WHEN`. |
| D4 | Pindah Saldo diwakili **dua baris** terhubung `transfer_group_id`. Tidak ada tabel grup terpisah. | Cukup. Kedua baris membawa tanggal, jam, dan keterangan yang sama. |
| D5 | Tanggal disimpan sebagai teks lokal `YYYY-MM-DD`. | SPEC G-4. |
| D6 | Semua penghapusan memakai kolom `deleted_at`. | SPEC T-8. Sepran menghapus permanen; lihat INV-5. |
| D7 | Primary key memakai UUID, bukan auto-increment. | Aman saat pemulihan backup dan penggabungan dari perangkat lain. |
| D8 | Judul dan kategori adalah **teks bebas** di dalam `transactions`, bukan kunci asing ke tabel kategori. | Meniru Sepran (SPEC C-1). Daftar saran disimpan terpisah dan dikelola lewat layar Kelola Kategori. |
| D9 | Biaya admin Pindah Saldo disimpan sebagai baris `expense` **ketiga** dengan `transfer_group_id` yang sama, bukan kolom baru. | Saldo asal otomatis terpotong jumlah transfer + biaya, rekap menampilkannya sebagai pengeluaran biasa, dan tidak perlu migrasi skema (SPEC S-6). |

## Skema tabel

### `wallets`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | UUID |
| `name` | TEXT NOT NULL | Unik di antara baris yang belum dihapus, ditegakkan index parsial. SPEC G-9, lihat RW-13 |
| `type` | TEXT NOT NULL | `cash` \| `bank` \| `ewallet` \| `credit_card` \| `investment` \| `other` |
| `opening_balance` | INTEGER NOT NULL DEFAULT 0 | Yang diisi pengguna saat rekening dibuat; sesudah itu tidak ditulis ulang dari layar Ubah Rekening (SPEC K-6) |
| `currency` | TEXT NOT NULL DEFAULT 'IDR' | SPEC R-6, belum dipakai di UI |
| `icon` | TEXT | |
| `color` | INTEGER | ARGB |
| `is_default` | INTEGER NOT NULL DEFAULT 0 | SPEC G-8. Tepat satu baris bernilai 1. |
| `use_count` | INTEGER NOT NULL DEFAULT 0 | SPEC R-3 |
| `sort_order` | INTEGER NOT NULL DEFAULT 0 | |
| `archived_at` | INTEGER | NULL = aktif |
| `deleted_at` | INTEGER | |
| `created_at` / `updated_at` | INTEGER NOT NULL | Epoch ms |

Pemetaan dari Sepran: `balance` → `opening_balance`, `frequentlyUsed` → `use_count`, `walletTypeDesc` → `type`.

**Impor JSON dari HP (SPEC X-12).** Berkas JSON membawa saldo **akhir**
(`wallet_balances[].balance`), bukan saldo awal. Karena itu nilainya tidak
disalin langsung ke `opening_balance`. Untuk tiap rekening:

```
opening_balance = round(balance) - SUM(mutasi bertanda rekening itu)
```

Mutasi bertanda diambil dari aturan `transactions.amount` (D3): pemasukan
positif, pengeluaran negatif, pindah saldo mengurangi rekening asal dan
menambah rekening tujuan. Hasilnya, saldo akhir
(`opening_balance + SUM(amount)`) sama dengan saldo di HP. Tidak ada kolom baru:
saldo target tidak disimpan, hanya dipakai saat impor. Pindah saldo tetap
menjadi dua baris dengan satu `transfer_group_id` (D4).

### `transactions`

Satu tabel untuk seluruh pergerakan uang.

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | UUID |
| `kind` | TEXT NOT NULL | `income` \| `expense` \| `transfer_out` \| `transfer_in` \| `correction` |
| `wallet_id` | TEXT NOT NULL | FK → `wallets.id` |
| `counter_wallet_id` | TEXT NULL | Rekening pasangan, hanya untuk kedua jenis transfer |
| `transfer_group_id` | TEXT NULL | UUID, hanya untuk kedua jenis transfer |
| `title` | TEXT NULL | **Judul.** Wajib untuk `income` dan `expense` (SPEC T-1). **NULL hanya untuk kedua baris transfer**, karena form Pindah Saldo memang tidak punya field judul (SPEC S-9). `correction` tetap berjudul, diisi otomatis |
| `category` | TEXT NULL | Teks bebas. NULL untuk transfer |
| `note` | TEXT | Keterangan, opsional |
| `amount` | INTEGER NOT NULL | Ber-tanda, ≠ 0 (D3) |
| `date` | TEXT NOT NULL | `YYYY-MM-DD` lokal |
| `time` | TEXT NULL | `HH:MM`, opsional (SPEC G-5) |
| `debt_entry_id` | TEXT NULL | FK → `debt_entries.id` bila baris ini lahir dari entri hutang |
| `created_at` / `updated_at` | INTEGER NOT NULL | |
| `deleted_at` | INTEGER | |

Tanda `amount` per jenis:

| `kind` | Tanda | Field yang dipakai |
| --- | --- | --- |
| `income` | + | title, category, wallet, amount |
| `expense` | − | title, category, wallet, amount |
| `transfer_out` | − | wallet = rekening asal, counter_wallet_id = tujuan. **title NULL, category NULL** |
| `transfer_in` | + | wallet = rekening tujuan, counter_wallet_id = asal. **title NULL, category NULL** |
| `correction` | ± | wallet, amount, note. Title diisi otomatis, category NULL |

Index:

```sql
idx_tx_date            ON transactions(date DESC)            WHERE deleted_at IS NULL
idx_tx_wallet          ON transactions(wallet_id, date DESC) WHERE deleted_at IS NULL
idx_tx_category        ON transactions(category, date)       WHERE deleted_at IS NULL
idx_tx_transfer_group  ON transactions(transfer_group_id)
idx_tx_debt_entry      ON transactions(debt_entry_id)
```

### `suggestions`

Menggantikan `kategori_data_harian` dan `judul_data_harian` milik Sepran. Satu
tabel, dibedakan kolom `type`.

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | |
| `type` | TEXT NOT NULL | `title` \| `category` |
| `name` | TEXT NOT NULL | |
| `kind` | TEXT NOT NULL | `income` \| `expense` (SPEC C-3) |
| `use_count` | INTEGER NOT NULL DEFAULT 0 | `digunakan` di Sepran |
| `last_used_at` | INTEGER NULL | `terakhirDigunakan` di Sepran |
| `created_at` / `updated_at` | INTEGER NOT NULL | |
| — | — | `UNIQUE(type, name, kind)` |

Aturan pengelolaan:

| Kode | Aturan |
| --- | --- |
| SG-1 | Saat transaksi disimpan, naikkan `use_count` dan perbarui `last_used_at` untuk judul dan kategori terkait. |
| SG-2 | Saat transaksi dihapus, turunkan `use_count` dengan batas bawah nol (SPEC C-6). |
| SG-3 | Saran yang `last_used_at` lebih lama dari 30 hari dihapus berkala (SPEC C-10). |
| SG-4 | Layar Kelola Kategori bekerja pada `type='category'`. Mengganti nama berarti `UPDATE transactions SET category = :baru WHERE category = :lama`. Bila nama baru sudah ada, artinya **menggabungkan** dua kategori. |
| SG-5 | Menghapus kategori yang masih dipakai ditolak. Pengguna diarahkan menggabungkan atau mengganti dulu. |
| SG-6 | Kategori dan judul dengan `kind` berbeda diperlakukan sebagai entri berbeda (SPEC C-3). |

### `debts`

Satu baris = satu catatan (orang atau keperluan). **Tidak ada kolom jumlah dan
tidak ada kolom arah pergerakan.** Nominal dan arah pergerakan diturunkan dari
entrinya — persis seperti Sepran (SPEC H-3, H-4).

Sejak skema v2 ada tiga kolom **target** yang bersifat metadata: ia tidak
pernah menjadi pergerakan uang, tidak menulis `debt_entries`, dan tidak
mengubah saldo maupun Rekap (SPEC H-18).

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | |
| `party_name` | TEXT NOT NULL | Nama orang atau keperluan (SPEC H-5) |
| `phone` | TEXT NULL | Nomor HP, opsional |
| `date` | TEXT NOT NULL | |
| `note` | TEXT | Keterangan. Bila kosong, ditampilkan sebagai "Tanpa keterangan" |
| `is_settled` | INTEGER NOT NULL DEFAULT 0 | Flag "Lunas" manual; dipakai untuk utang yang dihapuskan (SPEC H-9, H-24) |
| `target_amount` | INTEGER NULL | Pokok/target. `NULL` atau 0 = catatan Normal (SPEC H-17) |
| `target_direction` | TEXT NULL | `owe` \| `owed`. Wajib `NULL` bila `target_amount` `NULL` |
| `paid_opening` | INTEGER NOT NULL DEFAULT 0 | Sudah dibayar sebelum aplikasi dipakai; hanya titik awal progress (SPEC H-27) |
| `deleted_at` | INTEGER | |
| `created_at` / `updated_at` | INTEGER NOT NULL | |

Ketiga kolom target ditambahkan lewat migrasi **v1 → v2** (`ALTER TABLE`, tanpa
menghapus data). Target bukan pergerakan uang: ia tidak menulis
`transactions` dan tidak masuk Rekap (SPEC H-18). Bila `target_amount` NULL,
`target_direction` juga NULL dan `paid_opening` 0.

Nominal dan arah sebuah catatan **dihitung**, bukan disimpan:

```sql
SELECT d.id, d.party_name, d.date, d.note, d.is_settled,
       COALESCE(SUM(e.amount), 0) AS net
FROM debts d
LEFT JOIN debt_entries e ON e.debt_id = d.id AND e.deleted_at IS NULL
WHERE d.deleted_at IS NULL
GROUP BY d.id;
```

`net > 0` berarti **Menerima** (hijau, bertanda `+`). `net < 0` berarti
**Memberi**. Dua total di kepala halaman dihitung dari situ:

```sql
SELECT SUM(CASE WHEN net > 0 THEN  net ELSE 0 END) AS total_menerima,
       SUM(CASE WHEN net < 0 THEN -net ELSE 0 END) AS total_memberi
FROM (SELECT d.id, COALESCE(SUM(e.amount), 0) AS net
      FROM debts d
      LEFT JOIN debt_entries e ON e.debt_id = d.id AND e.deleted_at IS NULL
      WHERE d.deleted_at IS NULL
      GROUP BY d.id);
```

### Progress target (SPEC H-22, H-23)

`paid_entries` hanya menjumlahkan entri yang **searah pembayaran**:

- `owe` (saya berutang) → entri negatif (Memberi);
- `owed` (orang berutang ke saya) → entri positif (Menerima).

Entri arah sebaliknya (mis. pinjam tambahan) **tidak** menambah progress.
`paid_opening` ikut dihitung sebagai titik awal, tetapi tidak pernah menjadi
entri atau baris `transactions`.

```sql
SELECT d.id, d.target_amount, d.target_direction, d.paid_opening,
       COALESCE(SUM(
         CASE
           WHEN d.target_direction = 'owe'  AND e.amount < 0 THEN -e.amount
           WHEN d.target_direction = 'owed' AND e.amount > 0 THEN  e.amount
           ELSE 0
         END
       ), 0) AS paid_entries
FROM debts d
LEFT JOIN debt_entries e ON e.debt_id = d.id AND e.deleted_at IS NULL
WHERE d.deleted_at IS NULL
GROUP BY d.id;
```

Di `domain/`:

```text
paid      = paid_opening + paid_entries
remaining = max(0, target_amount - paid)
overpaid  = max(0, paid - target_amount)
fraction  = paid / target_amount, dijepit 0..1
```

**Jangan** memakai `ABS(net)` sebagai progress: kelebihan bayar akan tampil
sebagai sisa.

Dua total di kepala tab Target hanya menghitung catatan bertarget yang **belum
lunas**:

```sql
SELECT
  SUM(CASE WHEN target_direction = 'owe'  THEN sisa ELSE 0 END) AS total_sisa_utang,
  SUM(CASE WHEN target_direction = 'owed' THEN sisa ELSE 0 END) AS total_sisa_piutang
FROM (SELECT d.target_direction,
             MAX(0, d.target_amount - (d.paid_opening + <paid_entries>)) AS sisa
      FROM debts d
      WHERE d.target_amount > 0
        AND d.is_settled = 0
        AND d.deleted_at IS NULL);
```

### Migrasi v1 → v2 (RW-10)

```sql
ALTER TABLE debts ADD COLUMN target_amount INTEGER;
ALTER TABLE debts ADD COLUMN target_direction TEXT;
ALTER TABLE debts ADD COLUMN paid_opening INTEGER NOT NULL DEFAULT 0;
INSERT INTO schema_migrations (version, applied_at) VALUES (2, :sekarang);
```

Tidak ada entri pokok palsu dan tidak ada data yang dihapus. Semua catatan lama
otomatis menjadi catatan Normal karena `target_amount` tetap `NULL`.

### Migrasi v2 → v3 (RW-10)

Auto-Capture Notifikasi menambah dua tabel baru dan tiga index. Tidak ada
`ALTER TABLE` pada tabel lama, sehingga transaksi, rekening, hutang, dan rekap
tidak berubah.

```sql
CREATE TABLE notification_drafts (...);
CREATE TABLE account_notification_mappings (...);
CREATE INDEX idx_notification_drafts_status ...;
CREATE UNIQUE INDEX idx_notification_drafts_source ...;
CREATE UNIQUE INDEX idx_notification_mappings_package_active ...;
INSERT INTO schema_migrations (version, applied_at) VALUES (3, :sekarang);
```

Saat membuka basis data, aplikasi juga menyalakan `PRAGMA journal_mode = WAL`
dan `PRAGMA busy_timeout = 5000`. Keduanya diperlukan karena aplikasi utama dan
mesin Flutter latar dapat menulis ke basis data yang sama ketika notifikasi
datang.

### `debt_entries`

Buku besar dua arah untuk satu catatan hutang. Nama aslinya di Sepran:
`hutang_detail`.

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | |
| `debt_id` | TEXT NOT NULL | FK → `debts.id`, **ON DELETE CASCADE** (SPEC H-7) |
| `amount` | INTEGER NOT NULL | **Bertanda**, tidak boleh 0. Positif = menerima, negatif = memberi |
| `date` | TEXT NOT NULL | |
| `time` | TEXT NULL | |
| `wallet_id` | TEXT NULL | **Opsional** (SPEC M-4) |
| `note` | TEXT | |
| `deleted_at` | INTEGER | |
| `created_at` / `updated_at` | INTEGER NOT NULL | |

Bila `wallet_id` terisi, satu baris `transactions` ikut dibuat atau diperbarui,
terhubung lewat `transactions.debt_entry_id`.

### `budgets`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | |
| `category` | TEXT NOT NULL | Nama kategori (teks) |
| `period` | TEXT NOT NULL | `monthly` \| `weekly` |
| `amount` | INTEGER NOT NULL | |
| `warn_percent` | INTEGER NOT NULL DEFAULT 80 | |
| `start_date` / `end_date` | TEXT NULL | NULL = tanpa batas |

> **Kita putuskan sendiri, bukan meniru.** Sepran tidak punya menu Anggaran sama
> sekali di versi 5.2.2 (SPEC §5.7), jadi tidak ada bentuk asli untuk ditiru.
> Struktur di atas adalah rancangan kita, dan bebas diubah sesuai kebutuhan
> fitur pembeda di SPEC §11.

### `custom_reports`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | |
| `name` | TEXT NOT NULL | Judul rekap (SPEC L-8) |
| `start_date` | TEXT NOT NULL | |
| `end_date` | TEXT NOT NULL | Harus ≥ `start_date` |
| `deleted_at` | INTEGER | |
| `created_at` / `updated_at` | INTEGER NOT NULL | |

Pemetaan dari Sepran: `laporan_data_harian` → `custom_reports`.

### `notification_drafts`

Draft transaksi dari notifikasi Android. Nominal di sini **selalu positif**;
arahnya disimpan di `type`, dan tanda untuk `transactions.amount` baru
ditentukan `Movement` saat draft disetujui (D3). Draft tidak pernah menulis
saldo sampai pengguna menekan **Simpan ke Transaksi**.

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | UUID |
| `package_name` | TEXT NOT NULL | Paket Android asal notifikasi |
| `app_name` | TEXT NOT NULL | Nama tampilan, mis. `DANA` |
| `raw_title` / `raw_message` | TEXT NOT NULL | Teks asli dari notifikasi |
| `amount` | INTEGER NOT NULL | Rupiah utuh, selalu > 0 |
| `type` | TEXT NOT NULL | `income` \| `expense` |
| `wallet_id` | TEXT NULL | FK → `wallets.id`; hasil pemetaan atau pilihan pengguna |
| `occurred_at` | INTEGER NOT NULL | Waktu notifikasi, epoch ms |
| `date` | TEXT NOT NULL | Tanggal lokal `YYYY-MM-DD` |
| `time` | TEXT NULL | Jam lokal `HH:MM` |
| `status` | TEXT NOT NULL DEFAULT 'pending' | `pending` \| `approved` \| `ignored` |
| `source_key` | TEXT NOT NULL | `paket|waktu|judul|isi`, unik untuk idempotensi |
| `approved_transaction_id` | TEXT NULL | ID transaksi yang lahir dari draft |
| `deleted_at` | INTEGER NULL | Diisi saat draft diabaikan |
| `created_at` / `updated_at` | INTEGER NOT NULL | Epoch ms |

Index:

```sql
CREATE INDEX idx_notification_drafts_status
  ON notification_drafts(status, occurred_at DESC)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX idx_notification_drafts_source
  ON notification_drafts(source_key);
```

Aturan:

| Kode | Aturan |
| --- | --- |
| ND-1 | Hanya draft `pending` yang tampil di inbox. Draft `approved`/`ignored` tetap tersimpan sebagai jejak. |
| ND-2 | `amount` tidak pernah negatif; arah ada di `type`. Saat disetujui, `createSimple` menentukan tanda berdasarkan jenis. |
| ND-3 | `source_key` unik mencegah satu notifikasi menjadi dua draft, termasuk saat mesin utama dan mesin latar memproses bersamaan. |
| ND-4 | Mengabaikan draft memakai hapus lunak (`status='ignored'`, `deleted_at` diisi), bukan `DELETE`. |
| ND-5 | Menyetujui draft menulis tepat satu baris `transactions` dan mengisi `approved_transaction_id` dalam satu transaksi basis data. |

### `account_notification_mappings`

Menghubungkan satu nama paket Android ke satu rekening Spendly.

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | TEXT PK | UUID |
| `package_name` | TEXT NOT NULL | Paket Android |
| `wallet_id` | TEXT NOT NULL | FK → `wallets.id` |
| `deleted_at` | INTEGER NULL | Pemetaan dilepas = hapus lunak |
| `created_at` / `updated_at` | INTEGER NOT NULL | Epoch ms |

```sql
CREATE UNIQUE INDEX idx_notification_mappings_package_active
  ON account_notification_mappings(package_name)
  WHERE deleted_at IS NULL;
```

Keunikan hanya berlaku pada baris aktif. Satu aplikasi bisa punya beberapa
nama paket (mis. GoPay lewat `com.gojek.app` dan `com.gojek.gopay`), dan layar
pengaturan memetakan semuanya sekaligus. Pemetaan yang dibuat setelah draft
masuk ikut mengisi draft `pending` yang `wallet_id`-nya masih NULL.

### `app_settings`

Kunci-nilai sederhana: `key` TEXT PK, `value` TEXT. Untuk seluruh setelan SPEC §5.12.

### `schema_migrations`

| Kolom | Tipe |
| --- | --- |
| `version` | INTEGER PK |
| `applied_at` | INTEGER NOT NULL |

Wajib ada sejak versi 1, agar pemulihan backup dari versi berbeda dapat ditolak dengan aman (SPEC B-10). Versi saat ini: **3** (v1 awal, v2 target hutang, v3 notifikasi).

## Query inti

### Saldo rekening (INV-1, INV-2)

Satu query, tanpa `CASE WHEN`, berkat D2 dan D3:

```sql
SELECT w.id,
       w.opening_balance + COALESCE(SUM(t.amount), 0) AS balance
FROM wallets w
LEFT JOIN transactions t
       ON t.wallet_id = w.id
      AND t.deleted_at IS NULL
WHERE w.deleted_at IS NULL
GROUP BY w.id;
```

Total Saldo = jumlah hasil query itu untuk seluruh rekening non-arsip.

### Rincian rekap per kategori

```sql
SELECT t.category,
       -SUM(t.amount) AS total      -- amount pengeluaran negatif
FROM transactions t
WHERE t.deleted_at IS NULL
  AND t.kind = 'expense'            -- atau 'income'
  AND t.date BETWEEN :mulai AND :selesai
GROUP BY t.category
ORDER BY total DESC;
```

Ganti `t.category` menjadi `t.title` untuk rincian per judul (SPEC L-3).

Pindah Saldo dan Koreksi Saldo tidak pernah muncul di sini karena `kind`-nya
dikecualikan (INV-6).

### Saldo Awal dan Saldo Akhir (SPEC L-1, L-9)

```sql
-- Saldo Awal: seluruh mutasi sebelum rentang
SELECT COALESCE(SUM(amount), 0) FROM transactions
WHERE deleted_at IS NULL AND date < :mulai;

-- Saldo Akhir = Saldo Awal + Selisih rentang
```

### Pencarian (SPEC F-4)

```sql
SELECT * FROM transactions
WHERE deleted_at IS NULL
  AND (title LIKE '%' || :q || '%'
    OR category LIKE '%' || :q || '%'
    OR note LIKE '%' || :q || '%'
    OR wallet_id        IN (SELECT id FROM wallets WHERE name LIKE '%' || :q || '%')
    OR counter_wallet_id IN (SELECT id FROM wallets WHERE name LIKE '%' || :q || '%'))
ORDER BY date DESC, time DESC;
```

## Aturan tulis yang harus dipatuhi lapisan repository

| Kode | Aturan |
| --- | --- |
| RW-1 | Setiap penulisan yang mengubah saldo dibungkus satu transaksi database. |
| RW-2 | Membuat Pindah Saldo menulis **dua** baris `transactions` dengan `transfer_group_id` sama, dalam satu transaksi database. |
| RW-3 | Menyunting Pindah Saldo menyunting kedua baris, tanpa mengubah `transfer_group_id`. |
| RW-4 | Menghapus Pindah Saldo mengisi `deleted_at` pada kedua barisnya. |
| RW-9 | Bila Pindah Saldo punya biaya admin, baris biaya ikut ditulis, disunting, dihapus, dan dipulihkan bersama kedua baris transfer. Menghapus baris biaya saja tidak menghapus transfernya. |
| RW-5 | Tanda dan nilai `amount` dihitung di **satu tempat saja** (satu fungsi pembuat baris), berdasarkan `kind`. Tidak ada penulisan langsung dari UI. |
| RW-6 | Penghapusan rekening ditolak bila masih ada baris `transactions` yang merujuknya (SPEC R-4). |
| RW-7 | Rekening default tidak boleh dihapus dan tidak boleh ada dua (SPEC G-8). |
| RW-8 | **Tidak ada batas antara "pokok" dan "cicilan".** Entri hutang boleh melebihi arah mana pun; buku besar dua arah memang mengizinkannya (SPEC H-11). Yang divalidasi hanya `amount` ≠ 0. |
| RW-9 | Tidak ada query yang membaca `transactions` tanpa menyaring `deleted_at IS NULL`, kecuali layar tempat sampah. |
| RW-10 | Perubahan skema selalu menambah entri `schema_migrations` beserta skrip naiknya. Tidak ada perubahan yang menghapus data. |
| RW-11 | Saat transaksi disimpan atau dihapus, `suggestions` diperbarui dalam transaksi database yang sama (SG-1, SG-2). |
| RW-12 | Baris `transfer_out` dan `transfer_in` ditulis dengan `title` NULL dan `category` NULL. Hanya `income`, `expense`, dan `correction` yang punya judul. |
| RW-13 | Keunikan nama rekening ditegakkan **index unik parsial** `idx_wallets_name_active` pada `wallets(name) WHERE deleted_at IS NULL` — bukan `unique()` pada kolomnya. Sebabnya hapus lunak: baris lama tetap ada, jadi index penuh akan membuat nama rekening yang sudah dihapus tidak pernah bisa dipakai lagi. Diperiksa juga lebih dulu di lapisan repository supaya pesannya jelas bagi pengguna. |
| RW-14 | Rekening diperiksa tidak boleh dihapus bila masih ditunjuk salah satu dari tiga tempat: `transactions.wallet_id`, `transactions.counter_wallet_id`, atau `debt_entries.wallet_id`. Melewatkan satu saja akan membuat aturan R-4 bocor. |

## Pemetaan lengkap dari Sepran

Untuk memudahkan pemeriksaan paritas saat menguji berdampingan.

| Sepran | Kita | Catatan |
| --- | --- | --- |
| `wallet.balance` | `wallets.opening_balance` | Nilai dasar yang diisi pengguna |
| `wallet.frequentlyUsed` | `wallets.use_count` | |
| `wallet.walletTypeDesc` | `wallets.type` | Dipetakan lewat enum |
| `data_harian` (`jenisTransaksi=1`) | `transactions` (`kind='income'`) | |
| `data_harian` (`jenisTransaksi=2`) | `transactions` (`kind='expense'`) | |
| `data_harian.judul` | `transactions.title` | |
| `data_harian.kategori` | `transactions.category` | |
| `data_harian.keterangan` | `transactions.note` | |
| `data_harian.time` | `transactions.time` | |
| `data_harian.tanggal` | `transactions.date` | Sepran epoch ms; kita teks. Lihat D5. |
| `balance_transfer` | 2 baris `transactions` (`transfer_out`, `transfer_in`) | Lihat D4 |
| `balance_correction` | `transactions` (`kind='correction'`) | |
| `kategori_data_harian` | `suggestions` (`type='category'`) | |
| `judul_data_harian` | `suggestions` (`type='title'`) | |
| `hutang` | `debts` | Tanpa kolom jumlah maupun arah; keduanya diturunkan dari entri |
| `hutang_detail` | `debt_entries` | Nominal **bertanda** |
| `laporan_data_harian` | `custom_reports` | |
| — (fitur belum dirilis di Sepran) | `budgets` | Rancangan kita sendiri |
| — (di luar SQLite) | `app_settings` | |
