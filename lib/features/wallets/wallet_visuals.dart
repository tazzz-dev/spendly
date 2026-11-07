import 'package:flutter/material.dart';

import '../../domain/wallet_type.dart';

/// Ikon dan warna rekening.
///
/// Berkas ini menyentuh Flutter, jadi sengaja diletakkan di `features/`, bukan
/// di `domain/`. Lihat RENCANA-BUILD §2.

/// Kunci ikon yang boleh dipilih pengguna. Yang disimpan di basis data adalah
/// kuncinya, bukan kodenya, supaya pemetaan bisa berubah tanpa migrasi.
const Map<String, IconData> walletIconChoices = {
  'wallet': Icons.account_balance_wallet_outlined,
  'cash': Icons.payments_outlined,
  'bank': Icons.account_balance_outlined,
  'savings': Icons.savings_outlined,
  'card': Icons.credit_card_outlined,
  'phone': Icons.smartphone_outlined,
  'growth': Icons.trending_up_outlined,
  'store': Icons.storefront_outlined,
  'gift': Icons.card_giftcard_outlined,
  'home': Icons.home_outlined,
};

/// Ikon bawaan sebuah jenis rekening.
String defaultIconKey(WalletType type) => switch (type) {
  WalletType.cash => 'cash',
  WalletType.bank => 'bank',
  WalletType.ewallet => 'phone',
  WalletType.creditCard => 'card',
  WalletType.investment => 'growth',
  WalletType.other => 'wallet',
};

/// Ikon yang akhirnya dipakai sebuah rekening: pilihan pengguna bila ada,
/// kalau tidak ikon bawaan jenisnya.
IconData walletIcon(WalletType type, String? iconKey) =>
    walletIconChoices[iconKey] ??
    walletIconChoices[defaultIconKey(type)] ??
    Icons.account_balance_wallet_outlined;

/// Warna yang boleh dipilih pengguna, sebagai ARGB.
const List<int> walletColorChoices = [
  0xFF1E88E5,
  0xFF43A047,
  0xFFE53935,
  0xFFFB8C00,
  0xFF8E24AA,
  0xFF00897B,
  0xFF6D4C41,
  0xFF546E7A,
];
