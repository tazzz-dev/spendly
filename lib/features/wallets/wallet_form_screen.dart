import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/wallet_balance.dart';
import '../../domain/wallet_rules.dart';
import '../../domain/wallet_type.dart';
import 'wallet_visuals.dart';

/// Form tambah dan ubah rekening.
///
/// [initial] bernilai null berarti menambah rekening baru. Saat menyunting,
/// `initial` datang dari daftar sehingga tidak perlu membaca ulang basis data.
///
/// Saat menyunting, kolom saldo menampilkan **saldo saat ini**, bukan saldo
/// awal. Selisih yang diketik dicatat sebagai transaksi Koreksi Saldo, sesuai
/// SPEC K-6; saldo awal tidak pernah ditulis ulang dari layar ini.
///
/// SPEC R-1, R-4, R-5, G-8, G-9, K-6.
class WalletFormScreen extends ConsumerStatefulWidget {
  const WalletFormScreen({super.key, this.initial});

  final WalletBalance? initial;

  @override
  ConsumerState<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends ConsumerState<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _saldo;

  late WalletType _type;
  late String _iconKey;
  late int _color;
  bool _busy = false;

  /// Pesan galat khusus nama yang sudah terpakai.
  ///
  /// Dipisahkan dari [WalletName.validate] karena pemeriksaannya butuh
  /// menanyakan basis data, jadi baru bisa diisi setelah menekan Simpan.
  String? _nameError;

  WalletBalance? get _initial => widget.initial;
  bool get _isEditing => _initial != null;

  @override
  void initState() {
    super.initState();
    final initial = _initial;

    _name = TextEditingController(text: initial?.name ?? '');
    // Ditulis bergaya Indonesia (2.000.000), bukan angka polos, supaya
    // sejalan dengan saldo yang tampil di daftar rekening.
    // Saat menyunting yang ditampilkan adalah saldo saat ini, bukan saldo
    // awal. Inilah angka yang dilihat pengguna di daftar rekening, dan inilah
    // yang ingin ia ubah ketika menekan Ubah Rekening.
    _saldo = TextEditingController(
      text: MoneyFormat(showDecimals: false).plain(initial?.balance ?? 0),
    );
    _type = initial?.type ?? WalletType.cash;
    _iconKey = initial?.iconKey ?? defaultIconKey(_type);
    _color = initial?.color ?? walletColorChoices.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _saldo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewColor = Color(_color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Rekening' : 'Rekening Baru'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _busy ? null : _attemptDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus rekening',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pratinjau: pengguna langsung melihat hasil pilihan ikon dan warna.
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: previewColor,
                  child: Icon(
                    walletIcon(_type, _iconKey),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _name.text.trim().isEmpty ? _type.label : _name.text.trim(),
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // SPEC R-5 dan G-8: alasannya ditaruh di dekat kepala layar, bukan
            // di dasar daftar, supaya pengguna tahu kenapa rekening ini tidak
            // punya tombol hapus yang bisa dipakai.
            if (_isEditing && _initial!.isDefault)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ini rekening bawaan. Ia boleh diubah, tetapi tidak '
                        'boleh dihapus.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            TextFormField(
              key: const Key('wallet_name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Contoh: BCA',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              // Memperbarui pratinjau dan menyingkirkan galat nama terpakai
              // begitu pengguna mengetik nama lain.
              onChanged: (_) => setState(() {
                _nameError = null;
              }),
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            TextFormField(
              key: const Key('wallet_balance'),
              controller: _saldo,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Saldo Saat Ini' : 'Saldo Awal',
                prefixText: 'Rp ',
                border: const OutlineInputBorder(),
                helperText: _isEditing
                    ? 'Selisihnya dicatat sebagai Koreksi Saldo'
                    : 'Saldo sebelum transaksi apa pun dihitung',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: const [
                // Saldo boleh minus, tetapi tetap berpemisah ribuan.
                MoneyInputFormatter(allowNegative: true),
              ],
              validator: _validateSaldo,
            ),

            // Pengguna harus tahu bahwa angka di atas tidak menulis ulang
            // riwayat. Koreksi Saldo adalah jejak audit yang bisa dilihat lagi
            // di halaman transaksi, bukan perubahan senyap pada saldo awal.
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Saldo awal ${MoneyFormat(showDecimals: true).rupiah(_initial!.openingBalance)}. '
                  'Mengubah angka di atas membuat transaksi Koreksi Saldo '
                  'sebesar selisihnya.',
                  style: theme.textTheme.bodySmall,
                ),
              ),

            const SizedBox(height: 24),
            Text('Tipe', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in WalletType.values)
                  ChoiceChip(
                    selected: _type == type,
                    label: Text(type.label),
                    avatar: Icon(
                      walletIcon(type, defaultIconKey(type)),
                      size: 18,
                    ),
                    onSelected: (_) => setState(() {
                      // Ikon ikut berganti hanya bila pengguna belum memilih
                      // sendiri ikonnya.
                      final wasDefaultIcon = _iconKey == defaultIconKey(_type);
                      _type = type;
                      if (wasDefaultIcon) _iconKey = defaultIconKey(type);
                    }),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            Text('Warna', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final value in walletColorChoices)
                  _ColorDot(
                    color: Color(value),
                    selected: _color == value,
                    onTap: () => setState(() => _color = value),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            Text('Ikon', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in walletIconChoices.entries)
                  _IconDot(
                    icon: entry.value,
                    color: previewColor,
                    selected: _iconKey == entry.key,
                    onTap: () => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                key: const Key('wallet_save'),
                onPressed: _busy ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    final formatError = WalletName.validate(value ?? '');
    if (formatError != null) return formatError;
    return _nameError;
  }

  String? _validateSaldo(String? value) {
    if (MoneyInput.tryParse(value ?? '') == null) {
      return 'Saldo harus berupa angka, contoh: 250000 atau 250.000';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repository = ref.read(walletRepositoryProvider);
    final transactions = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final initial = _initial;

    final name = WalletName.normalize(_name.text);
    final saldo = MoneyInput.tryParse(_saldo.text) ?? 0;
    // Selisih dihitung dari saldo saat ini. Ini nilai yang tadi ditampilkan di
    // kolom, jadi koreksi selalu tepat menuju angka yang diketik pengguna.
    final correction = initial == null ? 0 : saldo - initial.balance;

    setState(() {
      _busy = true;
      _nameError = null;
    });

    // SPEC G-9. Diperiksa lebih dulu supaya pesannya jelas bagi pengguna.
    final taken = await repository.isNameTaken(name, exceptId: initial?.id);
    if (!mounted) return;
    if (taken) {
      // Ditampilkan dua kali dengan sengaja: sebagai galat di bawah field Nama,
      // dan sebagai pesan singkat di atas tombol Simpan. Field Nama bisa berada
      // di luar layar saat tombol ditekan, jadi pesan singkat itu yang menutup
      // celah itu.
      setState(() {
        _busy = false;
        _nameError = WalletName.duplicateMessage;
      });
      _formKey.currentState?.validate();
      messenger.showSnackBar(
        SnackBar(content: Text(WalletName.duplicateMessage)),
      );
      return;
    }

    try {
      if (initial == null) {
        await repository.create(
          name: name,
          type: _type,
          openingBalance: saldo,
          iconKey: _iconKey,
          color: _color,
        );
      } else {
        // Saldo awal sengaja tidak disentuh. Kalau pengguna mengubah angka
        // saldo, perbedaannya dicatat sebagai Koreksi Saldo supaya riwayat dan
        // laporan tetap jujur. SPEC K-6.
        await repository.updateDetails(
          id: initial.id,
          name: name,
          type: _type,
          iconKey: _iconKey,
          color: _color,
        );
        if (correction != 0) {
          await transactions.createCorrection(
            amount: correction,
            walletId: initial.id,
            date: AppDate.today(),
            time: AppDate.nowTime(),
            note: 'Penyesuaian dari Ubah Rekening',
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
    if (initial != null && correction != 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Rekening disimpan. Selisih saldo dicatat sebagai Koreksi Saldo.',
          ),
        ),
      );
    }
  }

  Future<void> _attemptDelete() async {
    final initial = _initial;
    if (initial == null) return;

    final repository = ref.read(walletRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _busy = true);
    final verdict = await repository.checkDelete(initial.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!verdict.allowed) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tidak bisa dihapus'),
          content: Text(deleteBlockMessage(verdict)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus ${initial.name}?'),
        content: const Text(
          'Rekening ini akan dihapus dari daftar. Tindakan ini tidak bisa '
          'dibatalkan dari layar ini.',
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

    await repository.softDelete(initial.id);
    if (!mounted) return;

    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('${initial.name} dihapus')));
  }
}

/// Lingkaran warna yang bisa dipilih.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

/// Kotak ikon yang bisa dipilih.
class _IconDot extends StatelessWidget {
  const _IconDot({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: selected ? color : scheme.onSurfaceVariant),
      ),
    );
  }
}
