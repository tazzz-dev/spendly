import 'package:intl/intl.dart';

import '../core/dates.dart';
import 'report_rules.dart';

/// Membatasi hari mulai siklus ke rentang yang sah (1–28).
///
/// Dipisah dari [ReportRange.cycleOf] supaya bisa dipakai juga oleh layar
/// pengaturan tanpa ikut membuat rentang tanggal.
int clampStartDay(int startDay) {
  if (startDay < ReportRules.minStartDay) return ReportRules.minStartDay;
  if (startDay > ReportRules.maxStartDay) return ReportRules.maxStartDay;
  return startDay;
}

/// Rentang tanggal sebuah rekap, **inklusif di kedua ujung**.
///
/// Tanggal tetap berupa teks `YYYY-MM-DD` (SPEC G-4), sehingga membandingkan
/// dan mengurutkan rentang cukup dengan perbandingan leksikografis — tidak ada
/// zona waktu yang bisa menggeser batas hari. Murni: tanpa Flutter, tanpa drift.
class ReportRange {
  const ReportRange({required this.start, required this.end});

  /// Tanggal awal, `YYYY-MM-DD`, ikut dihitung.
  final String start;

  /// Tanggal akhir, `YYYY-MM-DD`, ikut dihitung.
  final String end;

  /// Satu bulan kalender penuh. SPEC L-13.
  factory ReportRange.monthOf(String dateKey) => ReportRange(
    start: AppDate.firstDayOfMonth(dateKey),
    end: AppDate.lastDayOfMonth(dateKey),
  );

  /// Siklus rekap yang mulai pada hari [startDay] tiap bulan. SPEC L-7 dan L-7b.
  ///
  /// Nilai 1 berarti mengikuti awal bulan. Nilai 25 berarti periode berjalan
  /// dari tanggal 25 sampai tanggal 24 bulan berikutnya — berguna untuk siklus
  /// gaji. Hari dibatasi 1–28 supaya tidak ada bulan yang kehilangan siklusnya
  /// (tanggal 29, 30, 31 tidak ada di semua bulan).
  factory ReportRange.cycleOf(String dateKey, int startDay) {
    final day = clampStartDay(startDay);
    final date = AppDate.parseKey(dateKey);
    final start = date.day >= day
        ? DateTime(date.year, date.month, day)
        : DateTime(date.year, date.month - 1, day);

    // `DateTime` menormalkan nilai di luar rentang: hari ke-0 bulan berikutnya
    // berarti hari terakhir bulan ini. Jadi tanggal 25 menghasilkan akhir
    // tanggal 24 bulan berikutnya, persis seperti SPEC L-7b.
    final end = DateTime(start.year, start.month + 1, start.day - 1);

    return ReportRange(start: AppDate.key(start), end: AppDate.key(end));
  }

  /// Rentang bebas, misalnya rekap kustom yang disimpan. SPEC L-8.
  factory ReportRange.custom({required String start, required String end}) =>
      ReportRange(start: start, end: end);

  /// Apakah [dateKey] jatuh di dalam rentang ini.
  bool contains(String dateKey) =>
      dateKey.compareTo(start) >= 0 && dateKey.compareTo(end) <= 0;

  /// Apakah [dateKey] jatuh **sebelum** rentang ini.
  ///
  /// Dipakai menghitung Saldo Awal bila Saldo Akumulasi menyala (SPEC L-9).
  bool isBefore(String dateKey) => dateKey.compareTo(start) < 0;

  /// Banyak hari kalender dalam rentang, termasuk kedua ujungnya.
  int get dayCount {
    final from = AppDate.parseKey(start);
    final to = AppDate.parseKey(end);
    return to.difference(from).inDays + 1;
  }

  /// `Okt 2026` untuk siklus yang mengikuti awal bulan, selain itu
  /// `25 Sep – 24 Okt 2026`.
  String get label {
    final from = AppDate.parseKey(start);
    if (from.day == 1) return _month.format(from);
    return '${_short.format(from)} – ${_long.format(AppDate.parseKey(end))}';
  }

  static final DateFormat _month = DateFormat('MMM yyyy', 'id_ID');
  static final DateFormat _short = DateFormat('d MMM', 'id_ID');
  static final DateFormat _long = DateFormat('d MMM yyyy', 'id_ID');

  @override
  bool operator ==(Object other) =>
      other is ReportRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start..$end';
}

/// Deretan siklus rekap, dipakai tab Bulanan. SPEC L-13.
class ReportCycles {
  const ReportCycles._();

  /// Daftar siklus dari yang **paling baru** ke paling lama, mulai dari siklus
  /// yang memuat [latest] sampai siklus yang memuat [earliest].
  ///
  /// [limit] adalah pagar agar daftar tidak pernah tak berujung bila data
  /// tanggalnya rusak (misalnya tersimpan sebagai tahun 1900).
  static List<ReportRange> recent({
    required String earliest,
    required String latest,
    required int startDay,
    int limit = 240,
  }) {
    final ranges = <ReportRange>[];
    var cursor = latest;

    while (ranges.length < limit) {
      final range = ReportRange.cycleOf(cursor, startDay);
      ranges.add(range);

      // Siklus ini sudah mencakup tanggal paling awal; tidak ada yang perlu
      // dicari lagi.
      if (range.start.compareTo(earliest) <= 0) break;

      // Mundur satu hari dari awal siklus untuk mendapatkan siklus sebelumnya.
      final previous = AppDate.parseKey(range.start)
          .subtract(const Duration(days: 1));
      cursor = AppDate.key(previous);
    }

    return ranges;
  }
}
