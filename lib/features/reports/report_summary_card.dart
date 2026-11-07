import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../domain/report_summary.dart';
import '../transactions/tx_visuals.dart';

/// Kartu ringkasan rekap: **lima baris berurutan**.
///
/// SPEC L-1: Pengeluaran, Pemasukan (bertanda `+`, hijau), Selisih,
/// Hutang Piutang, Koreksi Saldo. Dua baris terakhir adalah koreksi dokumentasi
/// terbaru — SPEC L-1b.
///
/// [showBalances] menambahkan Saldo Awal, Saldo Akhir, dan Sisa Saldo. Ketiganya
/// tidak muncul di kartu bulanan Sepran (SPEC L-1c), tetapi dipakai tab
/// Realtime.
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({
    super.key,
    required this.summary,
    required this.money,
    this.showBalances = false,
    this.title,
    this.onTap,
  });

  final ReportSummary summary;
  final MoneyFormat money;
  final bool showBalances;

  /// Judul opsional di dalam kartu, dipakai daftar bulanan (SPEC L-13).
  final String? title;

  /// Membuka rincian saat kartu ditekan.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heading = title;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              if (heading != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      heading,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
              if (showBalances) ...[
                _Row(
                  label: 'Saldo Awal',
                  value: money.rupiah(summary.openingBalance),
                ),
                _Row(
                  label: 'Saldo Akhir',
                  value: money.rupiah(summary.closingBalance),
                ),
                _Row(
                  label: 'Sisa Saldo',
                  value: signedRupiah(money, summary.netMovement),
                  // Negatif tidak dimerahi; tanda minusnya yang berbicara.
                  color: summary.netMovement < 0 ? null : txSummaryIncomeColor,
                ),
                const Divider(height: 17),
              ],
              // Sepran menampilkan Pengeluaran tanpa tanda, sementara Pemasukan
              // diberi tanda `+`. Kita mengikuti keduanya apa adanya.
              _Row(label: 'Pengeluaran', value: money.rupiah(summary.expense)),
              _Row(
                label: 'Pemasukan',
                value: '+${money.rupiah(summary.income)}',
                color: txSummaryIncomeColor,
              ),
              _Row(
                label: 'Selisih',
                value: signedRupiah(money, summary.difference),
              ),
              _Row(
                label: 'Hutang Piutang',
                value: signedRupiah(money, summary.debt),
              ),
              _Row(
                label: 'Koreksi Saldo',
                value: signedRupiah(money, summary.correction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nominal bertanda dengan awalan `Rp`, untuk baris rekap.
String signedRupiah(MoneyFormat money, int value) {
  final text = money.rupiah(value.abs());
  return value < 0 ? '-$text' : '+$text';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
