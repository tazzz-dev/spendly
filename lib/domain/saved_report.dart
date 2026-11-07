import 'report_range.dart';

/// Satu rekap kustom yang disimpan pengguna. SPEC L-8.
///
/// Memetakan tabel `custom_reports` (nama asli Sepran: `laporan_data_harian`).
/// Namanya sengaja bukan `CustomReport` supaya tidak bentrok dengan kelas baris
/// yang dibangkitkan drift untuk tabel `custom_reports`.
class SavedReport {
  const SavedReport({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String name;
  final String startDate;
  final String endDate;

  /// Rentang tanggal rekap ini.
  ReportRange get range => ReportRange.custom(start: startDate, end: endDate);

  bool get isValid => endDate.compareTo(startDate) >= 0;

  @override
  String toString() => 'SavedReport($name, $startDate..$endDate)';
}
