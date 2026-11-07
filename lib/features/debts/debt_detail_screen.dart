import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/debt_entry.dart';
import '../../domain/debt_progress.dart';
import '../../domain/debt_record.dart';
import '../../domain/debt_rules.dart';
import '../../domain/debt_target_direction.dart';
import '../../domain/debt_totals.dart';
import 'debt_direction_menu.dart';
import 'debt_entry_form_screen.dart';
import 'debt_form_screen.dart';
import 'debt_providers.dart';
import 'debt_target_form_screen.dart';
import 'debt_visuals.dart';

/// Halaman detail satu catatan hutang. SPEC H-6, H-9, H-13, dan H-14.
///
/// Bilah atas: judul = Nama catatan, anak judul status, dan tiga aksi —
/// tandai lunas, edit, dan hapus. Isinya: tiga sel ringkasan berikon tanpa
/// label, daftar entri, dan tombol `+` untuk menambah entri.
class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(debtRecordProvider(debtId));
    final entries = ref.watch(debtEntriesProvider(debtId));
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, record.value),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca entri: $error'),
          ),
        ),
        data: (rows) {
          final current = record.value;
          return _DetailBody(
            entries: rows,
            record: current,
            money: money,
            onPay: current?.targetDirection == null
                ? null
                : (direction) => _payTarget(context, current!, direction),
            onEditTarget: current == null
                ? null
                : () => _editTarget(context, current),
            onClearTarget: current == null
                ? null
                : () => _clearTarget(context, ref, current),
          );
        },
      ),
      floatingActionButton: record.value == null
          ? null
          : FloatingActionButton(
              onPressed: () => _addEntry(context, ref),
              tooltip: 'Tambah entri',
              child: const Icon(Icons.add),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    DebtRecord? record,
  ) {
    if (record == null) {
      return AppBar(title: const Text('Hutang'));
    }

    final theme = Theme.of(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            record.partyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          // SPEC H-9: status hanya muncul di sini, sebagai anak judul.
          Text(record.statusLabel, style: theme.textTheme.bodySmall),
        ],
      ),
      actions: [
        // SPEC H-13: tandai lunas, edit, hapus.
        IconButton(
          icon: Icon(record.isSettled ? debtUnsettleIcon : debtSettleIcon),
          tooltip: record.isSettled ? 'Tandai belum lunas' : 'Tandai lunas',
          onPressed: () => _toggleSettled(context, ref, record),
        ),
        IconButton(
          icon: const Icon(debtEditIcon),
          tooltip: 'Edit',
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => DebtFormScreen(initial: record)),
          ),
        ),
        IconButton(
          icon: const Icon(debtDeleteIcon),
          tooltip: 'Hapus',
          onPressed: () => _confirmDelete(context, ref, record),
        ),
      ],
    );
  }

  Future<void> _toggleSettled(
    BuildContext context,
    WidgetRef ref,
    DebtRecord record,
  ) async {
    final next = !record.isSettled;
    await ref.read(debtRepositoryProvider).setSettled(record.id, next);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? 'Ditandai lunas' : 'Ditandai belum lunas')),
    );
  }

  /// Menghapus catatan **beserta seluruh entrinya**. Konfirmasinya disalin
  /// persis dari SPEC H-7.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DebtRecord record,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(DebtRules.deleteConfirmation),
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

    await ref.read(debtRepositoryProvider).deleteDebt(record.id);

    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
  }

  /// Tombol `+` halaman detail juga lebih dulu memilih arah, seperti halaman
  /// daftar (SPEC H-2).
  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final direction = await showDebtDirectionMenu(context);
    if (direction == null || !context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            DebtEntryFormScreen(debtId: debtId, direction: direction),
      ),
    );
  }

  /// H-21: pembayaran target membuka form entri dengan arah otomatis dan
  /// rekening wajib.
  Future<void> _payTarget(
    BuildContext context,
    DebtRecord record,
    DebtTargetDirection direction,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            DebtEntryFormScreen(debtId: record.id, targetDirection: direction),
      ),
    );
  }

  Future<void> _editTarget(BuildContext context, DebtRecord record) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => DebtTargetFormScreen(initial: record)),
    );
  }

  /// Mengosongkan target. Entri dan transaksi cermin tidak ikut dihapus, jadi
  /// catatan kembali menjadi catatan Normal yang apa adanya.
  Future<void> _clearTarget(
    BuildContext context,
    WidgetRef ref,
    DebtRecord record,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          'Hapus target catatan ini? Catatan dan seluruh entrinya tetap ada, '
          'tetapi tidak lagi muncul di tab Target.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus target'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(debtRepositoryProvider).clearTarget(record.id);
    messenger.showSnackBar(const SnackBar(content: Text('Target dihapus')));
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.entries,
    required this.record,
    required this.money,
    this.onPay,
    this.onEditTarget,
    this.onClearTarget,
  });

  final List<DebtEntry> entries;
  final DebtRecord? record;
  final MoneyFormat money;
  final ValueChanged<DebtTargetDirection>? onPay;
  final VoidCallback? onEditTarget;
  final VoidCallback? onClearTarget;

  @override
  Widget build(BuildContext context) {
    final summary = DebtSummary.of(entries);
    final progress = record?.progress;

    return ListView(
      children: [
        if (progress != null)
          _TargetProgressCard(
            progress: progress,
            direction: record!.targetDirection!,
            money: money,
            onPay: onPay,
            onEdit: onEditTarget,
            onClear: onClearTarget,
          )
        else if (record != null)
          _MakeTargetButton(onPressed: onEditTarget),
        _SummaryRow(summary: summary, money: money),
        const Divider(height: 1),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Belum ada entri',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        for (final entry in entries) _EntryTile(entry: entry, money: money),
        // Ruang agar baris terakhir tidak tertutup tombol tambah.
        const SizedBox(height: 88),
      ],
    );
  }
}

/// Kartu progress di atas tiga sel ringkasan. USULAN-HUTANG-TARGET §6.5.
class _TargetProgressCard extends StatelessWidget {
  const _TargetProgressCard({
    required this.progress,
    required this.direction,
    required this.money,
    this.onPay,
    this.onEdit,
    this.onClear,
  });

  final DebtProgress progress;
  final DebtTargetDirection direction;
  final MoneyFormat money;
  final ValueChanged<DebtTargetDirection>? onPay;
  final VoidCallback? onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    debtTargetPaidText(money, progress),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (progress.isSettled) ...[
                  const SizedBox(width: 8),
                  const _LunasBadge(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    debtTargetStatusText(money, progress),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onPay == null ? null : () => onPay!(direction),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Bayar'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(onPressed: onEdit, child: const Text('Ubah target')),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Hapus target'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge kecil "Lunas" pada kartu target dan baris Normal.
class _LunasBadge extends StatelessWidget {
  const _LunasBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: debtSummaryReceiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        DebtRules.settledStatus,
        style: TextStyle(
          color: debtSummaryReceiveColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Ajakan mengubah catatan Normal menjadi bertarget. H-17/H-25.
class _MakeTargetButton extends StatelessWidget {
  const _MakeTargetButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: const Text('Jadikan Target'),
      ),
    );
  }
}

/// Tiga sel ringkasan **berikon tanpa label**. SPEC H-14.
///
/// Sel pertama Menerima (panah ke atas, hijau), sel kedua Memberi (panah ke
/// bawah), sel ketiga sisa (ikon bulat merah muda). Arti sel ketiga dijelaskan
/// di [DebtSummary.remaining].
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary, required this.money});

  final DebtSummary summary;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _SummaryCell(
            icon: debtSummaryReceiveIcon,
            color: debtSummaryReceiveColor,
            value: '+${money.plain(summary.receiving)}',
            theme: theme,
          ),
          _SummaryCell(
            icon: debtSummaryGiveIcon,
            color: debtSummaryGiveColor,
            value: money.plain(summary.giving),
            theme: theme,
          ),
          _SummaryCell(
            icon: debtSummaryRemainingIcon,
            color: debtSummaryRemainingColor,
            value: money.plain(summary.remaining),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu baris entri: tanggal, keterangan (atau "Tanpa keterangan"), nominal.
/// SPEC F.
class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.money});

  final DebtEntry entry;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(AppDate.readable(entry.date)),
      subtitle: Text(
        entry.noteLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        debtEntryAmountText(money, entry),
        style: theme.textTheme.titleSmall?.copyWith(
          color: debtEntryAmountColor(entry),
        ),
      ),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              DebtEntryFormScreen(debtId: entry.debtId, existing: entry),
        ),
      ),
    );
  }
}
