/// Arah uang pada hasil scan. Sengaja hanya dua, karena gambar mutasi tidak
/// membawa konsep pindah saldo atau koreksi saldo.
enum ScannedTransactionType {
  expense('Pengeluaran'),
  income('Pemasukan');

  const ScannedTransactionType(this.label);

  final String label;
}

/// Satu baris transaksi hasil OCR yang sudah diurai, sebelum dikonfirmasi
/// pengguna.
///
/// Semua field bisa diubah di layar tinjauan; kelas ini karena itu menyediakan
/// [copyWith], bukan setter.
class ScannedTransaction {
  const ScannedTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.title,
    required this.category,
    this.time,
    this.rawText = '',
    this.dateGuessed = false,
  });

  /// Pengenal sementara di dalam satu sesi scan. Bukan ID basis data.
  final String id;

  /// Kunci `YYYY-MM-DD`, sama seperti tabel `transactions`.
  final String date;

  /// `HH:MM` bila terbaca.
  final String? time;

  /// Nominal selalu positif. Tandanya ditentukan [type].
  final int amount;

  final ScannedTransactionType type;

  /// Judul/merchant hasil bacaan.
  final String title;

  /// Perkiraan kategori. Boleh diganti pengguna.
  final String category;

  /// Teks asli yang menjadi sumber baris ini, disimpan untuk membantu pengguna
  /// memeriksa bila hasil urai terasa aneh.
  final String rawText;

  /// `true` bila tanggal tidak ditemukan di gambar dan kami memakai tanggal
  /// hari ini. Layar tinjauan menandainya agar pengguna memeriksa.
  final bool dateGuessed;

  ScannedTransaction copyWith({
    String? date,
    String? time,
    int? amount,
    ScannedTransactionType? type,
    String? title,
    String? category,
    bool? dateGuessed,
    bool clearTime = false,
  }) {
    return ScannedTransaction(
      id: id,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      rawText: rawText,
      dateGuessed: dateGuessed ?? this.dateGuessed,
    );
  }
}
