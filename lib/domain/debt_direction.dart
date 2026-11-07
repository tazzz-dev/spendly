// Arah uang pada catatan hutang. Murni: tanpa Flutter, tanpa drift.
//
// SPEC H-3: arah **ditentukan oleh tanda nominal**, bukan kolom tersendiri.
// Tabel `debts` memang tidak punya kolom arah, jadi enum ini hanya menjadi
// penerjemah antara pilihan pengguna di menu dua arah (SPEC H-2) dan tanda
// angka yang akhirnya tersimpan di `debt_entries.amount`.

/// Arah uang pada satu entri atau satu catatan hutang.
///
/// Urutan [values] sengaja **Memberi lebih dulu**, karena begitulah urutan menu
/// dua arah pada SPEC H-2.
enum DebtDirection {
  /// Uang keluar dari pengguna: nominal tersimpan **negatif**. SPEC H-2.
  give('Memberi', -1),

  /// Uang masuk ke pengguna: nominal tersimpan **positif**. SPEC H-2.
  receive('Menerima', 1);

  const DebtDirection(this.label, this.sign);

  /// Sebutan Indonesia, sama dengan label menu dua arah SPEC H-2.
  final String label;

  /// Faktor tanda yang dikalikan ke besar nominal.
  final int sign;

  /// Menempelkan tanda arah ke besar nominal.
  ///
  /// Pengguna hanya mengetik besar nominalnya; arah sudah dipilih lebih dulu.
  /// Nol ditolak karena `amount` tidak pernah boleh nol (DATA-MODEL RW-8).
  int apply(int magnitude) {
    if (magnitude == 0) {
      throw ArgumentError('Nominal entri tidak boleh nol');
    }
    return magnitude.abs() * sign;
  }

  /// Arah yang dibaca dari nominal bertanda. Nol tidak punya arah.
  static DebtDirection? of(int amount) {
    if (amount > 0) return DebtDirection.receive;
    if (amount < 0) return DebtDirection.give;
    return null;
  }
}
