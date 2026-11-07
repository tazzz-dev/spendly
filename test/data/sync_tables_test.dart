import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/sync/sync_config.dart';
import 'package:pencatatan_keuangan/data/sync/sync_tables.dart';

/// Uji kesesuaian daftar tabel sinkronisasi dengan skema SQLite sungguhan, dan
/// uji aturan "versi terbaru menang" pada SQL yang dipakai [SyncService].
///
/// Tidak ada jaringan di sini: klien Supabase tidak dibutuhkan untuk memastikan
/// kolom dan penggabungan lokal benar.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('daftar tabel sinkronisasi', () {
    test('setiap kolom ada di skema SQLite', () async {
      for (final table in syncTables) {
        final rows = await db
            .customSelect('PRAGMA table_info(${table.name})')
            .get();
        final actual = {for (final row in rows) row.read<String>('name')};

        expect(
          table.columns.toSet(),
          actual,
          reason:
              'Kolom ${table.name} tidak sama dengan skema drift. '
              'Perbarui sync_tables.dart saat skema berubah.',
        );
      }
    });

    test('kolom wajib sinkronisasi tersedia di setiap tabel', () {
      for (final table in syncTables) {
        expect(table.columns, contains('id'), reason: table.name);
        expect(table.columns, contains('updated_at'), reason: table.name);
      }
    });

    test('setelan perangkat dan draft notifikasi tidak ikut tersinkron', () {
      final names = syncTables.map((table) => table.name).toSet();

      // Tema, bahasa, dan pengingat adalah pilihan perangkat.
      expect(names, isNot(contains('app_settings')));
      // Notifikasi hanya masuk ke ponsel yang menerimanya; transaksi hasil
      // konfirmasinya sudah ikut lewat tabel `transactions`.
      expect(names, isNot(contains('notification_drafts')));
      expect(names, isNot(contains('account_notification_mappings')));
    });
  });

  group('penggabungan last write wins', () {
    test('baris baru disisipkan', () async {
      await _applyWallet(db, name: 'Dompet A', updatedAt: 100);

      final row = await db
          .customSelect("SELECT name FROM wallets WHERE id = 'w1'")
          .getSingle();
      expect(row.read<String>('name'), 'Dompet A');
    });

    test('versi cloud yang lebih lama tidak menimpa versi lokal', () async {
      await _applyWallet(db, name: 'Versi lokal', updatedAt: 200);
      await _applyWallet(db, name: 'Versi cloud lama', updatedAt: 150);

      final row = await db
          .customSelect("SELECT name, updated_at FROM wallets WHERE id = 'w1'")
          .getSingle();
      expect(row.read<String>('name'), 'Versi lokal');
      expect(row.read<int>('updated_at'), 200);
    });

    test('versi cloud yang lebih baru menimpa versi lokal', () async {
      await _applyWallet(db, name: 'Versi lokal', updatedAt: 200);
      await _applyWallet(db, name: 'Versi cloud baru', updatedAt: 300);

      final row = await db
          .customSelect("SELECT name, updated_at FROM wallets WHERE id = 'w1'")
          .getSingle();
      expect(row.read<String>('name'), 'Versi cloud baru');
      expect(row.read<int>('updated_at'), 300);
    });

    test('waktu yang sama tidak menimpa apa pun', () async {
      await _applyWallet(db, name: 'Sama', updatedAt: 200);
      await _applyWallet(db, name: 'Sama juga', updatedAt: 200);

      final row = await db
          .customSelect("SELECT name FROM wallets WHERE id = 'w1'")
          .getSingle();
      expect(row.read<String>('name'), 'Sama');
    });
  });

  group('konfigurasi', () {
    test('build tanpa dart-define dianggap belum dikonfigurasi', () {
      expect(SyncConfig.isConfigured, isFalse);
    });

    test('tautan balik memakai skema kustom di Android/iOS', () {
      expect(
        SyncConfig.redirectUrl,
        '${SyncConfig.callbackScheme}://${SyncConfig.callbackHostPath}',
      );
    });
  });
}

/// Menjalankan SQL yang sama dengan [SyncService] untuk satu baris rekening.
Future<void> _applyWallet(
  AppDatabase db, {
  required String name,
  required int updatedAt,
}) async {
  final table = syncTables.firstWhere((table) => table.name == 'wallets');
  await db.customStatement(syncUpsertSql(table), [
    'w1',
    name,
    'cash',
    0,
    'IDR',
    null,
    null,
    1,
    0,
    0,
    null,
    null,
    10,
    updatedAt,
  ]);
}
