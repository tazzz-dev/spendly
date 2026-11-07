import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/wallet_balance.dart';
import 'wallet_form_screen.dart';
import 'wallet_visuals.dart';

/// Daftar rekening, dengan Total Saldo di baris paling atas. SPEC R-2.
///
/// Memakai `Scaffold` sendiri walau sudah berada di dalam kerangka lima tab:
/// hanya dengan begitu tombol tambah bisa mengambang tepat di atas bilah
/// navigasi. Bilah judul tetap milik kerangka, jadi tidak ada judul kembar.
class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletBalancesProvider);

    // Ikut setelan "Tampilkan Angka Desimal". SPEC ST-3.
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Pesannya sengaja tidak menumpahkan galat basis data mentah ke layar;
        // yang dibutuhkan pengguna hanya tahu bahwa bacaan gagal dan bisa
        // dicoba lagi.
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gagal membaca daftar rekening.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(walletBalancesProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (list) => _WalletList(wallets: list, money: money),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openWalletForm(context),
        tooltip: 'Tambah rekening',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Membuka form rekening. Tanpa [wallet] berarti menambah.
Future<void> openWalletForm(BuildContext context, {WalletBalance? wallet}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => WalletFormScreen(initial: wallet)),
  );
}

class _WalletList extends StatelessWidget {
  const _WalletList({required this.wallets, required this.money});

  final List<WalletBalance> wallets;
  final MoneyFormat money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = wallets.fold<int>(0, (sum, wallet) => sum + wallet.balance);

    return ListView(
      children: [
        ListTile(
          title: const Text('Total Saldo'),
          trailing: Text(
            money.rupiah(total),
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(height: 1),
        if (wallets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Belum ada rekening'),
          ),
        for (final wallet in wallets) ...[
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(wallet.color ?? walletColorChoices.first),
              child: Icon(
                walletIcon(wallet.type, wallet.iconKey),
                color: Colors.white,
              ),
            ),
            // Nama dan jenis dipangkas dengan elipsis: rekening boleh bernama
            // panjang, dan pada layar sempit (HP 1080x2408) barisnya tidak
            // boleh meluber keluar kartu.
            title: Text(
              wallet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // SPEC G-8: rekening bawaan ditandai supaya pengguna tahu kenapa
            // rekening itu tidak bisa dihapus.
            subtitle: Text(
              wallet.isDefault
                  ? '${wallet.type.label} • Bawaan'
                  : wallet.type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              money.rupiah(wallet.balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => openWalletForm(context, wallet: wallet),
          ),
          const Divider(height: 1, indent: 72),
        ],
        // Ruang agar baris terakhir tidak tertutup tombol tambah.
        const SizedBox(height: 88),
      ],
    );
  }
}
