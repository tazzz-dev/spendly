import 'debt_direction.dart';
import 'debt_progress.dart';
import 'debt_rules.dart';
import 'debt_target_direction.dart';

/// Satu catatan hutang, sudah dibaca dari basis data.
///
/// Seluruh nominalnya **dihitung**, bukan disimpan: tabel `debts` tidak punya
/// kolom jumlah maupun kolom arah (SPEC H-3 dan H-4). [net] adalah jumlah
/// seluruh entri bertanda milik catatan ini, persis hasil query pada
/// docs/DATA-MODEL.md bagian `debts`.
///
/// Murni: tanpa Flutter, tanpa drift.
class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.partyName,
    required this.date,
    required this.net,
    this.phone,
    this.note,
    this.isSettled = false,
    this.targetAmount,
    this.targetDirection,
    this.paidOpening = 0,
    this.paidEntries = 0,
  });

  final String id;

  /// Nama orang atau keperluan. Tampil sebagai judul baris dan judul bilah atas
  /// halaman detail. SPEC H-5.
  final String partyName;

  /// Nomor HP, opsional.
  final String? phone;

  /// Tanggal catatan `YYYY-MM-DD`. Lihat SPEC G-4.
  final String date;

  /// Keterangan catatan, opsional.
  final String? note;

  /// SPEC H-9: hanya tampil di halaman detail, sebagai anak judul.
  final bool isSettled;

  /// Jumlah seluruh entri bertanda. Positif berarti Menerima, negatif Memberi.
  /// Nol berarti catatan ini belum punya entri, atau entri dua arahnya
  /// berimbang. Lihat SPEC H-3, H-4, dan INV-10.
  final int net;

  /// Pokok/target catatan. `NULL` atau nol berarti catatan biasa yang hanya
  /// tampil di tab Normal. Target adalah metadata, bukan pergerakan uang.
  final int? targetAmount;

  /// Arah pokok target. Harus null bila [targetAmount] null (H-17).
  final DebtTargetDirection? targetDirection;

  /// Jumlah yang sudah dibayar sebelum aplikasi dipakai (H-27). Bukan entri dan
  /// tidak pernah menyentuh saldo maupun Rekap.
  final int paidOpening;

  /// Jumlah besar entri yang searah pembayaran target, dihitung di repository.
  /// Entri arah berlawanan tidak ikut (H-22).
  final int paidEntries;

  /// Besar nominal tanpa tanda.
  int get magnitude => net.abs();

  /// Apakah catatan ini punya target yang sah dan karenanya muncul di tab
  /// Target (H-20). Target nol/negatif tidak dianggap bertarget.
  bool get hasTarget => (targetAmount ?? 0) > 0;

  /// Progress target, atau null bila catatan ini tidak bertarget.
  DebtProgress? get progress {
    final target = targetAmount;
    final direction = targetDirection;
    if (target == null || direction == null || target <= 0) return null;

    return DebtProgress(
      target: target,
      paidOpening: paidOpening,
      paidEntries: paidEntries,
      manualSettled: isSettled,
    );
  }

  /// Arah catatan, ditentukan tanda [net]. Nol tidak punya arah.
  DebtDirection? get direction => DebtDirection.of(net);

  /// SPEC H-3: hanya sisi Menerima yang ditampilkan bertanda `+` dan berwarna.
  bool get isReceiving => net > 0;

  /// Anak judul bilah atas halaman detail. SPEC H-9.
  ///
  /// Status Lunas otomatis muncul saat target sudah terbayar penuh (H-24),
  /// jadi catatan bertarget yang sisa nol tidak lagi tampil "Belum lunas".
  String get statusLabel => isSettled || (progress?.isSettled ?? false)
      ? DebtRules.settledStatus
      : DebtRules.unsettledStatus;

  /// Keterangan untuk ditampilkan. Kosong menjadi "Tanpa keterangan".
  /// SPEC H-5 dan DATA-MODEL `debts.note`.
  String get noteLabel {
    final value = note?.trim() ?? '';
    return value.isEmpty ? DebtRules.noNote : value;
  }

  /// Apakah catatan ini cocok dengan kata kunci kotak Pencarian (SPEC H-8).
  ///
  /// Nama, nomor HP, dan keterangan ikut dicari; pencocokan tidak peka huruf
  /// besar-kecil. Kata kunci kosong berarti semuanya cocok.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return partyName.toLowerCase().contains(needle) ||
        (phone ?? '').toLowerCase().contains(needle) ||
        (note ?? '').toLowerCase().contains(needle);
  }
}

/// Menyaring daftar catatan untuk kotak Pencarian halaman Hutang. SPEC H-8.
List<DebtRecord> filterDebtRecords(
  Iterable<DebtRecord> records,
  String query,
) => records.where((record) => record.matches(query)).toList(growable: false);
