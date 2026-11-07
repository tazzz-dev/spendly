import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../core/money.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/tx_kind.dart';

/// Bahasa warna uang, dipakai seragam di seluruh aplikasi.
///
/// SPEC T-16: **oranye = uang masuk**, **merah = uang keluar**, **abu-abu =
/// netral** (pindah saldo dan koreksi saldo). Nilainya kini hanya ada di
/// [AppPalette]; di sini tinggal nama peran supaya layar mudah dibaca.
const Color txIncomeColor = AppPalette.moneyIn;
const Color txExpenseColor = AppPalette.moneyOut;
const Color txNeutralColor = AppPalette.neutral;

/// Warna kolom Pemasukan pada kartu ringkasan harian.
///
/// SPEC T-12 menyebut pemasukan berwarna **hijau** di kartu ini, sementara
/// SPEC T-16 menyebut oranye untuk uang masuk di tempat lain. Keduanya benar:
/// Sepran memakai oranye pada penanda jenis dan hijau pada nominal. Kita
/// mengikuti keduanya apa adanya.
const Color txSummaryIncomeColor = AppPalette.positive;

/// Warna nominal sebuah baris.
///
/// Mengikuti Sepran: nominal positif hijau, nominal negatif **tidak** dimerahi
/// (warna teks biasa, tanda minusnya yang berbicara), pindah saldo dan koreksi
/// abu-abu. `null` berarti ikut warna teks tema.
Color? txAmountColor(TxKind kind) => switch (kind) {
  TxKind.income => txSummaryIncomeColor,
  TxKind.expense => null,
  TxKind.transferOut || TxKind.transferIn => txNeutralColor,
  TxKind.correction => txNeutralColor,
};

/// Ikon besar untuk tiap jenis, dipakai di tombol pilihan.
///
/// Arah panahnya mengikuti Sepran: menerima uang digambar dengan panah ke atas
/// (lihat SPEC H-2), jadi pemasukan memakai panah ke atas juga.
IconData txKindIcon(TxKind kind) => switch (kind) {
  TxKind.income => Icons.arrow_upward_rounded,
  TxKind.expense => Icons.arrow_downward_rounded,
  TxKind.transferOut || TxKind.transferIn => Icons.swap_horiz_rounded,
  TxKind.correction => Icons.tune_rounded,
};

/// Nominal sebuah baris, sudah bertanda.
///
/// SPEC T-11 menyebut nominal pengeluaran bertanda minus. Kami memakai aturan
/// yang lebih sederhana: **selalu** bertanda, mengikuti nilai `amount` yang
/// tersimpan. Jadi pemasukan `+50.000`, pengeluaran `-18.000`, pindah saldo
/// `-250.000` di sisi asal dan `+250.000` di sisi tujuan.
String txAmountText(MoneyFormat money, TransactionEntry entry) {
  final sign = entry.amount < 0 ? '-' : '+';
  return '$sign${money.plain(entry.magnitude)}';
}
