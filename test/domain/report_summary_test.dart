import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/daily_totals.dart';
import 'package:pencatatan_keuangan/domain/report_range.dart';
import 'package:pencatatan_keuangan/domain/report_summary.dart';

void main() {
  const october = ReportRange(start: '2026-10-01', end: '2026-10-31');

  group('ReportSummary.of — lima baris kartu', () {
    test('rentang kosong menghasilkan nol, tanpa membagi dengan hari', () {
      final summary = ReportSummary.of(
        days: const [],
        range: october,
        walletOpeningBalance: 100000,
        accumulateBalance: false,
      );

      expect(summary.income, 0);
      expect(summary.expense, 0);
      expect(summary.debt, 0);
      expect(summary.correction, 0);
      expect(summary.difference, 0);
      expect(summary.averageExpensePerDay, 0);
      expect(summary.openingBalance, 100000);
      expect(summary.closingBalance, 100000);
    });

    test('menjumlahkan pemasukan, pengeluaran, koreksi, dan hutang', () {
      final summary = ReportSummary.of(
        days: const [
          DailyTotals(
            date: '2026-10-05',
            income: 500000,
            expense: 120000,
            correction: 5000,
            debt: -50000,
          ),
          DailyTotals(date: '2026-10-06', expense: 30000),
        ],
        range: october,
        walletOpeningBalance: 0,
        accumulateBalance: false,
      );

      expect(summary.income, 500000);
      expect(summary.expense, 150000);
      expect(summary.correction, 5000);
      expect(summary.debt, -50000);
      expect(summary.difference, 350000);
      expect(summary.netMovement, 500000 - 150000 + 5000 - 50000);
    });

    test('hari di luar rentang tidak ikut dijumlahkan', () {
      final summary = ReportSummary.of(
        days: const [
          DailyTotals(date: '2026-09-30', income: 999, expense: 999),
          DailyTotals(date: '2026-10-15', income: 10000),
          DailyTotals(date: '2026-11-01', income: 777),
        ],
        range: october,
        walletOpeningBalance: 0,
        accumulateBalance: false,
      );

      expect(summary.income, 10000);
      expect(summary.expense, 0);
    });
  });

  group('Saldo Awal dan Saldo Akhir (SPEC L-9)', () {
    test('tanpa akumulasi, Saldo Awal hanya saldo awal rekening', () {
      final summary = ReportSummary.of(
        days: const [DailyTotals(date: '2026-09-01', income: 5000000)],
        range: october,
        walletOpeningBalance: 200000,
        accumulateBalance: false,
      );

      expect(summary.openingBalance, 200000);
      // Pergerakan September tidak ikut menggeser Saldo Awal.
      expect(summary.closingBalance, 200000);
    });

    test('dengan akumulasi, Saldo Awal ikut pergerakan sebelum rentang', () {
      final summary = ReportSummary.of(
        days: const [
          DailyTotals(date: '2026-09-01', income: 5000000, expense: 1000000),
          DailyTotals(date: '2026-10-10', expense: 250000),
        ],
        range: october,
        walletOpeningBalance: 200000,
        accumulateBalance: true,
      );

      expect(summary.openingBalance, 200000 + 4000000);
      expect(summary.closingBalance, 200000 + 4000000 - 250000);
    });

    test('Sisa Saldo adalah perubahan selama rentang, tanpa saldo awal', () {
      final summary = ReportSummary.of(
        days: const [
          DailyTotals(date: '2026-10-10', income: 300000, expense: 100000),
        ],
        range: october,
        walletOpeningBalance: 900000,
        accumulateBalance: false,
      );

      expect(summary.openingBalance, 900000);
      expect(summary.netMovement, 200000);
      expect(summary.closingBalance, 1100000);
    });
  });

  group('rata-rata per hari (SPEC L-5)', () {
    test('dibagi panjang rentang, bukan jumlah hari berisi data', () {
      final summary = ReportSummary.of(
        days: const [DailyTotals(date: '2026-10-05', expense: 310000)],
        range: october,
        walletOpeningBalance: 0,
        accumulateBalance: false,
      );

      // 31 hari di Oktober.
      expect(summary.dayCount, 31);
      expect(summary.averageExpensePerDay, (310000 / 31).round());
    });
  });
}
