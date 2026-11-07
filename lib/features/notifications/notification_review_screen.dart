import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/palette.dart';
import '../../core/dates.dart';
import '../../data/providers.dart';
import '../../domain/notification_draft.dart';
import '../../domain/tx_rules.dart';
import '../../domain/wallet_balance.dart';
import '../transactions/suggestion_chips.dart';
import '../transactions/tx_visuals.dart';
import '../transactions/wallet_picker_sheet.dart';
import '../wallets/wallet_visuals.dart';

/// Layar konfirmasi sebelum draft notifikasi menjadi transaksi resmi.
///
/// Nominal, tanggal, jam, dan arah sudah dibaca dari notifikasi. Yang wajib
/// diisi pengguna hanya judul, kategori, dan rekening — rekening sudah terisi
/// otomatis bila paket aplikasinya sudah dipetakan.
class NotificationReviewScreen extends ConsumerStatefulWidget {
  const NotificationReviewScreen({super.key, required this.draft});

  final NotificationDraft draft;

  @override
  ConsumerState<NotificationReviewScreen> createState() =>
      _NotificationReviewScreenState();
}

class _NotificationReviewScreenState
    extends ConsumerState<NotificationReviewScreen> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  late String? _walletId;
  bool _busy = false;

  NotificationDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _category = TextEditingController();
    _walletId = _draft.walletId;
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyFormatProvider);
    final wallets = ref.watch(walletBalancesProvider).value ?? const [];
    final wallet = _walletById(wallets, _walletId);
    final theme = Theme.of(context);
    final isIncome = _draft.type == NotificationDraftType.income;

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Transaksi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isIncome
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isIncome ? txIncomeColor : txExpenseColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_draft.appName} • ${_draft.type.label}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${isIncome ? '+' : '-'}${money.rupiah(_draft.amount)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isIncome ? txSummaryIncomeColor : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppDate.readable(_draft.date)}'
                    '${_draft.time == null ? '' : ' • ${_draft.time}'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _draft.rawTitle.trim().isEmpty
                        ? _draft.rawMessage
                        : '${_draft.rawTitle}\n${_draft.rawMessage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rekening', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          _WalletTile(
            wallet: wallet,
            title: wallet?.name ?? 'Pilih Rekening',
            onTap: _pickWallet,
          ),
          if (wallet == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Rekening belum dipetakan untuk ${_draft.appName}. '
                'Pilih sekali di sini atau atur pemetaan di Pengaturan.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('notification_title'),
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Judul Transaksi',
              hintText: 'Contoh: Kopi Kenangan',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SuggestionChips(
            type: SuggestionRules.titleType,
            kind: _draft.type.txKind,
            query: _title.text,
            onSelected: (value) => setState(() => _title.text = value),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('notification_category'),
            controller: _category,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              hintText: 'Contoh: Makanan & Minuman',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SuggestionChips(
            type: SuggestionRules.categoryType,
            kind: _draft.type.txKind,
            query: _category.text,
            onSelected: (value) => setState(() => _category.text = value),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              TextButton(
                key: const Key('notification_delete'),
                onPressed: _busy ? null : _confirmDelete,
                child: const Text('Hapus Draft'),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('notification_save'),
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan ke Transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickWallet() async {
    final picked = await showWalletPicker(
      context,
      selectedId: _walletId,
      title: 'Pilih Rekening',
    );
    if (picked == null || !mounted) return;
    setState(() => _walletId = picked.id);
  }

  WalletBalance? _walletById(List<WalletBalance> wallets, String? id) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final message = TransactionRules.validateSimple(
      amount: _draft.amount,
      title: _title.text,
      category: _category.text,
      walletId: _walletId,
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // Rekening bisa saja dihapus/diarsipkan setelah draft masuk. Jangan
    // meneruskan ID lama ke kunci asing; minta pengguna memilih ulang.
    final wallets = ref.read(walletBalancesProvider).value ?? const [];
    if (wallets.isNotEmpty && _walletById(wallets, _walletId) == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text(TransactionRules.walletRequired)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(notificationRepositoryProvider)
          .approve(
            draft: _draft,
            title: _title.text,
            category: _category.text,
            walletId: _walletId!,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $error')),
      );
      return;
    }

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Transaksi dari notifikasi tersimpan')),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus draft?'),
        content: const Text(
          'Draft notifikasi ini akan diabaikan dan tidak menjadi transaksi.',
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
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(notificationRepositoryProvider).ignore(_draft.id);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus draft: $error')),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Draft notifikasi diabaikan')),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.title,
    required this.onTap,
  });

  final WalletBalance? wallet;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = wallet == null
        ? Theme.of(context).colorScheme.outline
        : Color(wallet!.color ?? walletColorChoices.first);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          wallet == null
              ? Icons.account_balance_wallet_outlined
              : walletIcon(wallet!.type, wallet!.iconKey),
          color: AppPalette.onAccent,
          size: 18,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
