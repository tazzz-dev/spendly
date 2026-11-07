import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/app_preferences.dart';
import 'db/app_database.dart';

/// Seluruh pembacaan dan penulisan setelan lewat sini.
///
/// Lapisan ini menjaga tabel `app_settings` (kunci-nilai teks) dan tindakan
/// berbahaya atas data. Tidak ada penulisan langsung dari UI.
/// Lihat SPEC §5.12 dan DATA-MODEL.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  /// Membaca seluruh setelan. Kunci yang belum pernah ditulis memakai nilai
  /// bawaan dari [AppPreferences.fromMap].
  Future<AppPreferences> load() async {
    final rows = await _db.select(_db.appSettings).get();
    final values = {for (final row in rows) row.key: row.value};
    return AppPreferences.fromMap(values);
  }

  /// Menulis sekumpulan kunci-nilai. Nilai lama pada kunci yang sama ditimpa.
  Future<void> save(Map<String, String> values) async {
    if (values.isEmpty) return;

    for (final entry in values.entries) {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(key: entry.key, value: entry.value),
          );
    }
  }

  /// SPEC B-7: mengosongkan basis data lokal.
  ///
  /// Urutan hapus mengikuti arah kunci asing: yang dirujuk dihapus lebih
  /// dulu, karena kunci asing (SPEC R-4) akan menolak sebaliknya.
  ///
  /// Setelan (`app_settings`) tidak ikut: pilihan tema dan bahasa pengguna
  /// bukan data pencatatan, dan menghapusnya hanya membuat aplikasi terasa
  /// rusak. Catatan versi skema (`schema_migrations`) juga dipertahankan,
  /// sesuai maksudnya saat dibuat (SPEC B-10).
  Future<void> clearAllData() async {
    await _db.transaction(() async {
      for (final statement in _clearStatements) {
        await _db.customStatement(statement);
      }

      // SPEC G-8: setelah dikosongkan, harus tetap ada tepat satu rekening
      // bawaan — sama seperti pemasangan pertama.
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .into(_db.wallets)
          .insert(
            WalletsCompanion.insert(
              id: _uuid.v4(),
              name: 'Uang Tunai',
              type: 'cash',
              isDefault: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  /// Hapus lunak tidak berlaku di sini: mengosongkan berarti benar-benar
  /// mengosongkan. Lihat SPEC B-7.
  static const List<String> _clearStatements = [
    'DELETE FROM transactions',
    'DELETE FROM debt_entries',
    'DELETE FROM debts',
    'DELETE FROM budgets',
    'DELETE FROM custom_reports',
    'DELETE FROM suggestions',
    'DELETE FROM wallets',
  ];
}
