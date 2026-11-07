import 'tx_kind.dart';

/// Satu baris pergerakan yang siap ditulis ke tabel `transactions`.
///
/// [amount] sudah **bertanda**. Tanda dihitung hanya di berkas ini, sesuai
/// DATA-MODEL RW-5: tidak ada penulisan langsung dari antarmuka, supaya tidak
/// mungkin ada layar yang menulis pemasukan bernilai negatif.
class TxDraft {
  const TxDraft({
    required this.kind,
    required this.walletId,
    required this.amount,
    required this.date,
    this.title,
    this.category,
    this.note,
    this.time,
    this.counterWalletId,
    this.transferGroupId,
  });

  final TxKind kind;
  final String walletId;

  /// Bertanda dan tidak pernah nol.
  final int amount;

  final String date;
  final String? title;
  final String? category;
  final String? note;
  final String? time;
  final String? counterWalletId;
  final String? transferGroupId;
}

/// Dua baris yang bersama-sama membentuk satu Pindah Saldo.
///
/// SPEC S-7 dan INV-4. Namanya `outgoing`/`incoming`, bukan `out`/`in`, karena
/// `in` adalah kata kunci Dart.
class TransferDraft {
  const TransferDraft({required this.outgoing, required this.incoming});

  final TxDraft outgoing;
  final TxDraft incoming;

  List<TxDraft> get rows => [outgoing, incoming];

  /// INV-4: dampak pada kedua sisi sama besar dan berlawanan tanda.
  bool get isBalanced => outgoing.amount == -incoming.amount;
}

/// Satu-satunya tempat yang menentukan tanda sebuah pergerakan.
///
/// Semua antarmuka memanggil fungsi di sini. Rumus saldo di SPEC §4 karena itu
/// cukup berupa satu penjumlahan `amount`, tanpa `CASE WHEN` per jenis.
class Movement {
  const Movement._();

  /// Pemasukan: nominal bertanda **positif**. SPEC T-4.
  static TxDraft income({
    required int amount,
    required String walletId,
    required String title,
    required String category,
    required String date,
    String? note,
    String? time,
  }) {
    return TxDraft(
      kind: TxKind.income,
      walletId: walletId,
      amount: _magnitude(amount),
      date: date,
      title: title,
      category: category,
      note: note,
      time: time,
    );
  }

  /// Pengeluaran: nominal bertanda **negatif**.
  ///
  /// Sepran menyimpan nominalnya tetap positif dan menaruh tandanya di kolom
  /// `jenisTransaksi`. Kita menaruh tanda itu di `amount`, sehingga rumus saldo
  /// tidak perlu tahu jenisnya. Lihat SPEC T-4 dan DATA-MODEL D2.
  static TxDraft expense({
    required int amount,
    required String walletId,
    required String title,
    required String category,
    required String date,
    String? note,
    String? time,
  }) {
    return TxDraft(
      kind: TxKind.expense,
      walletId: walletId,
      amount: -_magnitude(amount),
      date: date,
      title: title,
      category: category,
      note: note,
      time: time,
    );
  }

  /// Pindah saldo: dua baris berlawanan tanda dengan grup yang sama.
  ///
  /// Rekening asal dan tujuan harus berbeda (SPEC M-3). Kedua baris **tidak**
  /// punya judul maupun kategori, karena form Pindah Saldo memang tidak punya
  /// kedua field itu. Lihat SPEC S-9 dan DATA-MODEL RW-12.
  static TransferDraft transfer({
    required int amount,
    required String fromWalletId,
    required String toWalletId,
    required String groupId,
    required String date,
    String? note,
    String? time,
  }) {
    if (fromWalletId == toWalletId) {
      throw ArgumentError('Rekening asal dan tujuan harus berbeda');
    }
    final value = _magnitude(amount);

    return TransferDraft(
      outgoing: TxDraft(
        kind: TxKind.transferOut,
        walletId: fromWalletId,
        counterWalletId: toWalletId,
        transferGroupId: groupId,
        amount: -value,
        date: date,
        note: note,
        time: time,
      ),
      incoming: TxDraft(
        kind: TxKind.transferIn,
        walletId: toWalletId,
        counterWalletId: fromWalletId,
        transferGroupId: groupId,
        amount: value,
        date: date,
        note: note,
        time: time,
      ),
    );
  }

  /// Biaya admin Pindah Saldo: pengeluaran tersendiri di rekening asal.
  ///
  /// Baris ini memakai `transfer_group_id` yang sama dengan pasangan pindah
  /// saldo supaya ikut terhapus/dipulihkan bersama, tetapi tetap dihitung
  /// sebagai pengeluaran biasa di rekap. Dengan begitu saldo rekening asal
  /// berkurang sebesar jumlah transfer **ditambah** biaya admin, tanpa perlu
  /// kolom baru di tabel transaksi.
  static TxDraft adminFee({
    required int amount,
    required String walletId,
    required String groupId,
    required String date,
    String? time,
  }) {
    return TxDraft(
      kind: TxKind.expense,
      walletId: walletId,
      amount: -_magnitude(amount),
      date: date,
      title: 'Biaya admin',
      category: 'Biaya Admin',
      note: 'Biaya admin Pindah Saldo',
      time: time,
      transferGroupId: groupId,
    );
  }

  /// Koreksi saldo: nominal boleh positif maupun negatif. SPEC K-5.
  ///
  /// Judulnya diisi otomatis karena formnya tidak punya field judul
  /// (SPEC K-2), sementara judul wajib untuk jenis ini. Lihat DATA-MODEL RW-12.
  static TxDraft correction({
    required int amount,
    required String walletId,
    required String date,
    String? note,
    String? time,
  }) {
    if (amount == 0) {
      throw ArgumentError('Nilai koreksi tidak boleh nol');
    }
    return TxDraft(
      kind: TxKind.correction,
      walletId: walletId,
      amount: amount,
      date: date,
      title: 'Koreksi Saldo',
      note: note,
      time: time,
    );
  }

  /// Menolak nol dan membuang tanda, supaya pemanggil boleh mengirim nilai
  /// bertanda apa pun tanpa mengubah artinya. INV-9 dan DATA-MODEL D3.
  static int _magnitude(int amount) {
    if (amount == 0) {
      throw ArgumentError('Nominal tidak boleh nol');
    }
    return amount.abs();
  }
}
