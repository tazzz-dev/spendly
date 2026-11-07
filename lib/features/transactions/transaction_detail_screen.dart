import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/dates.dart';
import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/tx_kind.dart';
import 'transaction_form_screen.dart';
import 'transaction_visuals.dart';

/// Halaman **Detail Transaksi**: seluruh isi satu catatan terlihat di sini,
/// dengan pensil untuk mengubah dan tempat sampah untuk menghapus.
///
/// Susunannya mengikuti Sepran: lingkaran ikon berwarna di tengah, sebutan jenis
/// dalam huruf besar, nominal besar, tanggal dan jam, lalu kartu berisi
/// rekening, judul, kategori, dan keterangan.
///
/// Menghapus di sini **mengembalikan keadaan sebelumnya**: saldo rekening dan
/// seluruh rekap dihitung ulang dari baris yang tersisa, jadi dampak catatan itu
/// hilang seketika. Karena itu disediakan tombol **Urungkan** pada pesan sesudah
/// menghapus. SPEC T-7 dan T-8.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.entry});

  final TransactionEntry entry;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  late TransactionEntry _entry = widget.entry;
  bool _busy = false;

  /// Biaya admin yang menempel pada Pindah Saldo, bila ada. Baris biaya admin
  /// disimpan terpisah supaya saldo dan rekap tetap benar.
  int _adminFee = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminFee();
  }

  Future<void> _loadAdminFee() async {
    final entry = _entry;
    final group = entry.transferGroupId;
    if (!entry.isTransfer || group == null || group.isEmpty) return;
    try {
      final fee = await ref
          .read(transactionRepositoryProvider)
          .adminFeeForGroup(group);
      if (!mounted) return;
      setState(() => _adminFee = fee);
    } catch (_) {
      // Detail tetap bisa dibuka walau biaya admin gagal dibaca.
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyFormatProvider);
    final theme = Theme.of(context);
    final entry = _entry;
    final color = _headerColor(entry.kind);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          if (entry.kind == TxKind.income || entry.kind == TxKind.expense)
            IconButton(
              tooltip: 'Salin Transaksi',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _busy ? null : _copy,
            ),
          IconButton(
            tooltip: entry.isDebtMirror ? 'Ubah dari halaman Hutang' : 'Ubah',
            icon: const Icon(Icons.edit_outlined),
            onPressed: (_busy || entry.isDebtMirror) ? null : _edit,
          ),
          IconButton(
            tooltip: entry.isDebtMirror ? 'Hapus dari halaman Hutang' : 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: (_busy || entry.isDebtMirror) ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(TxColors.icon(entry.kind), color: color, size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              _headerLabel(entry.kind).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _amountText(money, entry),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              entry.time == null
                  ? AppDate.full(entry.date)
                  : '${AppDate.full(entry.date)} · ${entry.time}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: _rows(entry, money)),
          ),
          if (entry.isDebtMirror)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi ini lahir dari catatan Hutang. Ubah atau '
                      'hapus lewat halaman Hutang supaya catatan dan saldo '
                      'tetap sama.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Warna kepala halaman. Sepran mewarnai jenis dan nominalnya sekaligus:
  /// pengeluaran merah, pemasukan hijau, pindah dan koreksi abu-abu.
  static Color _headerColor(TxKind kind) => switch (kind) {
    TxKind.income => TxColors.positive,
    TxKind.expense => TxColors.expense,
    TxKind.transferOut ||
    TxKind.transferIn ||
    TxKind.correction => TxColors.neutral,
  };

  static String _headerLabel(TxKind kind) {
    if (kind.isTransfer) return 'Pindah Saldo';
    return kind.label;
  }

  /// Nominal bertanda. Hanya negatif yang diberi tanda, seperti daftar.
  static String _amountText(MoneyFormat money, TransactionEntry entry) {
    final sign = entry.amount < 0 ? '-' : '';
    return '$sign${money.plain(entry.magnitude)}';
  }

  List<Widget> _rows(TransactionEntry entry, MoneyFormat money) {
    final rows = <Widget>[];

    void add(Widget row) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 1));
      rows.add(row);
    }

    if (entry.isTransfer) {
      final outgoing = entry.kind == TxKind.transferOut;
      add(
        _DetailRow(
          icon: Icons.account_balance_wallet_outlined,
          label: outgoing ? 'Dari' : 'Ke',
          value: entry.walletName ?? '-',
        ),
      );
      add(
        _DetailRow(
          icon: Icons.swap_horiz,
          label: outgoing ? 'Ke' : 'Dari',
          value: entry.counterWalletName ?? '-',
        ),
      );
      if (_adminFee > 0) {
        add(
          _DetailRow(
            icon: Icons.receipt_long_outlined,
            label: 'Biaya admin',
            value: money.rupiah(_adminFee),
          ),
        );
      }
    } else {
      add(
        _DetailRow(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Rekening',
          value: entry.walletName ?? '-',
        ),
      );
    }

    final title = entry.title?.trim() ?? '';
    if (title.isNotEmpty) {
      add(_DetailRow(icon: Icons.title, label: 'Judul', value: title));
    }

    final category = entry.category?.trim() ?? '';
    if (category.isNotEmpty) {
      add(
        _DetailRow(
          icon: Icons.sell_outlined,
          label: 'Kategori',
          value: category,
          chip: true,
        ),
      );
    }

    final note = entry.note?.trim() ?? '';
    if (note.isNotEmpty) {
      add(
        _DetailRow(
          icon: Icons.notes_outlined,
          label: 'Keterangan',
          value: note,
        ),
      );
    }

    return rows;
  }

  Future<void> _edit() async {
    final entry = _entry;
    final mode = switch (entry.kind) {
      TxKind.income => TxFormMode.income,
      TxKind.expense => TxFormMode.expense,
      TxKind.transferOut || TxKind.transferIn => TxFormMode.transfer,
      TxKind.correction => TxFormMode.correction,
    };

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(mode: mode, editFrom: entry),
      ),
    );
    if (!mounted) return;

    final refreshed = await ref
        .read(transactionRepositoryProvider)
        .findById(entry.id);
    if (!mounted) return;

    // Baris bisa saja hilang kalau tanggalnya dipindah ke hari lain sementara
    // penyaring daftar tidak lagi memuatnya. Kembali diam-diam lebih aman
    // daripada menampilkan layar kosong.
    if (refreshed == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _entry = refreshed);
    await _loadAdminFee();
  }

  Future<void> _copy() async {
    final entry = _entry;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(
          mode: entry.kind == TxKind.income
              ? TxFormMode.income
              : TxFormMode.expense,
          copyFrom: entry,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // SPEC T-7: pesan konfirmasi Sepran, disalin apa adanya.
        content: const Text('Apakah Anda yakin akan menghapus transaksi ini?'),
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

    if (confirmed != true || !mounted) return;

    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final id = _entry.id;

    setState(() => _busy = true);
    try {
      // RW-4: menghapus satu sisi pindah saldo ikut menghapus pasangannya.
      await repository.softDelete(id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $error')),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => repository.restore(id),
        ),
      ),
    );
  }
}

/// Satu baris isi di kartu detail: ikon kecil, label, lalu nilai di kanan.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.chip = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Kategori ditampilkan sebagai lencana, bukan teks biasa — seperti Sepran.
  final bool chip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: chip
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.positive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppPalette.positive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
