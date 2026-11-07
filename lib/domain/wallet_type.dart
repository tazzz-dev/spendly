/// Jenis rekening.
///
/// Disimpan sebagai teks di kolom `wallets.type` (SPEC R-7). Murni, tanpa
/// ketergantungan Flutter, supaya mudah diuji.
///
/// Nilai [storageValue] ditulis ke basis data. Jangan diubah tanpa migrasi.
enum WalletType {
  cash('cash', 'Tunai'),
  bank('bank', 'Bank'),
  ewallet('ewallet', 'Dompet Digital'),
  creditCard('credit_card', 'Kartu Kredit'),
  investment('investment', 'Investasi'),
  other('other', 'Lainnya');

  const WalletType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  /// Membaca nilai dari basis data.
  ///
  /// Nilai yang tidak dikenal jatuh ke [other], bukan melempar galat. Alasannya
  /// pemulihan backup dari versi yang lebih baru: rekening dengan jenis yang
  /// belum kita kenal sebaiknya tetap tampil, bukan membuat aplikasi gagal
  /// dibuka. Lihat SPEC B-10.
  static WalletType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () => WalletType.other,
  );
}
