import 'package:flutter/material.dart';

/// Satu-satunya sumber warna aplikasi.
///
/// Sebelumnya warna tersebar di empat berkas, dan dua di antaranya memakai
/// nilai berbeda untuk hal yang sama: oranye uang masuk ada yang `#F57C00` dan
/// ada yang `#FB8C00`, merah uang keluar ada `#D32F2F` dan `#E53935`. Berkas ini
/// menyatukannya supaya tidak melenceng lagi.
///
/// Aturannya mengikuti Sepran, dilihat langsung dari tangkapan layarnya:
///
/// - **oranye = uang masuk**, **merah = uang keluar**, **abu-abu = netral**
///   untuk *penanda jenis* pergerakan. SPEC T-16 dan H-2.
/// - **hijau teduh = nominal positif** (Pemasukan, Menerima). SPEC T-12, H-1,
///   dan H-3. Nilainya disalin dari layar Sepran, bukan dikira-kira.
/// - **nominal negatif tidak dimerahi.** Di daftar Sepran, pengeluaran dan
///   "Memberi" berwarna teks biasa; tanda minusnya yang berbicara. Merah hanya
///   dipakai pada tombol arah dan ikon jenis.
/// - **warna aksen mengikuti tema** (biru, pink, ungu, gelap) dan dipakai untuk
///   bilah atas, tombol tambah, serta tab yang sedang dipilih. SPEC G-6, ST-4.
class AppPalette {
  const AppPalette._();

  // --- Penanda jenis pergerakan. SPEC T-16 ---

  /// Uang masuk: oranye.
  static const Color moneyIn = Color(0xFFFB8C00);

  /// Uang keluar: merah.
  static const Color moneyOut = Color(0xFFE53935);

  /// Pindah saldo dan koreksi saldo: abu-abu netral.
  static const Color neutral = Color(0xFF757575);

  // --- Nominal. SPEC T-12, H-1, H-3 ---

  /// Nominal positif: hijau teduh, sama dengan Sepran.
  static const Color positive = Color(0xFF4BA894);

  /// Sel ringkasan "sisa" di halaman detail hutang. SPEC H-14.
  static const Color remaining = Color(0xFFEC407A);

  // --- Teks, garis, dan latar ---

  /// Teks utama, terang.
  static const Color textPrimaryLight = Color(0xFF666666);

  /// Teks kedua, terang.
  static const Color textSecondaryLight = Color(0xFFAAAAAA);

  /// Teks utama, gelap.
  static const Color textPrimaryDark = Color(0xFFE6E6E6);

  /// Teks kedua, gelap.
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Garis rambut, terang.
  static const Color hairlineLight = Color(0xFFECECEC);

  /// Garis rambut, gelap.
  static const Color hairlineDark = Color(0xFF2A2A2A);

  /// Latar halaman, terang.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Latar halaman, gelap.
  static const Color surfaceDark = Color(0xFF121212);

  /// Ikon/teks di atas warna aksen yang terang.
  static const Color onAccent = Color(0xFFFFFFFF);

  // --- Grafik rincian. SPEC L-2 dan L-11 ---

  /// Warna bagian grafik, dipakai berurutan dan berulang bila bagiannya lebih
  /// banyak. Biru aksen lebih dulu supaya grafik terasa satu keluarga dengan
  /// antarmuka, lalu hijau, oranye, dan merah sebagai warna uang.
  static const List<Color> chart = [
    Color(0xFF2196F3),
    Color(0xFF4BA894),
    Color(0xFFFB8C00),
    Color(0xFFE53935),
    Color(0xFF7B1FA2),
    Color(0xFF00897B),
    Color(0xFF3949AB),
    Color(0xFF6D4C41),
    Color(0xFFD81B60),
    Color(0xFF546E7A),
  ];
}
