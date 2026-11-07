import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/debt_record.dart';
import '../../domain/debt_rules.dart';
import '../../domain/debt_target_direction.dart';
import 'debt_form_fields.dart';
import 'debt_providers.dart';

/// Form target: membuat target baru, atau mengubah/menambahkan target pada
/// catatan yang sudah ada.
///
/// Urutan bidang mengikuti USULAN-HUTANG-TARGET §6.4: Nama, Arah, Total target,
/// Sudah dibayar, Tanggal, Catatan. **Tidak ada field rekening**, karena target
/// bukan pergerakan uang (H-18).
class DebtTargetFormScreen extends ConsumerStatefulWidget {
  const DebtTargetFormScreen({super.key, this.initial});

  /// Catatan yang targetnya diubah. Null berarti target benar-benar baru.
  final DebtRecord? initial;

  @override
  ConsumerState<DebtTargetFormScreen> createState() =>
      _DebtTargetFormScreenState();
}

class _DebtTargetFormScreenState extends ConsumerState<DebtTargetFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _paidOpening;
  late final TextEditingController _note;

  late DebtTargetDirection _direction;
  late String _date;
  bool _busy = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final progress = initial?.progress;

    _name = TextEditingController(text: initial?.partyName ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _target = TextEditingController(
      text: progress == null ? '' : '${progress.target}',
    );
    _paidOpening = TextEditingController(
      text: progress == null || progress.paidOpening == 0
          ? ''
          : '${progress.paidOpening}',
    );
    _direction = initial?.targetDirection ?? DebtTargetDirection.owe;
    _date = initial?.date ?? AppDate.today();
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _paidOpening.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          !_isEditing
              ? 'Target Baru'
              : widget.initial!.hasTarget
              ? 'Ubah Target'
              : 'Jadikan Target',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nama',
              hintText: 'Nama orang atau keperluan',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // 2. Arah pokok target.
          Text('Arah', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final direction in DebtTargetDirection.values)
                ChoiceChip(
                  key: Key('target-direction-${direction.storageValue}'),
                  label: Text(direction.label),
                  selected: _direction == direction,
                  onSelected: (_) => setState(() => _direction = direction),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Total target.
          TextField(
            controller: _target,
            decoration: const InputDecoration(
              labelText: 'Total target',
              prefixText: 'Rp',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
          ),
          const SizedBox(height: 16),

          // 4. Sudah dibayar sebelum aplikasi dipakai (H-27).
          TextField(
            controller: _paidOpening,
            decoration: const InputDecoration(
              labelText: 'Sudah dibayar',
              hintText: 'Opsional',
              prefixText: 'Rp',
              border: OutlineInputBorder(),
              helperText: 'Hanya titik awal progress; tidak mengubah saldo.',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
          ),
          const SizedBox(height: 16),

          // 5. Tanggal.
          DebtPickerTile(
            icon: Icons.calendar_today,
            label: 'Tanggal',
            value: AppDate.readable(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // 6. Catatan.
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Catatan',
              hintText: 'Keterangan (tidak wajib diisi)',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Target tidak mengurangi saldo. Saldo baru berkurang saat kamu '
              'mencatat pembayaran.',
              style: theme.textTheme.bodySmall,
            ),
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

  Future<void> _save() async {
    final repository = ref.read(debtRepositoryProvider);
    final money = ref.read(moneyFormatProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = DebtRules.normalize(_name.text);
    final target = MoneyInput.tryParse(_target.text);
    final opening = MoneyInput.tryParse(_paidOpening.text) ?? 0;

    final message = DebtRules.validateTarget(
      partyName: name,
      targetAmount: target,
      paidOpening: opening,
      note: _note.text,
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // H-25: target baru di bawah jumlah yang sudah dibayar butuh konfirmasi.
    final alreadyPaid = (widget.initial?.progress?.paidEntries ?? 0) + opening;
    if (_isEditing && target! < alreadyPaid) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(DebtRules.targetBelowPaidWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _busy = true);

    try {
      if (_isEditing) {
        await repository.updateTarget(
          id: widget.initial!.id,
          partyName: name,
          date: _date,
          targetAmount: target!,
          direction: _direction,
          paidOpening: opening,
          note: _note.text,
        );
      } else {
        await repository.createTarget(
          partyName: name,
          date: _date,
          targetAmount: target!,
          direction: _direction,
          paidOpening: opening,
          note: _note.text,
        );
      }
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

    final overpaid = alreadyPaid - target;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          overpaid > 0
              ? 'Lunas, lebih ${money.rupiah(overpaid)}'
              : 'Target tersimpan',
        ),
      ),
    );
  }
}
