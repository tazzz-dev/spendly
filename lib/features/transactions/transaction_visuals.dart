import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../domain/tx_kind.dart';

/// Warna arah uang, satu tempat saja.
///
/// SPEC T-16 dan VERIFIKASI bagian D: **oranye = uang masuk**, **merah = uang
/// keluar**, **abu-abu = netral**. Nilainya diambil dari [AppPalette] supaya
/// tidak ada lagi dua oranye berbeda di aplikasi yang sama.
///
/// SPEC T-12 menyebut kolom Pemasukan berwarna **hijau**. Itu warna *nominal*,
/// bukan warna penanda jenis: Sepran memakai oranye untuk ikon dan hijau untuk
/// angka. Keduanya dipakai sesuai perannya masing-masing.
class TxColors {
  const TxColors._();

  /// Penanda uang masuk. SPEC T-16.
  static const Color income = AppPalette.moneyIn;

  /// Penanda uang keluar. SPEC T-16.
  static const Color expense = AppPalette.moneyOut;

  /// Pindah saldo: tidak menambah dan tidak mengurangi kekayaan. SPEC T-16.
  static const Color neutral = AppPalette.neutral;

  /// Nominal positif. SPEC T-12, H-1, H-3.
  static const Color positive = AppPalette.positive;

  /// Warna penanda jenis pergerakan, untuk ikon.
  static Color of(TxKind kind) => switch (kind) {
    TxKind.income => income,
    TxKind.expense => expense,
    TxKind.transferOut || TxKind.transferIn || TxKind.correction => neutral,
  };

  /// Warna nominal sebuah baris.
  ///
  /// Mengikuti Sepran: positif hijau, negatif mengikuti warna teks (tanda minus
  /// yang berbicara), netral abu-abu.
  static Color? amountOf(TxKind kind) => switch (kind) {
    TxKind.income => positive,
    TxKind.expense => null,
    TxKind.transferOut || TxKind.transferIn || TxKind.correction => neutral,
  };

  /// Ikon pilihan pada menu `+` dan pada baris daftar.
  static IconData icon(TxKind kind) => switch (kind) {
    TxKind.income => Icons.payments_outlined,
    TxKind.expense => Icons.shopping_basket_outlined,
    TxKind.transferOut || TxKind.transferIn => Icons.swap_horiz,
    TxKind.correction => Icons.tune,
  };
}

/// Nominal sebuah baris seperti yang dibaca pengguna.
///
/// Pengeluaran bertanda minus (SPEC T-11). Pemasukan dibiarkan tanpa tanda
/// plus: Sepran tidak memakainya di daftar harian, hanya di rekap.
String signedAmount(TxKind kind, int magnitude, String formatted) {
  return switch (kind) {
    TxKind.expense => '-$formatted',
    _ => formatted,
  };
}
