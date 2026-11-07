// Aturan hutang piutang yang murni. Rujukan kode: docs/SPEC.md §5.6 dan
// docs/DATA-MODEL.md bagian `debts` serta `debt_entries`.
//
// Berkas ini sengaja tanpa import apa pun — tidak Flutter, tidak drift — supaya
// seluruh aturannya bisa diuji tanpa membuka SQLite.

/// Teks dan validasi form hutang.
///
/// Sebagian pesan Sepran disalin apa adanya supaya paritas terjaga.
class DebtRules {
  const DebtRules._();

  /// SPEC H-5 dan DATA-MODEL `debts.note`: keterangan kosong ditampilkan
  /// sebagai ini, baik di daftar catatan maupun di daftar entri.
  static const String noNote = 'Tanpa keterangan';

  /// SPEC H-9: anak judul bilah atas halaman detail.
  static const String unsettledStatus = 'Belum lunas';
  static const String settledStatus = 'Lunas';

  /// H-19: badge kecil pada baris Normal yang punya target.
  static const String targetBadge = 'Target';

  /// Konfirmasi hapus catatan. Kalimat pertama disalin dari SPEC H-7; kalimat
  /// kedua ditambahkan oleh H-26 supaya pengguna tahu cicilan, transaksi
  /// cerminnya, dan saldo rekening ikut kembali.
  static const String deleteConfirmation =
      'Semua data transaksi pada halaman ini akan dihapus, termasuk seluruh '
      'cicilan dan transaksi cerminnya, dan saldo rekening akan kembali. '
      'Apakah Anda yakin?';

  /// H-21: peringatan saat pembayaran Target disimpan tanpa rekening.
  static const String walletRequiredForPayment =
      'Tanpa rekening, saldo tidak berkurang';

  /// H-17: target harus berupa pokok yang lebih besar dari nol.
  static const String targetNotPositive = 'Target harus lebih besar dari nol.';

  /// H-27: "Sudah dibayar" tidak boleh negatif.
  static const String paidOpeningNegative =
      'Sudah dibayar tidak boleh negatif.';

  /// Pembayaran hanya masuk akal untuk catatan bertarget.
  static const String targetMissing = 'Catatan ini tidak punya target.';

  /// Pesan saat nama atau jumlah belum diisi. Terinspirasi T-1 yang memakai
  /// satu kalimat untuk seluruh field wajib.
  static const String requiredFields = 'Nama dan jumlah harus diisi.';

  static const String nameRequired = 'Nama harus diisi.';

  static const String amountNotPositive = 'Jumlah harus lebih besar dari nol.';

  /// Batas panjang, keputusan kita. Bukan tiruan Sepran: hanya pagar supaya
  /// tata letak daftar tidak rusak.
  static const int maxPartyNameLength = 60;
  static const int maxPhoneLength = 25;
  static const int maxNoteLength = 200;

  /// Batas nominal. Sama dengan batas transaksi supaya penjumlahan saldo tidak
  /// pernah mendekati luapan bilangan bulat 64-bit. Lihat SPEC §8.
  static const int maxAmount = 999999999999; // 999 miliar lebih sedikit

  /// Memeriksa form catatan baru: Nama dan Jumlah wajib, sisanya opsional.
  ///
  /// [amount] adalah besar nominal bertanda yang sudah lewat
  /// [DebtDirection.apply]; yang diperiksa hanya "tidak nol" dan batasnya,
  /// sesuai DATA-MODEL RW-8 (tidak ada batas antara pokok dan cicilan).
  static String? validate({
    required String? partyName,
    required int? amount,
    String? phone,
    String? note,
  }) {
    final name = normalize(partyName);
    final hasAmount = amount != null && amount != 0;

    if (name.isEmpty || !hasAmount) return requiredFields;
    if (name.length > maxPartyNameLength) {
      return 'Nama paling panjang $maxPartyNameLength huruf.';
    }
    if (normalize(phone).length > maxPhoneLength) {
      return 'Nomor HP paling panjang $maxPhoneLength angka.';
    }
    if (normalize(note).length > maxNoteLength) {
      return 'Keterangan paling panjang $maxNoteLength huruf.';
    }
    return validateAmount(amount);
  }

  /// Memeriksa penyuntingan catatan. Menyunting catatan tidak menyentuh entri,
  /// jadi hanya Nama yang wajib.
  static String? validateRecord({
    required String? partyName,
    String? phone,
    String? note,
  }) {
    final name = normalize(partyName);
    if (name.isEmpty) return nameRequired;
    if (name.length > maxPartyNameLength) {
      return 'Nama paling panjang $maxPartyNameLength huruf.';
    }
    if (normalize(phone).length > maxPhoneLength) {
      return 'Nomor HP paling panjang $maxPhoneLength angka.';
    }
    if (normalize(note).length > maxNoteLength) {
      return 'Keterangan paling panjang $maxNoteLength huruf.';
    }
    return null;
  }

  /// Memeriksa form target. H-17 dan H-27.
  ///
  /// [paidOpening] sengaja **boleh melebihi** target: kelebihan bayar
  /// diizinkan (H-23), jadi pengguna yang sudah membayar lebih banyak tetap
  /// bisa mencatat keadaannya.
  static String? validateTarget({
    required String? partyName,
    required int? targetAmount,
    int? paidOpening,
    String? phone,
    String? note,
  }) {
    final name = normalize(partyName);
    if (name.isEmpty) return nameRequired;
    if (name.length > maxPartyNameLength) {
      return 'Nama paling panjang $maxPartyNameLength huruf.';
    }
    if (targetAmount == null || targetAmount <= 0) return targetNotPositive;
    if (targetAmount > maxAmount) {
      return 'Target paling besar ${maxAmount ~/ 1000000000} miliar.';
    }

    final opening = paidOpening ?? 0;
    if (opening < 0) return paidOpeningNegative;
    if (opening > maxAmount) {
      return 'Sudah dibayar paling besar ${maxAmount ~/ 1000000000} miliar.';
    }

    if (normalize(phone).length > maxPhoneLength) {
      return 'Nomor HP paling panjang $maxPhoneLength angka.';
    }
    if (normalize(note).length > maxNoteLength) {
      return 'Keterangan paling panjang $maxNoteLength huruf.';
    }
    return null;
  }

  /// Peringatan sebelum menyimpan target yang lebih kecil dari yang sudah
  /// dibayar. H-25.
  static const String targetBelowPaidWarning =
      'Target baru lebih kecil dari yang sudah dibayar. Setelah disimpan, '
      'catatan akan tampil lunas dengan kelebihan bayar. Lanjutkan?';

  /// Memeriksa nominal entri: bertanda apa pun boleh, termasuk nilai yang
  /// melebihi arah mana pun, asalkan bukan nol. SPEC H-11 dan RW-8.
  static String? validateAmount(int? amount) {
    if (amount == null || amount == 0) return amountNotPositive;
    if (amount.abs() > maxAmount) {
      return 'Jumlah paling besar ${maxAmount ~/ 1000000000} miliar.';
    }
    return null;
  }

  /// Bentuk yang disimpan: tanpa spasi di ujung.
  static String normalize(String? raw) => (raw ?? '').trim();

  /// Teks opsional: kosong menjadi null supaya kolomnya benar-benar kosong,
  /// bukan berisi spasi.
  static String? blankToNull(String? raw) {
    final value = normalize(raw);
    return value.isEmpty ? null : value;
  }
}

/// Pelanggaran aturan pembayaran target yang pesannya siap ditampilkan.
///
/// Repository melempar ini alih-alih `ArgumentError` mentah supaya lapisan UI
/// cukup menampilkan [message] (USULAN-HUTANG-TARGET §5).
class DebtPaymentException implements Exception {
  const DebtPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
