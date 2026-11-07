import 'scanned_transaction.dart';
import 'transaction_entry.dart';
import 'tx_kind.dart';

/// Mencocokkan baris hasil scan dengan transaksi yang **sudah tercatat**.
///
/// Sinyal utamanya tanggal, arah uang, dan nominal — bukan judul. Judul hasil
/// OCR sering berbeda dengan judul yang diketik pengguna ("Shopee" versus
/// "Payung"), sedangkan nominal dan tanggal jarang berubah. Setiap transaksi
/// lama hanya boleh dipakai sekali, supaya dua pembelian berbeda dengan nominal
/// sama pada hari yang sama tidak dianggap duplikat seluruhnya.
///
/// Bila rekening baris scan diketahui, transaksi lama hanya dianggap cocok bila
/// berada di rekening yang sama. Tanpa batas ini, pembayaran Rp10.000 dari DANA
/// akan dianggap duplikat dari pembayaran Rp10.000 di GoPay pada hari yang sama.
class DuplicateTransactionFinder {
  const DuplicateTransactionFinder();

  /// Mengembalikan peta `id baris scan -> transaksi lama` yang cocok.
  ///
  /// [scanned] boleh berisi nominal 0 (sedang diketik); baris seperti itu
  /// dilewati. Koreksi saldo tidak dianggap duplikat karena bukan pergerakan
  /// biasa; pindah saldo tetap dihitung karena uangnya sudah tercatat.
  ///
  /// [walletByScanId] memetakan id baris scan ke rekening yang dipilih. Nilai
  /// null berarti rekening belum diketahui, sehingga pencocokan hanya memakai
  /// tanggal, arah, dan nominal.
  Map<String, TransactionEntry> find({
    required Iterable<ScannedTransaction> scanned,
    required Iterable<TransactionEntry> existing,
    Map<String, String?> walletByScanId = const {},
  }) {
    final pool = [
      for (final entry in existing)
        if (entry.kind != TxKind.correction) entry,
    ];
    final used = <int>{};
    final matches = <String, TransactionEntry>{};

    for (final item in scanned) {
      if (item.amount <= 0) continue;
      final wantsIncome = item.type == ScannedTransactionType.income;
      final walletId = walletByScanId[item.id];

      int? bestIndex;
      var bestScore = -1;
      for (var index = 0; index < pool.length; index++) {
        if (used.contains(index)) continue;
        final entry = pool[index];
        if (entry.date != item.date) continue;
        if (walletId != null && entry.walletId != walletId) continue;
        final entryIncome =
            entry.kind == TxKind.income || entry.kind == TxKind.transferIn;
        if (entryIncome != wantsIncome) continue;
        if (entry.amount.abs() != item.amount) continue;

        final score = _score(item, entry);
        if (score > bestScore) {
          bestScore = score;
          bestIndex = index;
        }
      }

      if (bestIndex == null) continue;
      used.add(bestIndex);
      matches[item.id] = pool[bestIndex];
    }

    return matches;
  }

  /// Cocokkan jam dan judul bila keduanya tersedia; kalau tidak, tetap cocok
  /// dengan skor dasar. Nilai hanya dipakai untuk memilih kandidat terbaik,
  /// bukan untuk menolak, karena OCR jam bisa terbaca salah.
  int _score(ScannedTransaction item, TransactionEntry entry) {
    var score = 1;
    if (item.time != null && entry.time != null && item.time == entry.time) {
      score += 2;
    }
    if (_normalizeTitle(item.title) == _normalizeTitle(entry.title)) {
      score += 2;
    }
    return score;
  }

  static String _normalizeTitle(String? value) =>
      (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
