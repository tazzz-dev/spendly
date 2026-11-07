import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/tx_rules.dart';
import 'calculator_sheet.dart';
import 'tx_visuals.dart';
import 'wallet_picker_sheet.dart';

/// Form Pindah Saldo. SPEC §5.3.
///
/// Yang membedakannya dari form pemasukan dan pengeluaran: **tidak ada field
/// Judul dan tidak ada field Kategori** (SPEC S-9), tetapi judul halamannya
/// tetap "Tambah Transaksi" (SPEC S-10).
class TransferFormScreen extends ConsumerStatefulWidget {
  const TransferFormScreen({super.key, this.initialDate});

  /// Tanggal yang sedang dilihat di daftar.
  final String? initialDate;

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  late final TextEditingController _note;
  late final TextEditingController _adminFee;

  late String _dateKey;
  late String _time;
  String? _fromWalletId;
  String? _toWalletId;
  int? _amount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController();
    _adminFee = TextEditingController();
    _dateKey = widget.initialDate ?? AppDate.today();
    _time = AppDate.nowTime();
  }

  @override
  void dispose() {
    _note.dispose();
    _adminFee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = MoneyFormat(showDecimals: true);
    final adminFee = MoneyInput.tryParse(_adminFee.text) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Tanggal',
                  icon: Icons.calendar_today_outlined,
                  value: AppDate.readable(_dateKey),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Jam',
                  icon: Icons.schedule_outlined,
                  value: _time,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SPEC S-1: rekening asal tampil tanpa label, langsung namanya.
          _WalletLine(
            walletId: _fromWalletId,
            placeholder: 'Pilih rekening asal',
            icon: Icons.arrow_upward_rounded,
            color: txNeutralColor,
            onTap: () => _pickWallet(isSource: true),
          ),
          const SizedBox(height: 12),
          _WalletLine(
            walletId: _toWalletId,
            placeholder: 'Pilih rekening tujuan',
            label: 'Tujuan',
            icon: Icons.arrow_downward_rounded,
            color: txNeutralColor,
            onTap: () => _pickWallet(isSource: false),
          ),
          const SizedBox(height: 16),

          InkWell(
            key: const Key('transfer_amount'),
            onTap: _openCalculator,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Jumlah',
                border: const OutlineInputBorder(),
                prefixText: 'Rp ',
                suffixIcon: IconButton(
                  tooltip: 'Kalkulator',
                  icon: const Icon(Icons.calculate_outlined),
                  onPressed: _openCalculator,
                ),
              ),
              child: Text(
                _amount == null ? 'Belum diisi' : money.plain(_amount!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Biaya admin opsional. Bila diisi, nominalnya dipotong dari
          // rekening asal sebagai pengeluaran tersendiri, sehingga saldo dan
          // rekap tetap jujur menunjukkan biaya itu.
          TextField(
            key: const Key('transfer_admin_fee'),
            controller: _adminFee,
            keyboardType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Biaya admin (opsional)',
              hintText: 'Kosongkan bila tidak ada',
              prefixText: 'Rp ',
              helperText: 'Dipotong dari rekening asal',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Keterangan (tidak wajib diisi)',
              border: OutlineInputBorder(),
            ),
          ),

          if (_amount != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                adminFee > 0
                    ? 'Saldo rekening asal berkurang '
                          '${money.rupiah(_amount! + adminFee)} '
                          '(${money.rupiah(_amount!)} transfer + '
                          '${money.rupiah(adminFee)} biaya admin). '
                          'Rekening tujuan bertambah '
                          '${money.rupiah(_amount!)}.'
                    : 'Saldo akan berkurang ${money.rupiah(_amount!)} di '
                          'rekening asal dan bertambah sebanyak itu di '
                          'rekening tujuan.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                key: const Key('transfer_save'),
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.parseKey(_dateKey),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dateKey = AppDate.key(picked));
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.last) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return;
    setState(() {
      _time =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickWallet({required bool isSource}) async {
    final picked = await showWalletPicker(
      context,
      selectedId: isSource ? _fromWalletId : _toWalletId,
      title: isSource ? 'Pilih Rekening Asal' : 'Pilih Rekening Tujuan',
    );
    if (picked == null) return;
    setState(() {
      if (isSource) {
        _fromWalletId = picked.id;
      } else {
        _toWalletId = picked.id;
      }
    });
  }

  Future<void> _openCalculator() async {
    final result = await showCalculator(context, initial: _amount);
    if (result == null) return;
    setState(() => _amount = result);
  }

  Future<void> _save() async {
    final amount = _amount;
    final from = _fromWalletId;
    final to = _toWalletId;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // SPEC S-2, pesan Sepran apa adanya.
    final message = TransactionRules.validateTransfer(
      amount: amount,
      fromWalletId: from,
      toWalletId: to,
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final noteError = TransactionRules.validateNote(_note.text);
    if (noteError != null) {
      messenger.showSnackBar(SnackBar(content: Text(noteError)));
      return;
    }

    final adminFee = MoneyInput.tryParse(_adminFee.text) ?? 0;
    final feeError = TransactionRules.validateAdminFee(
      adminFee: adminFee,
      amount: amount,
    );
    if (feeError != null) {
      messenger.showSnackBar(SnackBar(content: Text(feeError)));
      return;
    }

    final note = TransactionRules.normalize(_note.text);
    setState(() => _busy = true);

    try {
      await ref
          .read(transactionRepositoryProvider)
          .createTransfer(
            amount: amount!,
            fromWalletId: from!,
            toWalletId: to!,
            date: _dateKey,
            note: note.isEmpty ? null : note,
            time: _time,
            adminFee: adminFee,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $error')),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Transaksi tersimpan')),
    );
  }
}

/// Baris rekening yang menampilkan nama rekening terpilih.
class _WalletLine extends ConsumerWidget {
  const _WalletLine({
    required this.walletId,
    required this.placeholder,
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final String? walletId;
  final String placeholder;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallets = ref.watch(walletBalancesProvider).value;
    final name = wallets
        ?.where((wallet) => wallet.id == walletId)
        .map((wallet) => wallet.name)
        .firstOrNull;

    final labelText = label;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (labelText != null)
                    Text(labelText, style: theme.textTheme.bodySmall),
                  Text(
                    name ?? placeholder,
                    style: name == null
                        ? theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 20),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
