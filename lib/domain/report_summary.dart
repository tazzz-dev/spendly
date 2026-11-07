import 'daily_totals.dart';
import 'report_range.dart';

/// Ringkasan sebuah rentang rekap.
///
/// Lima baris pertama adalah susunan kartu Sepran: **Pengeluaran, Pemasukan,
/// Selisih, Hutang Piutang, Koreksi Saldo**. SPEC L-1 dan L-1b.
///
/// Saldo Awal, Saldo Akhir, dan Sisa Saldo tidak muncul di kartu bulanan
/// (SPEC L-1c) tetapi dipakai tab Realtime.
class ReportSummary {
  const ReportSummary({
    required this.income,
    required this.expense,
    required this.debt,
    required this.correction,
    required this.openingBalance,
    required this.closingBalance,
    required this.dayCount,
  });

  /// Menghitung ringkasan dari total harian.
  ///
  /// [walletOpeningBalance] adalah jumlah saldo awal seluruh rekening. Bila
  /// [accumulateBalance] menyala, Saldo Awal ditambah seluruh pergerakan
  /// **sebelum** rentang — inilah arti "Saldo Akumulasi" di SPEC L-9.
  factory ReportSummary.of({
    required Iterable<DailyTotals> days,
    required ReportRange range,
    required int walletOpeningBalance,
    required bool accumulateBalance,
  }) {
    var income = 0;
    var expense = 0;
    var debt = 0;
    var correction = 0;
    var movementInRange = 0;
    var movementBefore = 0;

    for (final day in days) {
      if (range.isBefore(day.date)) {
        movementBefore += day.movement;
      } else if (range.contains(day.date)) {
        income += day.income;
        expense += day.expense;
        debt += day.debt;
        correction += day.correction;
        movementInRange += day.movement;
      }
    }

    final opening = accumulateBalance
        ? walletOpeningBalance + movementBefore
        : walletOpeningBalance;

    return ReportSummary(
      income: income,
      expense: expense,
      debt: debt,
      correction: correction,
      openingBalance: opening,
      closingBalance: opening + movementInRange,
      dayCount: range.dayCount,
    );
  }

  /// Seluruh pemasukan rentang, ≥ 0.
  final int income;

  /// Seluruh pengeluaran rentang sebagai besar mutlak, ≥ 0.
  final int expense;

  /// Mutasi hutang piutang rentang, bertanda. SPEC L-1b.
  final int debt;

  /// Koreksi saldo rentang, bertanda. SPEC L-1b.
  final int correction;

  /// Saldo seluruh rekening di awal rentang.
  final int openingBalance;

  /// Saldo seluruh rekening di akhir rentang.
  final int closingBalance;

  /// Banyak hari kalender dalam rentang.
  final int dayCount;

  /// Pemasukan dikurangi pengeluaran.
  ///
  /// **SPEC T-17 masih terbuka**: pada satu-satunya hari yang terekam di Sepran,
  /// Selisih tertulis tanpa tanda minus meski pengeluaran lebih besar. Rumusnya
  /// dikumpulkan di satu getter ini supaya perbaikan nanti cukup satu baris.
  int get difference => income - expense;

  /// Perubahan saldo selama rentang, di luar saldo awal.
  int get netMovement => income - expense + debt + correction;

  /// Rata-rata pengeluaran per hari kalender. SPEC L-5.
  int get averageExpensePerDay =>
      dayCount <= 0 ? 0 : (expense / dayCount).round();

  /// Rata-rata pemasukan per hari kalender. SPEC L-5.
  int get averageIncomePerDay =>
      dayCount <= 0 ? 0 : (income / dayCount).round();
}
