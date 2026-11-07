import 'wallet_type.dart';

/// Sebuah rekening beserta saldonya. Murni, tanpa ketergantungan Flutter maupun
/// drift, sehingga mudah diuji.
///
/// Lihat SPEC INV-1 dan INV-2.
class WalletBalance {
  const WalletBalance({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.balance,
    this.iconKey,
    this.color,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final WalletType type;

  /// Saldo yang diisi pengguna saat rekening dibuat.
  ///
  /// Setelah rekening punya riwayat, layar Ubah Rekening tidak menulis kolom
  /// ini; perubahan saldo dicatat sebagai Koreksi Saldo. SPEC K-6.
  final int openingBalance;

  /// Saldo awal ditambah seluruh pergerakan bertanda.
  ///
  /// **Dihitung, bukan disimpan.** Tidak ada kolom saldo di tabel `wallets`,
  /// jadi tidak ada dua sumber kebenaran yang bisa saling menyimpang.
  /// Lihat DATA-MODEL D1.
  final int balance;

  /// Kunci ikon pilihan pengguna. Null berarti pakai ikon bawaan [type].
  final String? iconKey;

  /// Warna ARGB pilihan pengguna.
  final int? color;

  /// SPEC G-8: rekening default tidak bisa dihapus.
  final bool isDefault;
}
