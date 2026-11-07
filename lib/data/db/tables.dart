import 'package:drift/drift.dart';

/// Definisi tabel drift.
///
/// Mengikuti `docs/DATA-MODEL.md`. Setiap kolom uang memakai `integer` dalam
/// satuan rupiah utuh, tidak pernah `real`. Lihat SPEC G-11.
///
/// Semua tabel memakai hapus lunak (`deleted_at`), bukan hapus permanen.
/// Lihat SPEC T-8.

/// Wadah uang. Sepran menyebutnya "Rekening".
class Wallets extends Table {
  TextColumn get id => text()();

  /// SPEC G-9: nama rekening harus unik. Keunikannya ditegakkan index parsial
  /// di `app_database.dart`, bukan `unique()` di sini. Alasannya hapus lunak:
  /// kalau indeksnya berlaku untuk seluruh baris, nama rekening yang sudah
  /// dihapus tidak akan pernah bisa dipakai lagi. Lihat DATA-MODEL RW-13.
  TextColumn get name => text()();

  TextColumn get type => text()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Seluruh pergerakan uang, dalam satu tabel.
///
/// `kind` menentukan artinya, dan `amount` selalu bertanda:
/// pemasukan positif, pengeluaran negatif. Rumus saldo jadi satu penjumlahan
/// saja. Lihat SPEC §4 dan DATA-MODEL D2, D3.
@DataClassName('TxRow')
class Transactions extends Table {
  TextColumn get id => text()();

  /// `income` | `expense` | `transfer_out` | `transfer_in` | `correction`
  TextColumn get kind => text()();

  // Dua kolom di tabel ini menunjuk ke `wallets`, jadi keduanya perlu nama
  // rujukan yang berbeda. Tanpa ini drift mengeluh soal bentrok nama.
  @ReferenceName('walletTransactions')
  TextColumn get walletId => text().references(Wallets, #id)();

  /// Rekening pasangan. Hanya diisi untuk kedua jenis pindah saldo.
  @ReferenceName('counterWalletTransactions')
  TextColumn get counterWalletId =>
      text().nullable().references(Wallets, #id)();

  /// Menyatukan pasangan baris pindah saldo. Lihat SPEC S-7.
  TextColumn get transferGroupId => text().nullable()();

  /// Judul. Wajib untuk pemasukan dan pengeluaran (SPEC T-1), tetapi **kosong**
  /// untuk kedua baris pindah saldo: form Pindah Saldo memang tidak punya field
  /// judul sama sekali (SPEC S-9). Lihat DATA-MODEL RW-12.
  TextColumn get title => text().nullable()();

  /// Kategori sebagai teks bebas, bukan kunci asing. Lihat SPEC C-1.
  TextColumn get category => text().nullable()();

  TextColumn get note => text().nullable()();

  /// Bertanda, tidak pernah 0.
  IntColumn get amount => integer()();

  /// Tanggal lokal `YYYY-MM-DD`. Lihat SPEC G-4.
  TextColumn get date => text()();

  /// Jam `HH:MM`, opsional. Lihat SPEC G-5.
  TextColumn get time => text().nullable()();

  /// Diisi bila baris ini lahir dari entri hutang.
  TextColumn get debtEntryId => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Daftar saran judul dan kategori.
///
/// Menggabungkan `judul_data_harian` dan `kategori_data_harian` milik Sepran
/// menjadi satu tabel, dibedakan kolom `type`.
/// Lihat SPEC §5.5 dan DATA-MODEL SG-1 sampai SG-6.
class Suggestions extends Table {
  TextColumn get id => text()();

  /// `title` | `category`
  TextColumn get type => text()();

  TextColumn get name => text()();

  /// `income` | `expense`. Judul dan kategori dipisah per jenis (SPEC C-3).
  TextColumn get kind => text()();

  IntColumn get useCount => integer().withDefault(const Constant(0))();
  IntColumn get lastUsedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {type, name, kind},
  ];
}

/// Satu catatan hutang/piutang.
///
/// Tidak menyimpan jumlah maupun arah. Keduanya diturunkan dari entri.
/// Lihat SPEC H-3, H-4 dan DATA-MODEL.
class Debts extends Table {
  TextColumn get id => text()();

  /// Nama orang atau keperluan. Sepran memakai kolom `nama`. Lihat SPEC H-5.
  TextColumn get partyName => text()();

  TextColumn get phone => text().nullable()();
  TextColumn get date => text()();
  TextColumn get note => text().nullable()();

  /// Pokok/target catatan. `NULL` atau 0 = catatan biasa tanpa target.
  /// Target adalah metadata, bukan pergerakan uang.
  IntColumn get targetAmount => integer().nullable()();

  /// `owe` | `owed`. Wajib `NULL` bila [targetAmount] `NULL`.
  TextColumn get targetDirection => text().nullable()();

  /// Jumlah yang sudah dibayar sebelum aplikasi dipakai. Bukan entri dan tidak
  /// pernah menyentuh saldo maupun Rekap.
  IntColumn get paidOpening => integer().withDefault(const Constant(0))();

  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Entri bertanda pada satu catatan hutang. Nama asli Sepran: `hutang_detail`.
///
/// `amount` positif berarti menerima, negatif berarti memberi.
/// Lihat SPEC H-11 dan DATA-MODEL.
class DebtEntries extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  IntColumn get amount => integer()();
  TextColumn get date => text()();
  TextColumn get time => text().nullable()();

  /// Opsional. Bila kosong, entri tidak memengaruhi saldo mana pun (SPEC M-4).
  TextColumn get walletId => text().nullable().references(Wallets, #id)();

  TextColumn get note => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Anggaran. Tidak ada di Sepran, jadi ini rancangan kita sendiri.
/// Lihat SPEC §5.7 dan §11.
class Budgets extends Table {
  TextColumn get id => text()();

  /// Nama kategori sebagai teks, selaras dengan `transactions.category`.
  TextColumn get category => text()();

  /// `monthly` | `weekly`
  TextColumn get period => text()();

  IntColumn get amount => integer()();
  IntColumn get warnPercent => integer().withDefault(const Constant(80))();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rekap kustom yang disimpan. Nama asli Sepran: `laporan_data_harian`.
/// Lihat SPEC L-8.
class CustomReports extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Draft transaksi yang berasal dari notifikasi Android.
///
/// Nominal selalu positif; arahnya ada di [type]. Tanda transaksi baru
/// ditentukan `Movement` ketika draft disetujui, bukan di sini.
@DataClassName('NotificationDraftRow')
class NotificationDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  TextColumn get rawTitle => text()();
  TextColumn get rawMessage => text()();

  /// Nominal rupiah utuh, selalu positif.
  IntColumn get amount => integer()();

  /// `income` | `expense`.
  TextColumn get type => text()();

  /// Rekening hasil pemetaan paket aplikasi. Boleh kosong sampai pengguna
  /// memilih rekening di layar konfirmasi.
  TextColumn get walletId => text().nullable().references(Wallets, #id)();

  /// Waktu notifikasi muncul, epoch milidetik.
  IntColumn get occurredAt => integer()();

  /// Tanggal lokal `YYYY-MM-DD`.
  TextColumn get date => text()();

  /// Jam lokal `HH:MM`, opsional.
  TextColumn get time => text().nullable()();

  /// `pending` | `approved` | `ignored`.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Kunci idempoten agar notifikasi yang diposting ulang tidak menjadi dua
  /// draft.
  TextColumn get sourceKey => text()();

  /// Terisi setelah draft disetujui.
  TextColumn get approvedTransactionId => text().nullable()();

  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pemetaan paket aplikasi ke rekening Spendly.
///
/// Keunikan paket hanya berlaku pada baris yang belum dihapus. Itu sebabnya
/// keunikannya dibuat sebagai index parsial di `app_database.dart`, bukan
/// `unique()` di sini.
@DataClassName('AccountNotificationMappingRow')
class AccountNotificationMappings extends Table {
  TextColumn get id => text()();
  TextColumn get packageName => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Setelan kunci-nilai. Lihat SPEC §5.12.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Catatan versi skema, agar pemulihan backup dari versi berbeda dapat ditolak
/// dengan aman. Lihat SPEC B-10.
///
/// Sengaja tanpa kunci utama: satu-satunya kolomnya bilangan bulat, dan di
/// SQLite `INTEGER PRIMARY KEY` menjadi alias rowid yang dianggap naik sendiri.
/// Kalau dibiarkan, drift akan mengisi versinya sendiri dan catatan kita jadi
/// salah. Jadi `version` dibuat unik saja, bukan kunci utama.
class SchemaMigrations extends Table {
  IntColumn get version => integer()();
  IntColumn get appliedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {version},
  ];
}
