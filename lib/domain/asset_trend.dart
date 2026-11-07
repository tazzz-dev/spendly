import 'daily_totals.dart';

/// Satu titik pada grafik Tren Aset.
class AssetTrendPoint {
  const AssetTrendPoint({required this.date, required this.balance});

  /// Tanggal lokal `YYYY-MM-DD`.
  final String date;

  /// Saldo akumulasi sampai tanggal ini.
  final int balance;
}

/// Penyusun Tren Aset. SPEC L-6.
class AssetTrend {
  const AssetTrend._();

  /// Akumulasi mutasi dari transaksi paling awal.
  ///
  /// Ini keputusan kita di `docs/VERIFIKASI.md`: titik awal 0, lalu setiap hari
  /// ditambah `movement` hari itu. Saldo awal rekening sengaja **tidak** ikut,
  /// sehingga mengubah saldo awal tidak menggeser seluruh grafik.
  static List<AssetTrendPoint> build(Iterable<DailyTotals> days) {
    final sorted = days.toList()..sort((a, b) => a.date.compareTo(b.date));

    final points = <AssetTrendPoint>[];
    var balance = 0;
    for (final day in sorted) {
      balance += day.movement;
      points.add(AssetTrendPoint(date: day.date, balance: balance));
    }
    return points;
  }
}
