import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/daily_totals.dart';
import '../../domain/report_breakdown.dart';
import '../../domain/report_range.dart';
import '../../domain/report_rules.dart';
import '../../domain/report_summary.dart';
import '../../domain/tx_kind.dart';
import 'report_charts.dart';
import 'report_summary_card.dart';

/// Rincian satu rekap: ringkasan, grafik, lalu empat daftar. SPEC L-2 dan L-3.
///
/// Keempat daftarnya adalah Pengeluaran per Kategori, Pengeluaran per Judul,
/// Pemasukan per Kategori, dan Pemasukan per Judul.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    required this.range,
    required this.title,
  });

  final ReportRange range;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dailyTotalsProvider);
    final lines = ref.watch(reportLinesProvider(range));
    final money = MoneyFormat(showDecimals: true);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca rekap: $error'),
          ),
        ),
        data: (days) => _Body(
          range: range,
          days: days,
          lines: lines.value ?? const [],
          money: money,
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.range,
    required this.days,
    required this.lines,
    required this.money,
  });

  final ReportRange range;
  final List<DailyTotals> days;
  final List<ReportLine> lines;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config =
        ref.watch(reportConfigProvider).value ?? const ReportConfig();
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];
    final opening = wallets.fold<int>(0, (sum, w) => sum + w.openingBalance);

    final summary = ReportSummary.of(
      days: days,
      range: range,
      walletOpeningBalance: opening,
      accumulateBalance: config.accumulateBalance,
    );

    final expenseByCategory = ReportBreakdown.build(
      lines: lines,
      kind: TxKind.expense,
    );
    final expenseByTitle = ReportBreakdown.build(
      lines: lines,
      kind: TxKind.expense,
      byTitle: true,
    );
    final incomeByCategory = ReportBreakdown.build(
      lines: lines,
      kind: TxKind.income,
    );
    final incomeByTitle = ReportBreakdown.build(
      lines: lines,
      kind: TxKind.income,
      byTitle: true,
    );

    return ListView(
      children: [
        ReportSummaryCard(summary: summary, money: money, showBalances: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Rata-rata pengeluaran per hari '
            '${money.rupiah(summary.averageExpensePerDay)} · '
            'rata-rata pemasukan per hari '
            '${money.rupiah(summary.averageIncomePerDay)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _Section(
          title: 'Pengeluaran per Kategori',
          items: expenseByCategory,
          money: money,
          showChart: true,
        ),
        _Section(
          title: 'Pemasukan per Kategori',
          items: incomeByCategory,
          money: money,
        ),
        _Section(
          title: 'Pengeluaran per Judul',
          items: expenseByTitle,
          money: money,
        ),
        _Section(
          title: 'Pemasukan per Judul',
          items: incomeByTitle,
          money: money,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.money,
    this.showChart = false,
  });

  final String title;
  final List<BreakdownItem> items;
  final MoneyFormat money;
  final bool showChart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('Belum ada data', style: theme.textTheme.bodySmall)
          else ...[
            if (showChart)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BreakdownPieChart(items: items, money: money),
              ),
            for (final item in items) _BreakdownRow(item: item, money: money),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.money});

  final BreakdownItem item;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                money.rupiah(item.amount),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
