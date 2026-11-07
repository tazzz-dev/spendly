// Aturan transaksi yang murni: pesan validasi dan batas panjang.
// Sengaja tanpa import, supaya berkasnya tetap ringan dan bisa dipakai di mana
// saja. Rujukan kode mengacu ke docs/SPEC.md.

/// Validasi form transaksi.
///
/// Pesan Sepran disalin apa adanya supaya paritas terjaga: pengguna yang
/// berpindah dari Sepran menemui kalimat yang sama.
class TransactionRules {
  const TransactionRules._();

  /// SPEC T-1.
  static const String requiredFields =
      'Jumlah, judul, kategori, dan rekening harus diisi.';

  /// SPEC S-2.
  static const String requiredTransfer =
      'Jumlah, rekening asal, dan rekening tujuan harus diisi.';

  /// SPEC K-2.
  static const String requiredCorrection = 'Jumlah dan rekening harus diisi.';

  /// SPEC M-3.
  static const String sameWallet = 'Rekening asal dan tujuan harus berbeda.';

  static const String amountNotPositive = 'Jumlah harus lebih besar dari nol.';

  static const String titleRequired = 'Judul harus diisi.';

  static const String categoryRequired = 'Kategori harus diisi.';

  static const String walletRequired = 'Rekening harus dipilih.';

  static const String tooLong = 'Teksnya terlalu panjang.';

  /// Batas panjang, keputusan kita. Bukan tiruan Sepran: hanya pagar supaya
  /// tata letak daftar tidak rusak. Judul dan kategori sengaja pendek karena
  /// keduanya ditampilkan di baris yang sama.
  static const int maxTitleLength = 60;
  static const int maxCategoryLength = 40;
  static const int maxNoteLength = 200;

  /// Batas nominal. Nominal disimpan sebagai bilangan bulat 64-bit, jadi batas
  /// teknisnya sekitar 9,2 × 10^18. Kita berhenti jauh di bawahnya supaya
  /// penjumlahan saldo tidak pernah mendekati luapan. Lihat SPEC §8.
  static const int maxAmount = 999999999999; // 999 miliar lebih sedikit

  /// Memeriksa jumlah. Mengembalikan pesan galat, atau null bila sah.
  static String? validateAmount(int? amount) {
    if (amount == null || amount == 0) return amountNotPositive;
    if (amount.abs() > maxAmount) {
      return 'Jumlah paling besar ${maxAmount ~/ 1000000000} miliar.';
    }
    return null;
  }

  /// Memeriksa satu field teks. [label] dipakai menyusun pesannya.
  static String? validateText(
    String? raw, {
    required String label,
    required int maxLength,
  }) {
    final value = normalize(raw);
    if (value.isEmpty) return '$label harus diisi.';
    if (value.length > maxLength) {
      return '$label paling panjang $maxLength huruf.';
    }
    return null;
  }

  /// Urutan prioritas pesan untuk form pemasukan dan pengeluaran.
  ///
  /// Sepran menampilkan **satu** kalimat untuk keempat field wajib sekaligus
  /// (SPEC T-1). Karena itu, bila ada yang kosong, pesan gabungan itulah yang
  /// dikembalikan — bukan pesan per field. Baru setelah keempatnya terisi,
  /// galat yang lebih rinci (misalnya jumlah nol) ditampilkan.
  static String? validateSimple({
    required int? amount,
    required String? title,
    required String? category,
    required String? walletId,
  }) {
    final hasTitle = normalize(title).isNotEmpty;
    final hasCategory = normalize(category).isNotEmpty;
    final hasWallet = normalize(walletId).isNotEmpty;
    final hasAmount = amount != null && amount != 0;

    if (!hasTitle || !hasCategory || !hasWallet || !hasAmount) {
      return requiredFields;
    }

    // Setelah keempatnya terisi, panjang teks baru diperiksa. Pesannya tetap
    // datang dari [validateText], sehingga tidak ada kalimat baru yang lahir di
    // layar.
    final titleError = validateText(
      title,
      label: 'Judul',
      maxLength: maxTitleLength,
    );
    if (titleError != null) return titleError;

    final categoryError = validateText(
      category,
      label: 'Kategori',
      maxLength: maxCategoryLength,
    );
    if (categoryError != null) return categoryError;

    return validateAmount(amount);
  }

  /// Keterangan bersifat opsional (SPEC T-2), jadi yang diperiksa hanya
  /// panjangnya. Mengembalikan pesan galat, atau null bila sah.
  static String? validateNote(String? raw) {
    final value = normalize(raw);
    if (value.length > maxNoteLength) {
      return 'Keterangan paling panjang $maxNoteLength huruf.';
    }
    return null;
  }

  /// SPEC S-2.
  static String? validateTransfer({
    required int? amount,
    required String? fromWalletId,
    required String? toWalletId,
  }) {
    final from = normalize(fromWalletId);
    final to = normalize(toWalletId);
    if (amount == null || amount == 0 || from.isEmpty || to.isEmpty) {
      return requiredTransfer;
    }
    if (from == to) return sameWallet;
    return validateAmount(amount);
  }

  /// Biaya admin opsional pada Pindah Saldo. Nol/kosong berarti tidak ada
  /// potongan. Nilainya tidak boleh melebihi jumlah yang dipindahkan.
  static const String adminFeeNegative = 'Biaya admin tidak boleh negatif.';
  static const String adminFeeTooLarge =
      'Biaya admin tidak boleh lebih besar dari jumlah transfer.';

  static String? validateAdminFee({
    required int? adminFee,
    required int? amount,
  }) {
    if (adminFee == null || adminFee == 0) return null;
    if (adminFee < 0) return adminFeeNegative;
    if (amount != null && adminFee > amount.abs()) return adminFeeTooLarge;
    return null;
  }

  /// SPEC K-2. Berbeda dari dua yang lain, nominal koreksi **boleh** negatif,
  /// jadi yang diperiksa hanya nol. Lihat SPEC K-5.
  static String? validateCorrection({
    required int? amount,
    required String? walletId,
  }) {
    if (amount == null || amount == 0 || normalize(walletId).isEmpty) {
      return requiredCorrection;
    }
    return validateAmount(amount);
  }

  /// Bentuk yang disimpan: tanpa spasi di ujung.
  static String normalize(String? raw) => (raw ?? '').trim();
}

/// Aturan daftar saran judul dan kategori. SPEC §5.5.
class SuggestionRules {
  const SuggestionRules._();

  /// Berapa lama saran bertahan sebelum dibersihkan otomatis.
  /// SPEC C-10: angka asli Sepran belum terbaca; kita tetapkan 30 hari.
  static const int expiryDays = 30;

  /// Berapa saran yang ditampilkan di bawah field saat pengguna mengetik.
  /// Lebih dari ini tidak muat dan justru memperlambat pemilihan.
  static const int visibleCount = 8;

  /// Berapa chip yang terlihat sebelum pengguna mengetik. Cukup untuk satu
  /// baris, sehingga form tidak langsung menampilkan seluruh daftar.
  static const int initialVisibleCount = 3;

  /// Jenis saran. Selaras dengan kolom `suggestions.type`.
  static const String titleType = 'title';
  static const String categoryType = 'category';
}
