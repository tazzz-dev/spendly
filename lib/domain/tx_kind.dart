// Jenis pergerakan uang. Murni: tanpa Flutter, tanpa drift, tanpa basis data.
// Sepran menyimpannya di empat tabel terpisah; kita satu tabel dengan kolom
// `kind`. Lihat SPEC §4 dan DATA-MODEL D2, D3.

/// Kelima jenis pergerakan uang yang mungkin.
///
/// Nilai [storageValue] masuk ke kolom `kind` dan **tidak boleh berubah** —
/// mengubahnya berarti semua baris lama tidak terbaca lagi.
enum TxKind {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran'),
  transferOut('transfer_out', 'Pindah Saldo Keluar'),
  transferIn('transfer_in', 'Pindah Saldo Masuk'),
  correction('correction', 'Koreksi Saldo');

  const TxKind(this.storageValue, this.label);

  /// Nilai yang disimpan di kolom `kind`.
  final String storageValue;

  /// Sebutan Indonesia untuk pengguna.
  final String label;

  /// Membaca nilai dari basis data.
  ///
  /// Melempar bila tidak dikenal. Sengaja tidak mengembalikan nilai cadangan:
  /// baris yang rusak harus ketahuan, bukan diam-diam dianggap pemasukan lalu
  /// merusak saldo.
  static TxKind fromStorage(String value) => values.firstWhere(
    (kind) => kind.storageValue == value,
    orElse: () =>
        throw ArgumentError('Jenis pergerakan tidak dikenal: "$value"'),
  );

  /// Pindah saldo selalu **dua baris** yang terhubung `transfer_group_id`,
  /// bukan satu baris. Lihat SPEC S-7 dan DATA-MODEL D4.
  bool get isTransfer => this == transferOut || this == transferIn;

  /// Apakah jenis ini ikut dihitung sebagai pemasukan atau pengeluaran.
  ///
  /// Pindah saldo dan koreksi saldo **tidak pernah** ikut, supaya rekap tidak
  /// menggelembung hanya karena uang dipindah antar rekening.
  /// Lihat SPEC M-2, L-10, dan INV-6.
  bool get countsInReport => this == income || this == expense;
}
