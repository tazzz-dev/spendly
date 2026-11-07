import '../domain/report_range.dart';
import '../domain/report_rules.dart';
import 'db/app_database.dart';

/// Membaca dan menyimpan setelan rekap dari tabel `app_settings`.
///
/// Hanya dua kunci yang dikelola di sini (SPEC L-7). Setelan lain aplikasi
/// nanti memakai tabel yang sama dengan kunci masing-masing.
class ReportSettingsRepository {
  ReportSettingsRepository(this._db);

  final AppDatabase _db;

  static const List<String> _keys = [
    ReportRules.settingStartDay,
    ReportRules.settingAccumulate,
  ];

  /// Memancarkan setelan setiap kali tersimpan, sehingga seluruh layar rekap
  /// ikut berubah begitu Konfigurasi Rekap disimpan.
  Stream<ReportConfig> watch() {
    return (_db.select(
      _db.appSettings,
    )..where((row) => row.key.isIn(_keys))).watch().map(_toConfig);
  }

  Future<ReportConfig> read() async {
    final rows = await (_db.select(
      _db.appSettings,
    )..where((row) => row.key.isIn(_keys))).get();
    return _toConfig(rows);
  }

  Future<void> save(ReportConfig config) async {
    await _write(
      ReportRules.settingStartDay,
      '${clampStartDay(config.startDay)}',
    );
    await _write(
      ReportRules.settingAccumulate,
      config.accumulateBalance ? 'true' : 'false',
    );
  }

  Future<void> _write(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  ReportConfig _toConfig(List<AppSetting> rows) {
    var startDay = ReportRules.defaultStartDay;
    var accumulate = ReportRules.defaultAccumulate;

    for (final row in rows) {
      switch (row.key) {
        case ReportRules.settingStartDay:
          startDay = clampStartDay(
            int.tryParse(row.value) ?? ReportRules.defaultStartDay,
          );
        case ReportRules.settingAccumulate:
          accumulate = row.value == 'true';
      }
    }

    return ReportConfig(startDay: startDay, accumulateBalance: accumulate);
  }
}
