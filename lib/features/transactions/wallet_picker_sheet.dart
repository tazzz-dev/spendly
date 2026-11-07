import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/wallet_balance.dart';
import '../wallets/wallet_list_screen.dart';
import '../wallets/wallet_visuals.dart';

/// Memilih rekening lewat **panel bawah**, bukan menu tarik-turun. SPEC T-21.
///
/// Mengembalikan rekening yang dipilih, atau null bila panel ditutup tanpa
/// memilih. Rekening yang sedang terpilih ditandai supaya pengguna tahu.
Future<WalletBalance?> showWalletPicker(
  BuildContext context, {
  String? selectedId,
  String title = 'Pilih Rekening',
}) {
  return showModalBottomSheet<WalletBalance>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WalletPickerSheet(selectedId: selectedId, title: title),
  );
}

class _WalletPickerSheet extends ConsumerWidget {
  const _WalletPickerSheet({required this.title, this.selectedId});

  final String title;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wallets = ref.watch(walletBalancesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                // SPEC T-21: ikon pensil untuk mengelola rekening.
                IconButton(
                  onPressed: () => _manageWallets(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Kelola rekening',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: wallets.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal membaca rekening: $error'),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Belum ada rekening'),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                        children: [
                          for (final wallet in list)
                            _WalletTile(
                              wallet: wallet,
                              selected: wallet.id == selectedId,
                              onTap: () => Navigator.of(context).pop(wallet),
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

  Future<void> _manageWallets(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push<void>(
      MaterialPageRoute(builder: (_) => const WalletListScreen()),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.selected,
    required this.onTap,
  });

  final WalletBalance wallet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(wallet.color ?? walletColorChoices.first);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(
                walletIcon(wallet.type, wallet.iconKey),
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wallet.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
