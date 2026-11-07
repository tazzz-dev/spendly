/// Total mutasi satu hari, hasil pengerutan di SQL.
///
/// Satu baris per hari. Inilah bahan bakar seluruh modul Rekap: kartu bulanan,
/// tab Realtime, rekap kustom, dan Tren Aset semuanya dihitung dari daftar ini
/// di `domain/`, sehingga rumusnya bisa diuji tanpa basis data.
///
/// Pindah saldo sengaja tidak punya kolom di sini. Ia keluar dari satu rekening
/// dan masuk ke rekening lain, jadi jumlahnya nol; menghitungnya akan membuat
/// rekap menggelembung tanpa sebab. SPEC M-2, L-10, dan INV-6.
class DailyTotals {
  const DailyTotals({
    required this.date,
    this.income = 0,
    this.expense = 0,
    this.correction = 0,
    this.debt = 0,
  });

  /// Tanggal lokal `YYYY-MM-DD`. SPEC G-4.
  final String date;

  /// Seluruh pemasukan hari itu. Selalu ≥ 0.
  final int income;

  /// Seluruh pengeluaran hari itu sebagai besar mutlak. Selalu ≥ 0.
  final int expense;

  /// Koreksi saldo hari itu, **bertanda** (boleh menambah atau mengurangi).
  /// SPEC K-5.
  final int correction;

  /// Mutasi hutang piutang hari itu, **bertanda**. Positif berarti menerima.
  /// SPEC H-3 dan L-1b.
  final int debt;

  /// Perubahan saldo gabungan seluruh rekening pada hari ini.
  int get movement => income - expense + correction + debt;

  bool get isEmpty =>
      income == 0 && expense == 0 && correction == 0 && debt == 0;

  @override
  String toString() =>
      'DailyTotals($date, +$income, -$expense, ±$correction, debt $debt)';
}
