import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../data/providers.dart';
import 'transaction_export.dart';

/// Membuka dialog **Export Data**. SPEC X-1 dan X-2.
Future<void> showExportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const ExportDialog(),
  );
}

/// Dialog pemilih rentang tanggal dengan dua tombol: Excel dan PDF.
///
/// Di Sepran ekspor dikunci pembayaran (X-4). Di sini **gratis** (X-5): data
/// pengguna tidak boleh disandera, jadi tidak ada alur bayar sama sekali.
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({super.key});

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  late String _from;
  late String _until;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final today = AppDate.parseKey(AppDate.today());
    _from = AppDate.key(DateTime(today.year, today.month, 1));
    _until = AppDate.today();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Container(
        height: 52,
        alignment: Alignment.center,
        color: theme.colorScheme.primary,
        child: const Text(
          'Export Data',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateField(
              label: 'Dari',
              date: _from,
              onTap: () => _pickDate(from: true),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Sampai',
              date: _until,
              onTap: () => _pickDate(from: false),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '*) Ekspor gratis dan tanpa batas. Berkas berisi transaksi '
                'pada rentang ini saja.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _export(excel: true),
                    child: const Text('Export Excel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : () => _export(excel: false),
                    child: const Text('Export PDF'),
                  ),
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool from}) async {
    final current = AppDate.parseKey(from ? _from : _until);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = AppDate.key(picked);
        // Rentang terbalik tidak masuk akal; ujung lain ikut digeser.
        if (_from.compareTo(_until) > 0) _until = _from;
      } else {
        _until = AppDate.key(picked);
        if (_until.compareTo(_from) < 0) _from = _until;
      }
    });
  }

  Future<void> _export({required bool excel}) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = TransactionExportService(
      ref.read(transactionRepositoryProvider),
    );

    setState(() => _busy = true);
    try {
      final file = excel
          ? await service.writeExcel(from: _from, until: _until)
          : await service.writePdf(from: _from, until: _until);
      await service.shareFile(
        file,
        subject:
            'Transaksi ${AppDate.readable(_from)} - '
            '${AppDate.readable(_until)}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengekspor: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }
}

/// Satu baris isian tanggal di dalam dialog, dengan ikon kalender.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppDate.readable(date),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
