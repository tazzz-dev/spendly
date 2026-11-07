// Aturan rekap yang murni: setelan, batas, dan pesan validasi.
// Sengaja tanpa import, supaya ringan dan bisa dipakai di mana saja.
// Rujukan kode mengacu ke docs/SPEC.md.

/// Setelan rekap, disimpan di tabel `app_settings` (kunci-nilai).
///
/// SPEC L-7: halaman "Konfigurasi Rekap" hanya punya **dua** setelan, Tanggal
/// Mulai dan Saldo Akumulasi.
class ReportConfig {
  const ReportConfig({
    this.startDay = ReportRules.defaultStartDay,
    this.accumulateBalance = ReportRules.defaultAccumulate,
  });

  /// Hari dimulainya periode rekap. SPEC L-7b.
  final int startDay;

  /// Bila menyala, Saldo Awal dihitung dari seluruh pergerakan sebelum rentang.
  /// SPEC L-9.
  final bool accumulateBalance;

  ReportConfig copyWith({int? startDay, bool? accumulateBalance}) =>
      ReportConfig(
        startDay: startDay ?? this.startDay,
        accumulateBalance: accumulateBalance ?? this.accumulateBalance,
      );

  @override
  bool operator ==(Object other) =>
      other is ReportConfig &&
      other.startDay == startDay &&
      other.accumulateBalance == accumulateBalance;

  @override
  int get hashCode => Object.hash(startDay, accumulateBalance);

  @override
  String toString() =>
      'ReportConfig(startDay: $startDay, accumulate: $accumulateBalance)';
}

/// Aturan tetap modul Rekap.
class ReportRules {
  const ReportRules._();

  /// SPEC L-7: nilai bawaan Tanggal Mulai.
  static const int defaultStartDay = 1;

  /// Hari mulai dibatasi 1–28. Di atas 28 tidak ada di semua bulan, sehingga
  /// siklus bisa terlewat atau tumpang tindih.
  static const int minStartDay = 1;
  static const int maxStartDay = 28;

  /// SPEC L-7: Saldo Akumulasi bawaan **mati**.
  static const bool defaultAccumulate = false;

  /// Berapa kategori atau judul yang ditampilkan utuh sebelum sisanya
  /// digabung menjadi baris "Lainnya". SPEC L-4.
  static const int breakdownLimit = 7;

  /// SPEC L-4: baris pengelompokan sisa.
  static const String expenseOtherLabel = 'Pengeluaran Lainnya';
  static const String incomeOtherLabel = 'Pemasukan Lainnya';

  /// Judul atau kategori yang kosong tetap ditampilkan, dengan sebutan ini.
  static const String noCategoryLabel = 'Tanpa Kategori';
  static const String noTitleLabel = 'Tanpa Judul';

  /// Kunci setelan di tabel `app_settings`.
  static const String settingStartDay = 'report.start_day';
  static const String settingAccumulate = 'report.accumulate_balance';

  /// SPEC L-8: nama rekap kustom.
  static const int maxCustomNameLength = 40;
  static const String customNameRequired = 'Nama rekap harus diisi.';
  static const String customNameTooLong = 'Nama rekap terlalu panjang.';

  /// SPEC L-8: tanggal akhir tidak boleh lebih kecil dari tanggal awal.
  static const String customRangeInvalid =
      'Tanggal akhir tidak boleh lebih kecil dari tanggal awal.';

  /// Memeriksa isi form rekap kustom. Mengembalikan pesan galat, atau null.
  static String? validateCustom({
    required String? name,
    required String? start,
    required String? end,
  }) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return customNameRequired;
    if (trimmed.length > maxCustomNameLength) return customNameTooLong;
    if ((start ?? '').isEmpty || (end ?? '').isEmpty) {
      return customRangeInvalid;
    }
    // Tanggal `YYYY-MM-DD` sudah terurut secara leksikografis.
    if (end!.compareTo(start!) < 0) return customRangeInvalid;
    return null;
  }
}
