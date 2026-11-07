import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/movement.dart';
import '../../domain/wallet_balance.dart';
import 'sepran_import.dart';

/// Layar **Impor dari Sepran**: memilih berkas Excel hasil ekspor Sepran, lalu
/// menyalin isinya menjadi transaksi di aplikasi ini.
///
/// Ini **salinan**, bukan tautan: sesudah diimpor, kedua aplikasi berdiri
/// sendiri. Mengubah transaksi di sini tidak mengubah apa pun di Sepran.
class SepranImportScreen extends ConsumerStatefulWidget {
  const SepranImportScreen({super.key});

  @override
  ConsumerState<SepranImportScreen> createState() => _SepranImportScreenState();
}

class _SepranImportScreenState extends ConsumerState<SepranImportScreen> {
  static const SepranWorkbookParser _parser = SepranWorkbookParser();

  ImportPreview? _preview;
  String? _fileName;
  String? _error;
  bool _busy = false;

  /// Nama rekening di berkas → id rekening di aplikasi ini.
  final Map<String, String> _walletMapping = {};
  String? _defaultWalletId;

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impor dari Sepran')),
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca rekening: $error'),
          ),
        ),
        data: (list) => _buildBody(context, list),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<WalletBalance> wallets) {
    final theme = Theme.of(context);
    final preview = _preview;

    if (wallets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Buat satu rekening dulu sebelum mengimpor.'),
        ),
      );
    }

    _defaultWalletId ??= wallets.first.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Berkas Excel hasil ekspor Sepran dibaca di sini, lalu isinya disalin '
          'menjadi transaksi. Data di Sepran tidak berubah, dan data di sini '
          'tidak terhubung ke sana.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('Pilih berkas Excel (.xlsx)'),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: 10),
          Text('Berkas: $_fileName', style: theme.textTheme.bodySmall),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 20),
          _Summary(preview: preview),
          const SizedBox(height: 20),
          Text('Rekening tujuan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._walletFields(context, wallets, preview),
          const SizedBox(height: 20),
          Text('Contoh baris', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._sampleRows(context, preview),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || preview.rows.isEmpty
                ? null
                : () => _import(wallets),
            child: Text('Impor ${preview.rows.length} transaksi'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  List<Widget> _walletFields(
    BuildContext context,
    List<WalletBalance> wallets,
    ImportPreview preview,
  ) {
    final names = preview.walletNames;

    if (names.isEmpty) {
      return [
        _WalletPicker(
          label: 'Semua baris masuk ke',
          value: _defaultWalletId,
          wallets: wallets,
          onChanged: (value) => setState(() => _defaultWalletId = value),
        ),
      ];
    }

    return [
      for (final name in names)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _WalletPicker(
            label: name,
            value: _walletMapping[name] ?? _defaultWalletId,
            wallets: wallets,
            onChanged: (value) => setState(() {
              if (value != null) _walletMapping[name] = value;
            }),
          ),
        ),
    ];
  }

  List<Widget> _sampleRows(BuildContext context, ImportPreview preview) {
    final money = ref.watch(moneyFormatProvider);
    final theme = Theme.of(context);
    final sample = preview.rows.take(10);

    return [
      for (final row in sample)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  [
                    AppDate.readable(row.date),
                    if ((row.category ?? '').isNotEmpty) row.category,
                    if ((row.title ?? '').isNotEmpty) row.title,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${row.amount < 0 ? '-' : '+'}${money.plain(row.amount.abs())}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      if (preview.rows.length > 10)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '... dan ${preview.rows.length - 10} baris lain',
            style: theme.textTheme.bodySmall,
          ),
        ),
    ];
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (file == null) {
        setState(() => _busy = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('Berkas kosong.');
      }

      final preview = _parser.parse(bytes);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _fileName = file.name;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _preview = null;
        _busy = false;
      });
    }
  }

  Future<void> _import(List<WalletBalance> wallets) async {
    final preview = _preview;
    if (preview == null) return;

    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final fallback = _defaultWalletId ?? wallets.first.id;

    setState(() => _busy = true);
    try {
      final drafts = <TxDraft>[];
      for (final row in preview.rows) {
        final walletId = _walletMapping[row.walletName ?? ''] ?? fallback;
        final title = row.title ?? '';
        final category = row.category ?? '';

        drafts.add(
          row.amount > 0
              ? Movement.income(
                  amount: row.amount,
                  walletId: walletId,
                  title: title,
                  category: category,
                  date: row.date,
                  note: row.note,
                )
              : Movement.expense(
                  amount: -row.amount,
                  walletId: walletId,
                  title: title,
                  category: category,
                  date: row.date,
                  note: row.note,
                ),
        );
      }

      final count = await repository.createMany(drafts);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('$count transaksi diimpor dari Sepran')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengimpor: $error')),
      );
    }
  }
}

/// Kotak ringkasan hasil pembacaan berkas.
class _Summary extends StatelessWidget {
  const _Summary({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = MoneyFormat(showDecimals: true);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${preview.rows.length} transaksi terbaca',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Lembar "${preview.sheetName}"'
              '${preview.skipped > 0 ? ' · ${preview.skipped} baris dilewati' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 20),
            _TotalRow(
              label: 'Pemasukan',
              value: '+${money.plain(preview.income)}',
            ),
            _TotalRow(
              label: 'Pengeluaran',
              value: '-${money.plain(preview.expense)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Satu pemetaan: nama rekening di berkas → rekening di aplikasi ini.
class _WalletPicker extends StatelessWidget {
  const _WalletPicker({
    required this.label,
    required this.value,
    required this.wallets,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<WalletBalance> wallets;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = wallets.any((wallet) => wallet.id == value)
        ? value
        : wallets.first.id;

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: selected,
          onChanged: onChanged,
          items: [
            for (final wallet in wallets)
              DropdownMenuItem(value: wallet.id, child: Text(wallet.name)),
          ],
        ),
      ],
    );
  }
}
