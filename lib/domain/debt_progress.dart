/// Perhitungan progress sebuah target hutang/piutang.
///
/// Objek murni: tanpa Flutter, tanpa drift. Rumusnya sengaja **tidak** memakai
/// `DebtSummary.remaining`, karena getter lama itu memakai `net.abs()` dan
/// kelebihan bayar justru akan tampil sebagai sisa.
///
/// Lihat USULAN-HUTANG-TARGET §4.2.
class DebtProgress {
  const DebtProgress({
    required this.target,
    this.paidOpening = 0,
    this.paidEntries = 0,
    this.manualSettled = false,
  });

  /// Pokok/target yang harus dibayar. Selalu ≥ 0 pada data yang sah.
  final int target;

  /// Jumlah yang sudah dibayar sebelum aplikasi dipakai (H-27).
  final int paidOpening;

  /// Jumlah besar entri yang arahnya sejalan dengan pembayaran target.
  ///
  /// Entri arah berlawanan (mis. pinjam tambahan) tidak dihitung di sini.
  final int paidEntries;

  /// Flag "Lunas" manual, dipakai untuk utang yang dihapuskan (H-24).
  final bool manualSettled;

  /// Target sah: lebih besar dari nol.
  bool get isTargeted => target > 0;

  /// Total yang sudah dibayar, termasuk titik awal.
  int get paid => paidOpening + paidEntries;

  /// Sisa yang masih harus dibayar, tidak pernah negatif.
  int get remaining {
    if (!isTargeted) return 0;
    final value = target - paid;
    return value > 0 ? value : 0;
  }

  /// Kelebihan bayar, tidak pernah negatif. H-23.
  int get overpaid {
    if (!isTargeted) return 0;
    final value = paid - target;
    return value > 0 ? value : 0;
  }

  /// Bagian progress 0..1 untuk progress bar.
  double get fraction {
    // Target nol/negatif diperlakukan sebagai "tanpa target", bukan sebagai
    // pembagian dengan nol.
    if (!isTargeted) return 0;
    return (paid / target).clamp(0.0, 1.0).toDouble();
  }

  /// Lunas otomatis saat sisa nol, atau karena ditandai manual. H-24.
  bool get isSettled => manualSettled || (isTargeted && remaining == 0);

  /// Utang dihapuskan: ditandai lunas padahal masih ada sisa.
  bool get isForgiven => manualSettled && isTargeted && remaining > 0;
}
