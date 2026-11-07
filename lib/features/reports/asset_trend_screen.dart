import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/asset_trend.dart';
import 'report_charts.dart';

/// Membuka halaman Tren Aset. SPEC L-6.
Future<void> openAssetTrend(BuildContext context) {
  return Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const AssetTrendScreen()));
}

/// Grafik perkembangan aset sepanjang waktu. SPEC L-6.
///
/// Yang digambar adalah **akumulasi mutasi** dari transaksi paling awal
/// (keputusan kita di `docs/VERIFIKASI.md`), bukan saldo rekening yang ikut
/// berubah bila pengguna menyunting saldo awal.
class AssetTrendScreen extends ConsumerWidget {
  const AssetTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dailyTotalsProvider);
    final money = MoneyFormat(showDecimals: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Tren Aset')),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca tren: $error'),
          ),
        ),
        data: (days) {
          final points = AssetTrend.build(days);
          if (points.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum cukup data untuk menggambar tren.'),
              ),
            );
          }

          final last = points.last.balance;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akumulasi mutasi sampai sekarang',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      money.rupiah(last),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: AssetTrendChart(points: points, money: money),
              ),
            ],
          );
        },
      ),
    );
  }
}
