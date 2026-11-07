import 'package:flutter/material.dart';

import '../../domain/debt_direction.dart';
import '../../domain/wallet_balance.dart';
import '../wallets/wallet_visuals.dart';
import 'debt_visuals.dart';

/// Potongan form hutang yang dipakai bersama oleh form catatan dan form entri.
///
/// Berkas ini menyentuh Flutter, jadi sengaja di `features/`, bukan `domain/`.

/// Kotak pilih tanggal atau jam: ikon di kiri, label kecil, nilai di bawahnya.
/// Susunannya meniru form transaksi supaya seluruh aplikasi terasa seragam.
class DebtPickerTile extends StatelessWidget {
  const DebtPickerTile({
    super.key,
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
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

/// Satu baris pemilih rekening. Rekening pada entri hutang **opsional**
/// (SPEC M-4), jadi ada tombol untuk mengosongkannya kembali.
class DebtWalletTile extends StatelessWidget {
  const DebtWalletTile({
    super.key,
    required this.wallet,
    required this.onTap,
    required this.onClear,
    this.isRequired = false,
  });

  final WalletBalance? wallet;
  final VoidCallback onTap;
  final VoidCallback onClear;

  /// H-21: alur pembayaran Target mewajibkan rekening. Rekening tetap boleh
  /// dikosongkan, tetapi Simpan akan menolak sampai dipilih kembali.
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = wallet == null
        ? scheme.outline
        : Color(wallet!.color ?? walletColorChoices.first);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          wallet == null
              ? Icons.account_balance_wallet_outlined
              : walletIcon(wallet!.type, wallet!.iconKey),
          color: Colors.white,
          size: 18,
        ),
      ),
      title: Text(wallet?.name ?? 'Tanpa rekening'),
      subtitle: Text(
        isRequired
            ? 'Rekening (wajib diisi untuk pembayaran target)'
            : 'Rekening (tidak wajib diisi)',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wallet != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Kosongkan rekening',
              onPressed: onClear,
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Penanda arah yang sedang dipakai form entri.
///
/// Arah dipilih lebih dulu lewat menu dua arah (SPEC H-2), jadi di dalam form
/// ia hanya ditampilkan, bukan dipilih lagi.
class DebtDirectionBanner extends StatelessWidget {
  const DebtDirectionBanner({super.key, required this.direction});

  final DebtDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = debtDirectionColor(direction);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(debtDirectionIcon(direction), color: color),
          const SizedBox(width: 12),
          Text(
            direction.label,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
