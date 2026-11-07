import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/debt_direction.dart';
import '../../domain/debt_entry.dart';
import '../../domain/debt_rules.dart';
import '../../domain/debt_target_direction.dart';
import '../../domain/wallet_balance.dart';
import '../transactions/wallet_picker_sheet.dart';
import 'debt_form_fields.dart';
import 'debt_providers.dart';
import 'debt_visuals.dart';

/// Form entri hutang: menambah atau menyunting satu entri pada catatan yang
/// sudah ada. SPEC H-6 dan H-11.
///
/// Arah sudah ditentukan lebih dulu lewat menu dua arah (SPEC H-2); pada mode
/// menyunting arah diambil dari entri itu sendiri. Pengguna hanya mengetik
/// besar nominalnya, lalu [DebtDirection.apply] yang menempelkan tandanya.
class DebtEntryFormScreen extends ConsumerStatefulWidget {
  const DebtEntryFormScreen({
    super.key,
    required this.debtId,
    this.direction,
    this.existing,
    this.targetDirection,
  });

  final String debtId;
  final DebtDirection? direction;
  final DebtEntry? existing;

  /// Bila terisi, form ini adalah **pembayaran target** (H-21): arah otomatis
  /// mengikuti arah pokok dan rekening wajib dipilih.
  final DebtTargetDirection? targetDirection;

  @override
  ConsumerState<DebtEntryFormScreen> createState() =>
      _DebtEntryFormScreenState();
}

class _DebtEntryFormScreenState extends ConsumerState<DebtEntryFormScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _note;

  late String _date;
  late String _time;
  String? _walletId;
  bool _busy = false;

  bool get _isEditing => widget.existing != null;

  /// Pembayaran target hanya berlaku untuk entri baru; menyunting entri lama
  /// tetap mengikuti aturan umum (SPEC M-4).
  bool get _isPayment => !_isEditing && widget.targetDirection != null;

  /// Arah entri: dari entri yang disunting, dari arah pembayaran target, atau
  /// dari pilihan menu.
  DebtDirection get _direction =>
      widget.existing?.direction ??
      widget.targetDirection?.paymentDirection ??
      widget.direction ??
      DebtDirection.give;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _amount = TextEditingController(
      text: existing == null ? '' : '${existing.magnitude}',
    );
    _note = TextEditingController(text: existing?.note ?? '');
    _date = existing?.date ?? AppDate.today();
    _time = existing?.time ?? AppDate.nowTime();
    _walletId = existing?.walletId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Ubah Entri'
              : _isPayment
              ? 'Bayar Target'
              : 'Tambah Entri',
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(debtDeleteIcon),
              tooltip: 'Hapus entri',
              onPressed: _busy ? null : _confirmDelete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DebtDirectionBanner(direction: _direction),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(
              labelText: 'Jumlah',
              prefixText: 'Rp',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DebtPickerTile(
                  icon: Icons.calendar_today,
                  label: 'Tanggal',
                  value: AppDate.readable(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DebtPickerTile(
                  icon: Icons.schedule,
                  label: 'Jam',
                  value: _time,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DebtWalletTile(
            wallet: _walletById(wallets, _walletId),
            onTap: _pickWallet,
            onClear: () => setState(() => _walletId = null),
            isRequired: _isPayment,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              hintText: 'Keterangan (tidak wajib diisi)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WalletBalance? _walletById(List<WalletBalance> wallets, String? id) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: AppDate.parseKey(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = AppDate.key(picked));
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (picked == null) return;
    setState(() {
      _time =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickWallet() async {
    final picked = await showWalletPicker(context, selectedId: _walletId);
    if (picked == null) return;
    setState(() => _walletId = picked.id);
  }

  Future<void> _save() async {
    final repository = ref.read(debtRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final magnitude = MoneyInput.tryParse(_amount.text);
    final signed = (magnitude == null || magnitude == 0)
        ? null
        : _direction.apply(magnitude);

    final message = DebtRules.validateAmount(signed);
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // H-21: pembayaran Target wajib memakai rekening supaya saldo berkurang.
    if (_isPayment && _walletId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text(DebtRules.walletRequiredForPayment)),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      if (_isEditing) {
        await repository.updateEntry(
          id: widget.existing!.id,
          amount: signed!,
          date: _date,
          time: _time,
          walletId: _walletId,
          note: _note.text,
        );
      } else if (_isPayment) {
        await repository.addPayment(
          debtId: widget.debtId,
          magnitude: magnitude!,
          date: _date,
          time: _time,
          walletId: _walletId,
          note: _note.text,
        );
      } else {
        await repository.addEntry(
          debtId: widget.debtId,
          amount: signed!,
          date: _date,
          time: _time,
          walletId: _walletId,
          note: _note.text,
        );
      }
    } on DebtPaymentException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
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
    messenger.showSnackBar(const SnackBar(content: Text('Entri tersimpan')));
  }

  Future<void> _confirmDelete() async {
    final repository = ref.read(debtRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('Apakah Anda yakin akan menghapus entri ini?'),
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

    await repository.deleteEntry(widget.existing!.id);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Entri dihapus')));
  }
}
