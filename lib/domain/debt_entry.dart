import 'debt_direction.dart';
import 'debt_rules.dart';

/// Satu entri bertanda pada sebuah catatan hutang.
///
/// Nama aslinya di Sepran: `hutang_detail`. `amount` positif berarti menerima,
/// negatif berarti memberi, dan tidak pernah nol (DATA-MODEL `debt_entries`).
///
/// Murni: tanpa Flutter, tanpa drift.
class DebtEntry {
  const DebtEntry({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.time,
    this.walletId,
    this.walletName,
    this.note,
  });

  final String id;
  final String debtId;

  /// **Bertanda**, dan tidak pernah nol. Positif = Menerima, negatif = Memberi.
  /// Inilah satu-satunya sumber kebenaran arah entri. Lihat SPEC H-3.
  final int amount;

  /// Tanggal entri `YYYY-MM-DD`. Lihat SPEC G-4.
  final String date;

  /// Jam `HH:MM`, opsional. Lihat SPEC G-5.
  final String? time;

  /// Rekening yang ikut terpengaruh. **Opsional**: bila kosong, entri ini tidak
  /// memengaruhi saldo mana pun. SPEC M-4.
  final String? walletId;

  /// Nama rekening, sudah diambil lewat join supaya daftar tidak perlu
  /// menanyakan basis data lagi per baris.
  final String? walletName;

  /// Keterangan, opsional.
  final String? note;

  /// Arah entri, dibaca dari tanda [amount].
  DebtDirection get direction {
    final value = DebtDirection.of(amount);
    if (value == null) {
      // Tidak mungkin terjadi kalau aturan tulis dipatuhi: `amount` entri tidak
      // pernah nol. Kalau sampai terjadi, lebih baik ketahuan daripada
      // diam-diam dianggap Menerima.
      throw StateError('Entri hutang tidak boleh bernilai nol');
    }
    return value;
  }

  /// Besar nominal tanpa tanda.
  int get magnitude => amount.abs();

  bool get isReceiving => amount > 0;

  /// Keterangan untuk ditampilkan; kosong menjadi "Tanpa keterangan".
  String get noteLabel {
    final value = note?.trim() ?? '';
    return value.isEmpty ? DebtRules.noNote : value;
  }
}
