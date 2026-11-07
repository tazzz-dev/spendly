import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/asset_trend.dart';
import 'package:pencatatan_keuangan/domain/daily_totals.dart';

void main() {
  group('AssetTrend (SPEC L-6)', () {
    test('akumulasi mutasi berjalan dari nol', () {
      final points = AssetTrend.build(const [
        DailyTotals(date: '2026-10-01', income: 100000),
        DailyTotals(date: '2026-10-02', expense: 40000),
        DailyTotals(date: '2026-10-03', income: 25000, correction: -5000),
      ]);

      expect(points.map((point) => point.balance).toList(), [
        100000,
        60000,
        80000,
      ]);
    });

    test('urut menurut tanggal walau masukan tidak urut', () {
      final points = AssetTrend.build(const [
        DailyTotals(date: '2026-10-03', income: 1000),
        DailyTotals(date: '2026-10-01', income: 5000),
        DailyTotals(date: '2026-10-02', income: 2000),
      ]);

      expect(points.map((point) => point.date).toList(), [
        '2026-10-01',
        '2026-10-02',
        '2026-10-03',
      ]);
      expect(points.last.balance, 8000);
    });

    test('pindah saldo tidak menggeser tren karena nettonya nol', () {
      // Transfer tidak punya kolom di DailyTotals; memastikan ia memang tidak
      // ikut terhitung lewat nilai movement.
      const day = DailyTotals(
        date: '2026-10-01',
        income: 50000,
        expense: 20000,
      );
      expect(day.movement, 30000);
    });

    test('hutang bertanda ikut menggeser akumulasi', () {
      final points = AssetTrend.build(const [
        DailyTotals(date: '2026-10-01', debt: -100000),
        DailyTotals(date: '2026-10-05', debt: 40000),
      ]);

      expect(points.last.balance, -60000);
    });

    test('tanpa data tidak ada titik', () {
      expect(AssetTrend.build(const []), isEmpty);
    });
  });
}
