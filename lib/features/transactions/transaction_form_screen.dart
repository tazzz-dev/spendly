import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/tx_kind.dart';
import '../../domain/tx_rules.dart';
import '../../domain/wallet_balance.dart';
import '../wallets/wallet_visuals.dart';
import 'calculator_sheet.dart';
import 'suggestion_chips.dart';
import 'wallet_picker_sheet.dart';

/// Empat bentuk form transaksi. SPEC §5.2 sampai §5.4.
///
/// Pemasukan dan Pengeluaran memakai form yang sama persis (SPEC T-22); yang
/// berbeda hanya daftar saran. Pindah Saldo dan Koreksi Saldo masing-masing
/// punya susunan field sendiri.
enum TxFormMode {
  income('Tambah Transaksi'),
  expense('Tambah Transaksi'),
  transfer('Tambah Transaksi'),
  correction('Koreksi Saldo');

  const TxFormMode(this.title);

  final String title;

  /// Jenis saran hanya berlaku untuk pemasukan dan pengeluaran (SPEC C-3).
  TxKind? get kind => switch (this) {
    TxFormMode.income => TxKind.income,
    TxFormMode.expense => TxKind.expense,
    TxFormMode.transfer || TxFormMode.correction => null,
  };
}

/// Form tambah transaksi.
///
/// [copyFrom] dipakai fitur **Salin Transaksi** (SPEC T-5): form terbuka
/// terisi dari transaksi yang sudah ada, tetapi tetap disimpan sebagai baris
/// baru.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    required this.mode,
    this.presetWalletId,
    this.initialDate,
    this.copyFrom,
    this.editFrom,
  });

  final TxFormMode mode;

  /// Tanggal awal form, dipakai saat menambah dari hari yang sedang dilihat.
  final String? initialDate;

  /// Rekening yang langsung terpilih, dipakai jalur Koreksi Saldo dari halaman
  /// Rekening (SPEC K-6).
  final String? presetWalletId;

  final TransactionEntry? copyFrom;

  /// Baris yang sedang **diubah**. Bila terisi, form menyimpan sebagai
  /// perubahan atas baris itu, bukan sebagai baris baru.
  final TransactionEntry? editFrom;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _note;
  late final TextEditingController _adminFee;

  late String _date;
  late String _time;

  String? _fromWalletId;
  String? _toWalletId;
  bool _busy = false;

  /// Biaya admin hanya ada di Pindah Saldo dan boleh dikosongkan.
  ///
  /// Saat mengubah transfer lama, nilainya dimuat dari baris biaya yang sudah
  /// tersimpan. Selama pemuatan belum selesai, penyimpanan tidak boleh
  /// menganggapnya nol — kalau tidak, biaya lama akan terhapus diam-diam.
  bool _adminFeeLoaded = true;

  /// Menyala setelah pengguna menekan Simpan tanpa memilih dompet. Dipakai
  /// untuk memberi tanda merah pada pemilih rekening, bukan hanya pesan
  /// sekilas di bawah layar.
  bool _walletMissing = false;

  TxFormMode get _mode => widget.mode;
  TransactionEntry? get _copy => widget.copyFrom;

  @override
  void initState() {
    super.initState();
    final edit = widget.editFrom;
    final source = edit ?? _copy;

    _date = source?.date ?? widget.initialDate ?? AppDate.today();
    // SPEC T-18: jam terisi waktu sekarang, bukan dikosongkan.
    _time = source?.time ?? _nowTime();

    // Saat mengubah atau menyalin, nominal diisi dengan angka yang berlaku
    // supaya pengguna bisa menimpanya (SPEC T-5). Pemisah ribuan langsung
    // ditampilkan agar besar nominalnya mudah dibaca.
    _amount = TextEditingController(
      text: source == null
          ? ''
          : MoneyInputFormatter.formatValue(
              source.kind == TxKind.correction
                  ? source.amount
                  : source.magnitude,
            ),
    );
    _title = TextEditingController(text: source?.title ?? '');
    _category = TextEditingController(text: source?.category ?? '');
    _note = TextEditingController(text: source?.note ?? '');
    _adminFee = TextEditingController();

    _fromWalletId = _mode == TxFormMode.transfer
        ? source?.walletId
        : (widget.presetWalletId ?? source?.walletId);
    _toWalletId = source?.counterWalletId;

    if (_mode == TxFormMode.transfer) {
      final groupId = widget.editFrom?.transferGroupId;
      if (groupId != null && groupId.isNotEmpty) {
        _adminFeeLoaded = false;
        _loadAdminFee(groupId);
      }
    }
  }

  /// Mengisi field biaya admin dari transfer yang sedang diubah.
  Future<void> _loadAdminFee(String groupId) async {
    try {
      final fee = await ref
          .read(transactionRepositoryProvider)
          .adminFeeForGroup(groupId);
      if (!mounted) return;
      setState(() {
        if (fee > 0) {
          _adminFee.text = MoneyInputFormatter.formatValue(fee);
        }
        _adminFeeLoaded = true;
      });
    } catch (_) {
      // Biarkan `_adminFeeLoaded` tetap false: bila pengguna tidak menyentuh
      // field ini, biaya lama dipertahankan. Begitu ia mengetik, nilainya
      // dianggap sudah diketahui lewat onChanged di bawah.
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _category.dispose();
    _note.dispose();
    _adminFee.dispose();
    super.dispose();
  }

  static String _nowTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];
    // Sejak SPEC T-1 diperketat: form **tidak** lagi memilih rekening bawaan
    // sendiri. Pengguna harus memilih sadar-sadar, supaya transaksi tidak
    // mendarat di rekening yang salah.
    final fromWallet = _walletById(wallets, _fromWalletId);
    final toWallet = _walletById(wallets, _toWalletId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editFrom == null ? _mode.title : 'Ubah Transaksi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _FieldTile(
                  icon: Icons.calendar_today,
                  label: 'Tanggal',
                  value: AppDate.readable(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldTile(
                  icon: Icons.schedule,
                  label: 'Jam',
                  value: _time,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SPEC S-1: rekening asal tanpa label, tujuan berlabel.
          if (_mode == TxFormMode.transfer) ...[
            _walletTile(
              key: const Key('tx_wallet_from'),
              title: fromWallet?.name ?? 'Pilih Dompet / Rekening',
              wallet: fromWallet,
              hasError: _walletMissing && fromWallet == null,
              onTap: () => _pickWallet(from: true),
            ),
            const SizedBox(height: 8),
            Text('Tujuan', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            _walletTile(
              key: const Key('tx_wallet_to'),
              title: toWallet?.name ?? 'Pilih Rekening Tujuan',
              wallet: toWallet,
              hasError:
                  _walletMissing && fromWallet != null && toWallet == null,
              onTap: () => _pickWallet(from: false),
            ),
          ] else ...[
            _walletTile(
              key: const Key('tx_wallet_from'),
              title: fromWallet?.name ?? 'Pilih Dompet / Rekening',
              wallet: fromWallet,
              hasError: _walletMissing && fromWallet == null,
              onTap: () => _pickWallet(from: true),
            ),
            if (_walletMissing && fromWallet == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  TransactionRules.walletRequired,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],

          const SizedBox(height: 16),
          TextField(
            key: const Key('tx_amount'),
            controller: _amount,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixText: 'Rp',
              border: const OutlineInputBorder(),
              // SPEC T-19: hanya field Jumlah yang punya ikon kalkulator.
              suffixIcon: IconButton(
                tooltip: 'Kalkulator',
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _openCalculator,
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(
              // SPEC K-5: hanya koreksi saldo yang boleh bernilai negatif.
              signed: _mode == TxFormMode.correction,
            ),
            // SPEC G-1: ribuan dipisah titik saat mengetik, mulai dari 1.000.
            inputFormatters: [
              MoneyInputFormatter(
                allowNegative: _mode == TxFormMode.correction,
              ),
            ],
          ),

          // Biaya admin hanya untuk Pindah Saldo. Opsional: kosong berarti
          // tidak ada potongan tambahan di rekening asal.
          if (_mode == TxFormMode.transfer) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('tx_admin_fee'),
              controller: _adminFee,
              decoration: const InputDecoration(
                labelText: 'Biaya admin (opsional)',
                prefixText: 'Rp',
                helperText: 'Dipotong dari rekening asal',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [MoneyInputFormatter()],
              onChanged: (_) => setState(() => _adminFeeLoaded = true),
            ),
          ],

          // Judul dan kategori hanya ada di pemasukan dan pengeluaran
          // (SPEC S-9 untuk pindah saldo, K-2 untuk koreksi saldo).
          if (_mode == TxFormMode.income || _mode == TxFormMode.expense) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('tx_title'),
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Ketik disini untuk judul baru',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            SuggestionChips(
              type: SuggestionRules.titleType,
              kind: _mode.kind!,
              query: _title.text,
              onSelected: _selectTitle,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('tx_category'),
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                hintText: 'Ketik disini untuk kategori baru',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            SuggestionChips(
              type: SuggestionRules.categoryType,
              kind: _mode.kind!,
              query: _category.text,
              onSelected: (value) => setState(() => _category.text = value),
            ),
          ],

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
            // SPEC T-18: tombol Simpan rata kanan.
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                key: const Key('tx_save'),
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTitle(String value) async {
    setState(() => _title.text = value);
    if (_category.text.trim().isNotEmpty) return;

    final kind = _mode.kind;
    if (kind == null) return;

    final category = await ref
        .read(transactionRepositoryProvider)
        .categoryForTitle(title: value, kind: kind);
    if (!mounted || category == null) return;
    // Pengguna mungkin sudah mengetik kategori selama pencarian berjalan.
    if (_category.text.trim().isNotEmpty) return;
    setState(() => _category.text = category);
  }

  Widget _walletTile({
    Key? key,
    required String title,
    required WalletBalance? wallet,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    final theme = Theme.of(context);
    final color = wallet == null
        ? theme.colorScheme.outline
        : Color(wallet.color ?? walletColorChoices.first);

    return ListTile(
      key: key,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: hasError
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
          width: hasError ? 1.5 : 1,
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          wallet == null
              ? Icons.account_balance_wallet_outlined
              : walletIcon(wallet.type, wallet.iconKey),
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  WalletBalance? _walletById(List<WalletBalance> wallets, String? id) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  /// Rekening tidak lagi dipilih otomatis. Form sengaja terbuka dengan
  /// pemilih kosong supaya pengguna memilih sendiri (permintaan UX: hapus
  /// dompet bawaan). SPEC G-8 tetap berarti "selalu ada rekening bawaan di
  /// basis data", bukan "form memilihnya diam-diam".

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

  Future<void> _pickWallet({required bool from}) async {
    final picked = await showWalletPicker(
      context,
      selectedId: from ? _fromWalletId : _toWalletId,
      title: from ? 'Pilih Rekening' : 'Pilih Rekening Tujuan',
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _fromWalletId = picked.id;
        _walletMissing = false;
      } else {
        _toWalletId = picked.id;
        if (_fromWalletId != null) _walletMissing = false;
      }
    });
  }

  Future<void> _openCalculator() async {
    final current = MoneyInput.tryParse(_amount.text) ?? 0;
    final result = await showCalculator(context, initial: current);
    if (result == null) return;
    final formatted = MoneyInputFormatter.formatValue(result);
    setState(() {
      _amount.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  /// Menyusun nominal bertanda seperti yang dibaca aturan validasi.
  ///
  /// Pemasukan dan pengeluaran selalu diketik positif; koreksi saldo boleh
  /// negatif (SPEC K-5).
  int? get _parsedAmount => MoneyInput.tryParse(_amount.text);

  /// Biaya admin yang diketik. Kosong berarti tidak ada biaya.
  int? get _parsedAdminFee => MoneyInput.tryParse(_adminFee.text);

  Future<void> _save() async {
    final fromId = _fromWalletId;

    final amount = _parsedAmount;
    final message = switch (_mode) {
      TxFormMode.income ||
      TxFormMode.expense => TransactionRules.validateSimple(
        amount: amount,
        title: _title.text,
        category: _category.text,
        walletId: fromId,
      ),
      TxFormMode.transfer => TransactionRules.validateTransfer(
        amount: amount,
        fromWalletId: fromId,
        toWalletId: _toWalletId,
      ),
      TxFormMode.correction => TransactionRules.validateCorrection(
        amount: amount,
        walletId: fromId,
      ),
    };

    if (message != null) {
      // Tandai pemilih rekening bila itulah yang kurang, lalu tampilkan pesan
      // aturan yang sudah ada. Pengguna melihat dua isyarat sekaligus.
      setState(() {
        _walletMissing =
            fromId == null ||
            (_mode == TxFormMode.transfer && _toWalletId == null);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final adminFee = _mode == TxFormMode.transfer ? (_parsedAdminFee ?? 0) : 0;
    if (_mode == TxFormMode.transfer) {
      final feeError = TransactionRules.validateAdminFee(
        adminFee: adminFee,
        amount: amount,
      );
      if (feeError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(feeError)));
        return;
      }
    }

    setState(() => _walletMissing = false);

    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final value = amount!.abs();
    final editId = widget.editFrom?.id;
    final isEditing = editId != null;

    setState(() => _busy = true);

    try {
      switch (_mode) {
        case TxFormMode.income:
        case TxFormMode.expense:
          final kind = _mode == TxFormMode.income
              ? TxKind.income
              : TxKind.expense;
          if (isEditing) {
            await repository.updateSimple(
              id: editId,
              kind: kind,
              amount: value,
              walletId: fromId!,
              title: _title.text,
              category: _category.text,
              date: _date,
              note: _note.text,
              time: _time,
            );
          } else {
            await repository.createSimple(
              kind: kind,
              amount: value,
              walletId: fromId!,
              title: _title.text,
              category: _category.text,
              date: _date,
              note: _note.text,
              time: _time,
            );
          }
        case TxFormMode.transfer:
          final groupId = widget.editFrom?.transferGroupId;
          if (isEditing && groupId != null && groupId.isNotEmpty) {
            // Kedua sisi pindah saldo diubah bersama, kalau tidak saldonya
            // jadi tidak seimbang. SPEC S-7.
            await repository.updateTransfer(
              groupId: groupId,
              amount: value,
              fromWalletId: fromId!,
              toWalletId: _toWalletId!,
              date: _date,
              note: _note.text,
              time: _time,
              // Bila biaya lama belum sempat dimuat, biarkan apa adanya
              // ketimbang menghapusnya tanpa sepengetahuan pengguna.
              adminFee: _adminFeeLoaded ? adminFee : null,
            );
          } else {
            await repository.createTransfer(
              amount: value,
              fromWalletId: fromId!,
              toWalletId: _toWalletId!,
              date: _date,
              note: _note.text,
              time: _time,
              adminFee: adminFee,
            );
          }
        case TxFormMode.correction:
          if (isEditing) {
            await repository.updateCorrection(
              id: editId,
              // Nominal koreksi boleh negatif; hanya nol yang ditolak tadi.
              amount: amount,
              walletId: fromId!,
              date: _date,
              note: _note.text,
              time: _time,
            );
          } else {
            await repository.createCorrection(
              // Nominal koreksi boleh negatif; hanya nol yang ditolak tadi.
              amount: amount,
              walletId: fromId!,
              date: _date,
              note: _note.text,
              time: _time,
            );
          }
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isEditing ? 'Perubahan tersimpan' : 'Transaksi tersimpan',
        ),
      ),
    );
  }
}

/// Kotak tanggal atau jam: ikon di kiri, label kecil, nilai di bawahnya.
class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 18),
          labelText: label,
        ),
        child: Text(value, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
