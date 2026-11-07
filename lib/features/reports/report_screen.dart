import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/daily_totals.dart';
import '../../domain/report_range.dart';
import '../../domain/report_rules.dart';
import '../../domain/report_summary.dart';
import '../../domain/saved_report.dart';
import '../notifications/notification_inbox_button.dart';
import '../settings/settings_button.dart';
import 'asset_trend_screen.dart';
import 'custom_report_form_screen.dart';
import 'report_config_screen.dart';
import 'report_detail_screen.dart';
import 'report_summary_card.dart';

/// Halaman Rekap: tiga tab — Realtime, Bulanan, Custom. SPEC §5.8 dan L-14.
///
/// Layar ini membawa bilah judulnya sendiri, karena ikon gerigi (SPEC L-14)
/// harus berada di baris aksi bilah itu. Kerangka lima tab karena itu tidak
/// lagi menggambar bilah judul untuk tab ini.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: const SettingsButton(),
          title: const Text('Rekap'),
          actions: [
            const NotificationInboxButton(),
            IconButton(
              // Ikon tune, bukan gerigi: gerigi kiri atas sudah menjadi
              // pengaturan aplikasi. Yang ini khusus Konfigurasi Rekap.
              icon: const Icon(Icons.tune_outlined),
              tooltip: 'Konfigurasi Rekap',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const ReportConfigScreen()),
              ),
            ),
          ],
        ),
        body: const Column(
          children: [
            _ReportTabs(),
            Expanded(
              child: TabBarView(
                children: [_RealtimeTab(), _MonthlyTab(), _CustomTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pemilih **Realtime / Bulanan / Custom**.
///
/// Sepran menaruhnya **di bawah** bilah biru, bukan di dalamnya: bingkai biru
/// tipis di atas latar halaman, pilihan aktif terisi biru penuh dengan teks
/// putih. Kalau ditaruh di dalam bilah (seperti `TabBar` bawaan), pilihan aktif
/// menjadi biru di atas biru dan tulisannya lenyap. SPEC L-14.
class _ReportTabs extends StatelessWidget {
  const _ReportTabs();

  static const List<String> _labels = ['Realtime', 'Bulanan', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Container(
        height: 42,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border.all(color: primary),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var index = 0; index < _labels.length; index++) ...[
              if (index > 0)
                VerticalDivider(width: 1, thickness: 1, color: primary),
              Expanded(
                child: Material(
                  color: controller.index == index
                      ? primary
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.animateTo(index),
                    child: Center(
                      child: Text(
                        _labels[index],
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: controller.index == index
                              ? Colors.white
                              : primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Jumlah saldo awal seluruh rekening. Ini titik tolak Saldo Awal rekap.
int _walletOpeningTotal(WidgetRef ref) {
  final wallets = ref.watch(walletBalancesProvider).value ?? const [];
  return wallets.fold<int>(0, (sum, wallet) => sum + wallet.openingBalance);
}

ReportSummary _summaryFor(
  WidgetRef ref,
  ReportRange range,
  Iterable<DailyTotals> days,
) {
  final config = ref.watch(reportConfigProvider).value ?? const ReportConfig();
  return ReportSummary.of(
    days: days,
    range: range,
    walletOpeningBalance: _walletOpeningTotal(ref),
    accumulateBalance: config.accumulateBalance,
  );
}

/// Tab **Realtime**: siklus yang sedang berjalan, lengkap dengan tiga saldo.
///
/// SPEC L-1c menandai isi tab ini sebagai `[?]` — Sepran belum pernah terekam.
/// Susunan kita: kartu lima baris ditambah Saldo Awal, Saldo Akhir, dan Sisa
/// Saldo, karena kata "Realtime" paling masuk akal berarti "posisi sekarang".
class _RealtimeTab extends ConsumerWidget {
  const _RealtimeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dailyTotalsProvider);
    final money = MoneyFormat(showDecimals: true);

    return totals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorText(error),
      data: (days) {
        final config =
            ref.watch(reportConfigProvider).value ?? const ReportConfig();
        final range = ReportRange.cycleOf(AppDate.today(), config.startDay);
        final summary = _summaryFor(ref, range, days);

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                range.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ReportSummaryCard(
              summary: summary,
              money: money,
              showBalances: true,
            ),
            _AverageCard(summary: summary, money: money),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDetail(context, range, range.label),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text('Rincian'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openAssetTrend(context),
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Tren Aset'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

/// Tab **Bulanan**: daftar kartu per bulan dalam satu gulir. SPEC L-13.
class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dailyTotalsProvider);
    final money = MoneyFormat(showDecimals: true);

    return totals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorText(error),
      data: (days) {
        final config =
            ref.watch(reportConfigProvider).value ?? const ReportConfig();
        final today = AppDate.today();

        // Hari paling awal yang punya catatan; kalau kosong, cukup siklus ini.
        final earliest = days.isEmpty ? today : days.first.date;
        final ranges = ReportCycles.recent(
          earliest: earliest,
          latest: today,
          startDay: config.startDay,
        );

        final cards = <Widget>[];
        for (var index = 0; index < ranges.length; index++) {
          final range = ranges[index];
          final summary = _summaryFor(ref, range, days);
          // Bulan tanpa catatan apa pun dilewati, kecuali siklus yang sedang
          // berjalan supaya pengguna tetap melihat posisi hari ini.
          final hasData =
              summary.income != 0 ||
              summary.expense != 0 ||
              summary.debt != 0 ||
              summary.correction != 0;
          if (index > 0 && !hasData) {
            continue;
          }
          cards.add(
            ReportSummaryCard(
              title: range.label,
              summary: summary,
              money: money,
              onTap: () => _openDetail(context, range, range.label),
            ),
          );
        }

        if (cards.isEmpty) {
          return const Center(child: Text('Belum ada rekap'));
        }

        return ListView(children: [...cards, const SizedBox(height: 24)]);
      },
    );
  }
}

/// Tab **Custom**: rekap kustom tersimpan. SPEC L-8.
class _CustomTab extends ConsumerWidget {
  const _CustomTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(customReportsProvider);

    return Scaffold(
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorText(error),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Belum ada rekap kustom tersimpan'),
                ),
              )
            : ListView(
                children: [
                  for (final report in list) _CustomReportTile(report: report),
                  const SizedBox(height: 88),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCustomReportForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Rekap Baru'),
        // Tema memberi seluruh FAB bentuk lingkaran (Sepran). Tombol memanjang
        // ini perlu bentuk kapsul sendiri, kalau tidak tulisannya terpotong.
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _CustomReportTile extends ConsumerWidget {
  const _CustomReportTile({required this.report});

  final SavedReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.bookmark_outline),
      title: Text(report.name),
      subtitle: Text(report.range.label),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'edit':
              await openCustomReportForm(context, initial: report);
            case 'delete':
              await _confirmDelete(context, ref, report);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Ubah')),
          PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      ),
      onTap: () => _openDetail(context, report.range, report.name),
      // Judul yang panjang dipangkas agar tata letak tidak rusak.
      titleTextStyle: theme.textTheme.titleMedium,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedReport report,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus ${report.name}?'),
        content: const Text(
          'Rekap kustom ini akan dihapus. Transaksinya tidak terpengaruh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(reportRepositoryProvider).softDeleteCustomReport(report.id);
    messenger.showSnackBar(SnackBar(content: Text('${report.name} dihapus')));
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.summary, required this.money});

  final ReportSummary summary;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rata-rata pengeluaran per hari '
              '${money.rupiah(summary.averageExpensePerDay)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text('${summary.dayCount} hari', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Gagal membaca rekap: $error'),
      ),
    );
  }
}

void _openDetail(BuildContext context, ReportRange range, String title) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ReportDetailScreen(range: range, title: title),
    ),
  );
}
