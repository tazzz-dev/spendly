import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/wallet_balance.dart';
import '../../domain/wallet_rules.dart';
import '../../domain/wallet_type.dart';
import '../wallets/wallet_visuals.dart';
import 'sepran_json_import.dart';
import 'sepran_json_importer.dart';

/// Layar **Impor JSON Sepran**: membaca berkas JSON hasil ekspor dari HP,
/// lengkap dengan saldo akhir tiap rekening.
///
/// Berbeda dari impor Excel, berkas ini membawa `wallet_balances`. Saldo itu
/// dipakai untuk menghitung saldo awal, sehingga saldo akhir di aplikasi ini
/// langsung sama dengan angka di HP tanpa perlu koreksi manual.
class SepranJsonImportScreen extends ConsumerStatefulWidget {
  const SepranJsonImportScreen({super.key});

  @override
  ConsumerState<SepranJsonImportScreen> createState() =>
      _SepranJsonImportScreenState();
}

class _SepranJsonImportScreenState
    extends ConsumerState<SepranJsonImportScreen> {
  static const SepranJsonParser _parser = SepranJsonParser();

  /// Nilai dropdown untuk "buat rekening baru".
  static const String _createNew = '__new__';

  SepranJsonPreview? _preview;
  String? _fileName;
  String? _error;
  bool _busy = false;

  /// Pilihan pengguna per nama rekening: id rekening lama atau [_createNew].
  /// Nama yang tidak ada di sini memakai pilihan bawaan.
  final Map<String, String> _choices = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletBalancesProvider);
    final wallets = walletState.value ?? const <WalletBalance>[];
    final preview = _preview;
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impor JSON Sepran')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Berkas JSON dari HP Sepran memuat transaksi sekaligus saldo akhir '
            'tiap rekening. Saldo awal dihitung dari selisihnya, jadi saldo di '
            'sini langsung cocok dengan HP.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _pickFile,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Pilih berkas JSON (.json)'),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 10),
            Text('Berkas: $_fileName', style: theme.textTheme.bodySmall),
          ],
          if (walletState.hasError && _error == null) ...[
            const SizedBox(height: 10),
            Text(
              'Gagal membaca daftar rekening: ${walletState.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
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
            _Summary(preview: preview, money: money),
            const SizedBox(height: 20),
            Text('Rekening', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Pilih rekening yang sudah ada, atau buat baru dengan saldo awal '
              'hasil hitung. Saldo awal rekening lama tidak diubah.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final summary in preview.wallets)
              _WalletCard(
                summary: summary,
                wallets: wallets,
                money: money,
                choice: _choiceFor(summary.name, wallets),
                createNewValue: _createNew,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _choices[summary.name] = value);
                },
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy || preview.rows.isEmpty
                  ? null
                  : () => _import(preview, wallets),
              child: Text('Impor ${preview.rows.length} transaksi'),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ],
      ),
    );
  }

  /// Id rekening lama yang dipakai untuk [name], atau [_createNew].
  String _choiceFor(String name, List<WalletBalance> wallets) {
    final chosen = _choices[name];
    if (chosen != null) {
      if (chosen == _createNew ||
          wallets.any((wallet) => wallet.id == chosen)) {
        return chosen;
      }
    }

    final existing = _findWalletByName(wallets, name);
    return existing?.id ?? _createNew;
  }

  WalletBalance? _findWalletByName(List<WalletBalance> wallets, String name) {
    for (final wallet in wallets) {
      if (WalletName.isSame(wallet.name, name)) return wallet;
    }
    return null;
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) {
        setState(() => _busy = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('Berkas kosong.');
      }

      var text = utf8.decode(bytes);
      // Sebagian editor menuliskan BOM di awal berkas.
      if (text.startsWith('\uFEFF')) text = text.substring(1);

      final preview = _parser.parse(text);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _fileName = file.name;
        _choices.clear();
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

  Future<void> _import(
    SepranJsonPreview preview,
    List<WalletBalance> wallets,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final importer = SepranJsonImporter(
      db: ref.read(appDatabaseProvider),
      wallets: ref.read(walletRepositoryProvider),
      transactions: ref.read(transactionRepositoryProvider),
    );

    final existing = <String, String>{};
    final created = <SepranNewWallet>[];

    for (var index = 0; index < preview.wallets.length; index++) {
      final summary = preview.wallets[index];
      final choice = _choiceFor(summary.name, wallets);

      if (choice != _createNew) {
        existing[summary.name] = choice;
        continue;
      }

      final type = _guessType(summary.name);
      created.add(
        SepranNewWallet(
          name: summary.name,
          openingBalance: summary.openingBalance ?? 0,
          type: type,
          iconKey: defaultIconKey(type),
          color: walletColorChoices[index % walletColorChoices.length],
        ),
      );
    }

    setState(() => _busy = true);
    try {
      final result = await importer.import(
        preview: preview,
        existingWalletIds: existing,
        newWallets: created,
      );

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.transactionCount} transaksi diimpor'
            '${result.newWalletCount > 0 ? ' · ${result.newWalletCount} rekening baru' : ''}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengimpor: $error')),
      );
    }
  }

  /// Tebakan jenis rekening dari namanya. Hanya untuk nilai awal yang wajar;
  /// pengguna tetap bisa menyunting rekening sesudah impor.
  WalletType _guessType(String name) {
    final lower = name.toLowerCase();

    const wallets = ['gopay', 'ovo', 'dana', 'shopeepay', 'linkaja', 'doku'];
    if (wallets.any(lower.contains)) return WalletType.ewallet;

    const banks = [
      'bca',
      'bri',
      'bni',
      'mandiri',
      'blu',
      'cimb',
      'permata',
      'jago',
      'seabank',
      'bank',
      'rekening',
      'tabungan',
    ];
    if (banks.any(lower.contains)) return WalletType.bank;

    const cash = ['tunai', 'cash', 'dompet'];
    if (cash.any(lower.contains)) return WalletType.cash;

    return WalletType.other;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.preview, required this.money});

  final SepranJsonPreview preview;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = preview.firstDate;
    final last = preview.lastDate;
    final range = first == null || last == null
        ? 'Tidak ada transaksi'
        : first == last
        ? AppDate.readable(first)
        : '${AppDate.readable(first)} – ${AppDate.readable(last)}';

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
            Text(range, style: theme.textTheme.bodySmall),
            if (preview.skipped > 0 || preview.skippedBalances > 0) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (preview.skipped > 0)
                    '${preview.skipped} baris transaksi dilewati',
                  if (preview.skippedBalances > 0)
                    '${preview.skippedBalances} saldo dilewati',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const Divider(height: 20),
            _TotalRow(
              label: 'Pemasukan',
              value: '+${money.plain(preview.income)}',
            ),
            _TotalRow(
              label: 'Pengeluaran',
              value: '-${money.plain(preview.expense)}',
            ),
            _TotalRow(
              label: 'Pindah saldo',
              value: '${preview.transferCount} transaksi',
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.summary,
    required this.wallets,
    required this.money,
    required this.choice,
    required this.createNewValue,
    required this.onChanged,
  });

  final SepranJsonWalletSummary summary;
  final List<WalletBalance> wallets;
  final MoneyFormat money;
  final String choice;
  final String createNewValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creating = choice == createNewValue;
    final opening = summary.openingBalance ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${summary.transactionCount} transaksi',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TotalRow(
              label: 'Saldo akhir di berkas',
              value: summary.hasTarget
                  ? money.plain(summary.targetBalance!)
                  : '—',
            ),
            _TotalRow(
              label: 'Saldo awal hasil hitung',
              value: summary.hasTarget ? money.plain(opening) : '0',
            ),
            if (!summary.hasTarget)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Rekening ini tidak punya saldo di berkas. Saldo awal '
                  'dibuat 0 dan saldo akhirnya mengikuti transaksi.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Jadikan', style: theme.textTheme.bodyMedium),
                ),
                DropdownButton<String>(
                  value: choice,
                  onChanged: onChanged,
                  items: [
                    DropdownMenuItem(
                      value: createNewValue,
                      child: Text(
                        summary.hasTarget
                            ? 'Rekening baru (${money.plain(opening)})'
                            : 'Rekening baru',
                      ),
                    ),
                    for (final wallet in wallets)
                      DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                  ],
                ),
              ],
            ),
            if (!creating)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Saldo awal rekening ini tidak diubah.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
