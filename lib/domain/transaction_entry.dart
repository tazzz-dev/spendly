import 'tx_kind.dart';

/// Satu baris pergerakan uang, sudah dibaca dari basis data.
///
/// Murni: tanpa Flutter, tanpa drift. Tugas repository adalah memetakan hasil
/// query ke bentuk ini, sehingga seluruh kalkulasi di `domain/` bisa diuji
/// tanpa membuka SQLite.
///
/// Lihat DATA-MODEL `transactions`.
class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.time,
    this.title,
    this.category,
    this.note,
    this.walletId,
    this.walletName,
    this.counterWalletId,
    this.counterWalletName,
    this.transferGroupId,
    this.debtEntryId,
  });

  final String id;
  final TxKind kind;

  /// **Bertanda**, dan tidak pernah nol:
  /// pemasukan positif, pengeluaran negatif, koreksi bisa dua-duanya.
  /// Tanda inilah satu-satunya sumber kebenaran dampak ke saldo.
  final int amount;

  /// Tanggal lokal `YYYY-MM-DD`. Lihat SPEC G-4.
  final String date;

  /// Jam `HH:MM`, opsional. Lihat SPEC G-5.
  final String? time;

  /// Judul. Kosong hanya pada kedua baris pindah saldo. Lihat DATA-MODEL RW-12.
  final String? title;

  /// Kategori. Kosong pada pindah saldo dan koreksi saldo. Lihat SPEC C-1.
  final String? category;

  /// Keterangan, opsional. Lihat SPEC T-2.
  final String? note;

  final String? walletId;

  /// Nama rekening, sudah diambil lewat join supaya daftar tidak perlu
  /// menanyakan basis data lagi per baris.
  final String? walletName;

  /// Rekening pasangan, hanya untuk kedua baris pindah saldo.
  final String? counterWalletId;
  final String? counterWalletName;

  /// Menyatukan pasangan baris pindah saldo. Lihat SPEC S-7.
  final String? transferGroupId;

  /// Terisi bila baris ini cermin dari satu entri Hutang.
  ///
  /// Baris seperti ini **tidak boleh** diubah dari daftar transaksi: sumber
  /// kebenarannya ada di catatan hutang, dan menyunting cerminnya saja membuat
  /// keduanya bercerita berbeda. Lihat SPEC H-3.
  final String? debtEntryId;

  bool get isTransfer => kind.isTransfer;

  /// Baris cermin hutang — hanya bisa diubah lewat halaman Hutang.
  bool get isDebtMirror => debtEntryId != null;

  /// Besar nominal tanpa tanda. Daftar menampilkan tandanya sendiri, sesuai
  /// keputusan tampilan, bukan dari nilai ini.
  int get magnitude => amount.abs();

  /// Baris utama di daftar: tebal dan hitam. SPEC T-11.
  ///
  /// Sepran menaruh **kategori** di sini, bukan judul. Pindah saldo dan koreksi
  /// saldo memang tidak punya kategori, jadi keduanya memakai sebutan jenisnya.
  String get primaryLabel {
    if (kind == TxKind.transferOut || kind == TxKind.transferIn) {
      return 'Pindah Saldo';
    }
    final value = category?.trim() ?? '';
    if (value.isNotEmpty) return value;
    final title = this.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    return kind.label;
  }

  /// Baris kedua di daftar: abu-abu. SPEC T-11.
  String get secondaryLabel {
    switch (kind) {
      case TxKind.transferOut:
        return counterWalletName == null ? 'Keluar' : 'Ke $counterWalletName';
      case TxKind.transferIn:
        return counterWalletName == null ? 'Masuk' : 'Dari $counterWalletName';
      case TxKind.correction:
        // Koreksi saldo tidak punya kategori; baris keduanya memakai keterangan,
        // lalu nama rekening, baru sebutan jenisnya sebagai cadangan.
        final noteValue = note?.trim() ?? '';
        if (noteValue.isNotEmpty) return noteValue;
        final walletValue = walletName?.trim() ?? '';
        if (walletValue.isNotEmpty) return walletValue;
        return 'Koreksi Saldo';
      case TxKind.income:
      case TxKind.expense:
        final value = title?.trim() ?? '';
        if (value.isNotEmpty) return value;
        return note?.trim() ?? '';
    }
  }
}
