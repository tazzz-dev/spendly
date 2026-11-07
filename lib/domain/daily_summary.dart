import 'transaction_entry.dart';
import 'tx_kind.dart';

/// Ringkasan satu hari: kartu tiga kolom pada SPEC T-12.
class DailySummary {
  const DailySummary({this.income = 0, this.expense = 0});

  /// Menghitung ringkasan dari baris-baris satu hari.
  ///
  /// Hanya `income` dan `expense` yang dihitung. Pindah saldo dan koreksi saldo
  /// dilewati, sesuai SPEC M-2, L-10, dan INV-6 — kalau tidak, memindahkan uang
  /// antar rekening akan tampak seperti pengeluaran besar.
  factory DailySummary.of(Iterable<TransactionEntry> entries) {
    var income = 0;
    var expense = 0;

    for (final entry in entries) {
      switch (entry.kind) {
        case TxKind.income:
          income += entry.amount;
        case TxKind.expense:
          // `amount` pengeluaran negatif; disimpan sebagai besar mutlaknya.
          expense += entry.amount.abs();
        case TxKind.transferOut:
        case TxKind.transferIn:
        case TxKind.correction:
          break;
      }
    }

    return DailySummary(income: income, expense: expense);
  }

  /// Seluruh pemasukan hari itu. Selalu ≥ 0.
  final int income;

  /// Seluruh pengeluaran hari itu, sebagai besar mutlak. Selalu ≥ 0.
  final int expense;

  /// Selisih pemasukan dan pengeluaran, **selalu tanpa tanda minus**.
  ///
  /// SPEC T-17 semula `[?]`: pada satu-satunya hari yang terekam di Sepran
  /// (pemasukan 0, pengeluaran 158.000) kolom Selisih tertulis **158.000 tanpa
  /// tanda minus**, padahal pemasukan dikurangi pengeluaran bernilai −158.000.
  ///
  /// **Keputusan gelombang ini:** Selisih ditampilkan sebagai besar mutlak
  /// (`|pemasukan − pengeluaran|`), karena begitulah satu-satunya angka yang
  /// terverifikasi dari tangkapan layar. Arah uangnya sudah terbaca dari kolom
  /// Pemasukan dan Pengeluaran di sebelahnya, jadi angkanya tidak perlu
  /// bertanda. Bila verifikasi berikutnya membuktikan sebaliknya, perubahan
  /// cukup di getter ini. Nilai bertanda tetap tersedia lewat [netDifference]
  /// untuk pemakaian lain. Lihat juga docs/VERIFIKASI.md.
  int get difference => netDifference.abs();

  /// Selisih bertanda: pemasukan dikurangi pengeluaran. Bisa negatif.
  int get netDifference => income - expense;

  bool get isEmpty => income == 0 && expense == 0;
}
