import 'debt_entry.dart';
import 'debt_record.dart';
import 'debt_target_direction.dart';

/// Dua total di kepala halaman Hutang. SPEC H-1.
///
/// Keduanya sengaja dipisah dan **tidak pernah** disatukan menjadi satu selisih:
/// mencampur uang yang akan diterima dengan uang yang harus dibayar akan
/// menyembunyikan posisi sebenarnya. Rumusnya persis query di
/// docs/DATA-MODEL.md bagian `debts`.
///
/// Murni: tanpa Flutter, tanpa drift.
class DebtTotals {
  const DebtTotals({this.receiving = 0, this.giving = 0});

  /// Menjumlahkan seluruh catatan non-terhapus.
  ///
  /// Catatan bertanda nol (belum ada entri, atau entri dua arahnya berimbang)
  /// tidak menyumbang ke sisi mana pun.
  factory DebtTotals.of(Iterable<DebtRecord> records) {
    var receiving = 0;
    var giving = 0;

    for (final record in records) {
      if (record.net > 0) {
        receiving += record.net;
      } else {
        giving += -record.net;
      }
    }

    return DebtTotals(receiving: receiving, giving: giving);
  }

  /// Total Menerima, selalu ≥ 0. Ditampilkan **bertanda `+` dan berwarna
  /// hijau** menurut SPEC H-1.
  final int receiving;

  /// Total Memberi, selalu ≥ 0, ditampilkan tanpa tanda (SPEC H-1).
  final int giving;

  /// Berapa catatan yang ikut dihitung. Bukan bagian tampilan, hanya penolong
  /// pengujian dan keadaan kosong.
  bool get isEmpty => receiving == 0 && giving == 0;
}

/// Dua total sisa di kepala tab **Target**. H-20.
///
/// Sama seperti [DebtTotals], keduanya tidak pernah dijumlahkan. Yang dihitung
/// hanya catatan yang punya target dan **belum lunas**; catatan Lunas tetap
/// tampil di daftar, tetapi tidak lagi menambah kewajiban.
class DebtTargetTotals {
  const DebtTargetTotals({this.owe = 0, this.owed = 0});

  factory DebtTargetTotals.of(Iterable<DebtRecord> records) {
    var owe = 0;
    var owed = 0;

    for (final record in records) {
      final progress = record.progress;
      if (progress == null || progress.isSettled) continue;

      switch (record.targetDirection) {
        case DebtTargetDirection.owe:
          owe += progress.remaining;
        case DebtTargetDirection.owed:
          owed += progress.remaining;
        case null:
          break;
      }
    }

    return DebtTargetTotals(owe: owe, owed: owed);
  }

  /// Total sisa utang: catatan arah `owe` yang belum lunas. Selalu ≥ 0.
  final int owe;

  /// Total sisa piutang: catatan arah `owed` yang belum lunas. Selalu ≥ 0.
  final int owed;

  bool get isEmpty => owe == 0 && owed == 0;
}

/// Catatan yang tampil di tab Target, sudah diurutkan menurut H-29.
///
/// Urutan: yang belum lunas lebih dulu, lalu sisa terbesar, lalu tanggal
/// terbaru. Catatan Lunas tetap ikut, hanya diletakkan di bawah.
List<DebtRecord> sortDebtTargets(Iterable<DebtRecord> records) {
  final list = records.where((record) => record.progress != null).toList();

  list.sort((a, b) {
    final progressA = a.progress!;
    final progressB = b.progress!;

    if (progressA.isSettled != progressB.isSettled) {
      return progressA.isSettled ? 1 : -1;
    }

    final byRemaining = progressB.remaining.compareTo(progressA.remaining);
    if (byRemaining != 0) return byRemaining;

    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;

    return b.id.compareTo(a.id);
  });

  return list;
}

/// Tiga sel ringkasan di halaman detail catatan. SPEC H-14.
///
/// Sel pertama dan kedua adalah Menerima dan Memberi, sama seperti kepala
/// halaman daftar. Sel ketiga adalah **sisa**, yaitu besar mutlak selisih kedua
/// arah — inilah penafsiran yang dijelaskan di laporan akhir. SPEC H-14
/// menandainya `[?]` karena pada contoh pengamatan salah satu sisinya nol.
class DebtSummary {
  const DebtSummary({this.receiving = 0, this.giving = 0});

  /// Menjumlahkan entri bertanda satu catatan.
  factory DebtSummary.of(Iterable<DebtEntry> entries) {
    var receiving = 0;
    var giving = 0;

    for (final entry in entries) {
      if (entry.amount > 0) {
        receiving += entry.amount;
      } else {
        giving += -entry.amount;
      }
    }

    return DebtSummary(receiving: receiving, giving: giving);
  }

  /// Sel pertama: seluruh entri Menerima. Selalu ≥ 0.
  final int receiving;

  /// Sel kedua: seluruh entri Memberi, sebagai besar mutlak. Selalu ≥ 0.
  final int giving;

  /// Selisih bertanda: positif berarti lebih banyak menerima.
  int get net => receiving - giving;

  /// Sel ketiga: sisa, sebagai besar mutlak selisih kedua arah.
  ///
  /// SPEC H-14 belum dapat memastikan arti sel ini. Pada contoh pengamatan
  /// nilainya 0 · 200.000 · 200.000, dengan sisi Menerima nol. Kalau sel ketiga
  /// adalah besar mutlak selisih, angkanya memang 200.000 — cocok. Tafsir itu
  /// yang dipakai, dan seluruh perhitungannya dikumpulkan di getter ini supaya
  /// perbaikan nanti cukup satu baris.
  int get remaining => net.abs();

  bool get isEmpty => receiving == 0 && giving == 0;
}
