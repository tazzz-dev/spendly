import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/debt_direction.dart';
import '../../domain/debt_record.dart';
import '../../domain/debt_rules.dart';
import '../../domain/wallet_balance.dart';
import '../transactions/wallet_picker_sheet.dart';
import 'debt_form_fields.dart';
import 'debt_providers.dart';

/// Form catatan hutang.
///
/// Dua kegunaan, sesuai SPEC H-12:
/// - **membuat** catatan baru beserta entri pertamanya. Arah sudah dipilih
///   lebih dulu lewat menu dua arah (SPEC H-2), jadi [direction] wajib ada;
/// - **menyunting** catatan yang sudah ada ([initial] terisi). Bidang jumlah
///   dan rekening tidak ditampilkan, karena keduanya milik entri, bukan
///   catatan.
///
/// Urutan bidangnya mengikuti daftar di SPEC H-12 apa adanya: Nama, Jumlah,
/// Nomor HP, Keterangan, Tanggal, lalu Rekening yang opsional.
class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.direction, this.initial});

  final DebtDirection? direction;
  final DebtRecord? initial;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  late String _date;
  String? _walletId;
  bool _busy = false;

  bool get _isEditing => widget.initial != null;
  DebtDirection get _direction => widget.direction ?? DebtDirection.give;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _name = TextEditingController(text: initial?.partyName ?? '');
    _phone = TextEditingController(text: initial?.phone ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _amount = TextEditingController();
    _date = initial?.date ?? AppDate.today();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Ubah Hutang' : 'Tambah Hutang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isEditing) ...[
            DebtDirectionBanner(direction: _direction),
            const SizedBox(height: 16),
          ],

          // 1. Nama: baru, atau dipilih dari yang sudah pernah dipakai.
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'Nama',
              hintText: 'Nama orang atau keperluan',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Pilih nama yang sudah ada',
                icon: const Icon(Icons.list_alt_outlined),
                onPressed: _pickExistingName,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),

          // 2. Jumlah. Hanya ada saat membuat, karena jumlah milik entri.
          if (!_isEditing) ...[
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
          ],

          // 3. Nomor HP.
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),

          // 4. Keterangan.
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

          // 5. Tanggal.
          const SizedBox(height: 16),
          DebtPickerTile(
            icon: Icons.calendar_today,
            label: 'Tanggal',
            value: AppDate.readable(_date),
            onTap: _pickDate,
          ),

          // 6. Rekening, opsional (SPEC M-4).
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            DebtWalletTile(
              wallet: _walletById(wallets, _walletId),
              onTap: _pickWallet,
              onClear: () => setState(() => _walletId = null),
            ),
          ],
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

  Future<void> _pickWallet() async {
    final picked = await showWalletPicker(context, selectedId: _walletId);
    if (picked == null) return;
    setState(() => _walletId = picked.id);
  }

  /// Memilih nama yang sudah pernah dipakai. SPEC H-12.
  Future<void> _pickExistingName() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _NamePickerSheet(),
    );
    if (picked == null) return;
    setState(() => _name.text = picked);
  }

  Future<void> _save() async {
    final repository = ref.read(debtRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = DebtRules.normalize(_name.text);
    // Hanya besar nominal yang diketik; tandanya ditempelkan arah.
    final magnitude = MoneyInput.tryParse(_amount.text);
    final signed = (magnitude == null || magnitude == 0)
        ? null
        : _direction.apply(magnitude);

    final message = _isEditing
        ? DebtRules.validateRecord(
            partyName: name,
            phone: _phone.text,
            note: _note.text,
          )
        : DebtRules.validate(
            partyName: name,
            amount: signed,
            phone: _phone.text,
            note: _note.text,
          );

    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => _busy = true);

    try {
      if (_isEditing) {
        await repository.updateDebt(
          id: widget.initial!.id,
          partyName: name,
          date: _date,
          phone: _phone.text,
          note: _note.text,
        );
      } else {
        await repository.createDebtWithEntry(
          partyName: name,
          date: _date,
          amount: signed!,
          phone: _phone.text,
          note: _note.text,
          time: AppDate.nowTime(),
          walletId: _walletId,
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
    messenger.showSnackBar(const SnackBar(content: Text('Hutang tersimpan')));
  }
}

/// Panel bawah berisi nama yang pernah dipakai. SPEC H-12.
class _NamePickerSheet extends ConsumerWidget {
  const _NamePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(debtPartyNamesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Nama', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: names.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal membaca nama: $error'),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Belum ada nama yang dipakai'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final name in list)
                            ListTile(
                              title: Text(name),
                              onTap: () => Navigator.of(context).pop(name),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
