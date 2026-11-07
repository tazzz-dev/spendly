import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/wallet_balance.dart';
import '../../domain/wallet_type.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Transactions,
    Suggestions,
    Debts,
    DebtEntries,
    Budgets,
    CustomReports,
    AppSettings,
    SchemaMigrations,
    NotificationDrafts,
    AccountNotificationMappings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Versi skema saat ini. Naikkan setiap kali skema berubah, dan tambahkan
  /// langkahnya di [migration].
  ///
  /// Riwayat:
  /// - 1: skema awal.
  /// - 2: kolom target pada `debts` (USULAN-HUTANG-TARGET §2.2).
  /// - 3: draft notifikasi dan pemetaan rekening (Auto-Capture Notifikasi).
  static const int currentSchemaVersion = 3;

  @override
  int get schemaVersion => currentSchemaVersion;

  /// Membuka basis data di platform mana pun.
  ///
  /// Di Android/iOS tetap berkas SQLite biasa. Di web, drift memakai SQLite
  /// yang dikompilasi ke WebAssembly dengan penyimpanan OPFS (atau IndexedDB
  /// bila peramban belum mendukung OPFS). Dua berkas di `web/` disalin dari
  /// paket `drift`; lihat `docs/SINKRONISASI.md`.
  ///
  /// Basis data web ini **lokal untuk peramban itu**. Data antarperangkat
  /// berpindah lewat sinkronisasi Supabase, bukan lewat berkas ini.
  static QueryExecutor _open() => driftDatabase(
    name: 'pencatatan_keuangan',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in [
        ..._indexStatements,
        ..._notificationIndexStatements,
      ]) {
        await customStatement(statement);
      }
      await _seedFirstRun();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: kolom target. Tidak ada data yang dihapus; catatan lama
      // otomatis menjadi catatan Normal karena target_amount tetap NULL.
      if (from < 2) {
        await customStatement(
          'ALTER TABLE debts ADD COLUMN target_amount INTEGER',
        );
        await customStatement(
          'ALTER TABLE debts ADD COLUMN target_direction TEXT',
        );
        await customStatement(
          'ALTER TABLE debts ADD COLUMN paid_opening INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await customStatement(
          'INSERT OR IGNORE INTO schema_migrations (version, applied_at) '
          'VALUES (?, ?)',
          [2, DateTime.now().millisecondsSinceEpoch],
        );
      }

      // v2 → v3: inbox notifikasi. Tabel baru tidak menyentuh data lama.
      if (from < 3) {
        await m.createTable(notificationDrafts);
        await m.createTable(accountNotificationMappings);
        for (final statement in _notificationIndexStatements) {
          await customStatement(statement);
        }
        await customStatement(
          'INSERT OR IGNORE INTO schema_migrations (version, applied_at) '
          'VALUES (?, ?)',
          [3, DateTime.now().millisecondsSinceEpoch],
        );
      }
    },
    beforeOpen: (details) async {
      // Menyalakan penegakan kunci asing. Ini jaring pengaman terakhir:
      // menghapus rekening yang masih dirujuk akan ditolak oleh basis data.
      // Lihat SPEC R-4.
      await customStatement('PRAGMA foreign_keys = ON');

      // Aplikasi utama dan mesin latar notifikasi dapat membuka basis data
      // yang sama. WAL membuat pembacaan tidak saling mengunci, sedangkan
      // busy_timeout memberi kesempatan penulisan lain menyelesaikan
      // transaksinya. Tanpa ini, notifikasi yang datang bersamaan dengan
      // layar terbuka bisa gagal tersimpan.
      //
      // Di web, WAL dan busy_timeout tidak berlaku untuk VFS peramban dan
      // justru bisa menggagalkan pembukaan basis data. Web hanya dipakai oleh
      // satu tab, jadi keduanya dilewati.
      if (!kIsWeb) {
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA busy_timeout = 5000');
      }
    },
  );

  /// Index khusus inbox notifikasi. Dipisah karena dipakai lagi saat migrasi
  /// v3 dan tidak boleh mencampur index tabel lama.
  static const List<String> _notificationIndexStatements = [
    'CREATE INDEX idx_notification_drafts_status '
        'ON notification_drafts(status, occurred_at DESC) '
        'WHERE deleted_at IS NULL',
    'CREATE UNIQUE INDEX idx_notification_drafts_source '
        'ON notification_drafts(source_key)',
    'CREATE UNIQUE INDEX idx_notification_mappings_package_active '
        'ON account_notification_mappings(package_name) '
        'WHERE deleted_at IS NULL',
  ];

  /// Index yang tidak bisa dinyatakan lewat kelas tabel drift.
  static const List<String> _indexStatements = [
    // SPEC G-9. Index parsial, bukan `unique()` pada kolomnya: keunikan hanya
    // berlaku di antara rekening yang belum dihapus, supaya nama rekening yang
    // sudah dihapus bisa dipakai lagi.
    'CREATE UNIQUE INDEX idx_wallets_name_active ON wallets(name) WHERE deleted_at IS NULL',
    'CREATE INDEX idx_tx_date ON transactions(date DESC) WHERE deleted_at IS NULL',
    'CREATE INDEX idx_tx_wallet ON transactions(wallet_id, date DESC) WHERE deleted_at IS NULL',
    'CREATE INDEX idx_tx_category ON transactions(category, date) WHERE deleted_at IS NULL',
    'CREATE INDEX idx_tx_transfer_group ON transactions(transfer_group_id)',
    'CREATE INDEX idx_tx_debt_entry ON transactions(debt_entry_id)',
    'CREATE INDEX idx_debt_entries_debt ON debt_entries(debt_id) WHERE deleted_at IS NULL',
    'CREATE INDEX idx_suggestions_lookup ON suggestions(type, kind, last_used_at DESC)',
  ];

  /// Data awal saat aplikasi baru dipasang.
  Future<void> _seedFirstRun() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // SPEC G-8: harus selalu ada tepat satu rekening default, dan rekening itu
    // tidak boleh dihapus.
    await into(wallets).insert(
      WalletsCompanion.insert(
        id: const Uuid().v4(),
        name: 'Uang Tunai',
        type: 'cash',
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await into(schemaMigrations).insert(
      SchemaMigrationsCompanion.insert(
        version: currentSchemaVersion,
        appliedAt: now,
      ),
    );
  }

  /// Rekening beserta saldonya, dihitung dari rumus SPEC §4.
  ///
  /// Karena seluruh pergerakan uang ada di satu tabel dan nominalnya bertanda,
  /// ini cukup satu penjumlahan — tanpa `CASE WHEN`, tanpa penggabungan empat
  /// tabel. Lihat DATA-MODEL D2 dan D3.
  ///
  /// Urutannya mengikuti frekuensi pemakaian (SPEC R-3): rekening yang paling
  /// sering dipakai berada di atas. `sort_order` hanya pemecah seri.
  Stream<List<WalletBalance>> watchWalletBalances() {
    return customSelect(
      '''
      SELECT w.id AS id,
             w.name AS name,
             w.type AS type,
             w.icon AS icon,
             w.color AS color,
             w.is_default AS is_default,
             w.opening_balance AS opening_balance,
             w.opening_balance + COALESCE(SUM(t.amount), 0) AS balance
      FROM wallets w
      LEFT JOIN transactions t
             ON t.wallet_id = w.id
            AND t.deleted_at IS NULL
      WHERE w.deleted_at IS NULL
      GROUP BY w.id
      ORDER BY w.use_count DESC, w.sort_order ASC, w.name ASC
      ''',
      readsFrom: {wallets, transactions},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => WalletBalance(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              type: WalletType.fromStorage(row.read<String>('type')),
              iconKey: row.read<String?>('icon'),
              color: row.read<int?>('color'),
              // Dibaca sebagai bilangan bulat, bukan bool: nilainya tersimpan
              // sebagai 0/1 di SQLite dan query ini mentah.
              isDefault: row.read<int>('is_default') != 0,
              openingBalance: row.read<int>('opening_balance'),
              balance: row.read<int>('balance'),
            ),
          )
          .toList(growable: false),
    );
  }
}
