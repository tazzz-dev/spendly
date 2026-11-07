import 'package:flutter/material.dart';

import '../../app/palette.dart';
import '../../core/money.dart';
import '../../domain/debt_direction.dart';
import '../../domain/debt_entry.dart';
import '../../domain/debt_progress.dart';
import '../../domain/debt_record.dart';

/// Bahasa warna dan ikon hutang.
///
/// Berkas ini menyentuh Flutter, jadi sengaja diletakkan di `features/`, bukan
/// di `domain/`. Lihat RENCANA-BUILD §2. Nilainya diambil dari [AppPalette].

/// SPEC T-16: **merah = uang keluar**, dan menu dua arah SPEC H-2 memakai
/// lingkaran merah untuk Memberi.
const Color debtGiveColor = AppPalette.moneyOut;

/// SPEC T-16: **oranye = uang masuk**, dan menu dua arah SPEC H-2 memakai
/// lingkaran oranye untuk Menerima.
const Color debtReceiveColor = AppPalette.moneyIn;

/// Total Menerima di kepala halaman **khusus berwarna hijau** menurut SPEC H-1.
/// Warnanya sengaja tidak diselaraskan dengan oranye di tempat lain: dokumen
/// memintanya demikian, dan Sepran memang tidak seragam (lihat SPEC T-12).
const Color debtTotalReceiveColor = AppPalette.positive;

/// Sel ringkasan pertama di halaman detail juga berwarna hijau (SPEC H-14).
const Color debtSummaryReceiveColor = debtTotalReceiveColor;

/// Sel ringkasan kedua, panah ke bawah.
const Color debtSummaryGiveColor = debtGiveColor;

/// Sel ringkasan ketiga: sebuah ikon bulat merah muda (SPEC H-14).
const Color debtSummaryRemainingColor = AppPalette.remaining;

/// Warna sebuah arah. Dipakai menu dua arah dan tombol pilihan.
Color debtDirectionColor(DebtDirection direction) => switch (direction) {
  DebtDirection.give => debtGiveColor,
  DebtDirection.receive => debtReceiveColor,
};

/// Ikon sebuah arah. SPEC H-2: Memberi panah ganda ke bawah, Menerima panah
/// ganda ke atas.
IconData debtDirectionIcon(DebtDirection direction) => switch (direction) {
  DebtDirection.give => Icons.keyboard_double_arrow_down_rounded,
  DebtDirection.receive => Icons.keyboard_double_arrow_up_rounded,
};

/// Ikon ketiga sel ringkasan halaman detail. SPEC H-14: panah ke atas berwarna
/// hijau, panah ke bawah, dan sebuah ikon bulat merah muda.
const IconData debtSummaryReceiveIcon = Icons.arrow_upward_rounded;
const IconData debtSummaryGiveIcon = Icons.arrow_downward_rounded;
const IconData debtSummaryRemainingIcon = Icons.circle;

/// Aksi bilah atas halaman detail. SPEC H-13.
///
/// "tandai lunas" digambar sebagai orang bercentang.
const IconData debtSettleIcon = Icons.how_to_reg_outlined;
const IconData debtUnsettleIcon = Icons.how_to_reg;
const IconData debtEditIcon = Icons.edit_outlined;
const IconData debtDeleteIcon = Icons.delete_outline;

/// Nominal sebuah catatan di daftar. SPEC H-3: hanya sisi Menerima yang
/// bertanda `+`; sisi Memberi tampil biasa, dan nol tampil apa adanya.
String debtRecordAmountText(MoneyFormat money, DebtRecord record) =>
    record.net > 0
    ? '+${money.plain(record.net)}'
    : money.plain(record.magnitude);

/// Warna nominal sebuah catatan. Hanya sisi Menerima yang berwarna (SPEC H-3);
/// sisi Memberi memakai warna teks bawaan. Null berarti ikuti tema.
Color? debtRecordAmountColor(DebtRecord record) =>
    record.isReceiving ? debtTotalReceiveColor : null;

/// Nominal sebuah entri di halaman detail, selalu bertanda.
String debtEntryAmountText(MoneyFormat money, DebtEntry entry) =>
    '${entry.isReceiving ? '+' : '-'}${money.plain(entry.magnitude)}';

/// Warna nominal sebuah entri: Menerima hijau, Memberi merah.
Color debtEntryAmountColor(DebtEntry entry) =>
    entry.isReceiving ? debtSummaryReceiveColor : debtSummaryGiveColor;

/// Teks progress di kartu Target dan halaman detail.
///
/// "Terbayar Rp200.000 dari Rp5.000.000" — memakai format uang yang sedang
/// aktif supaya setelan desimal ikut berlaku (acceptance §7 butir 14).
String debtTargetPaidText(MoneyFormat money, DebtProgress progress) =>
    'Terbayar ${money.rupiah(progress.paid)} '
    'dari ${money.rupiah(progress.target)}';

/// Baris status di bawah progress bar.
///
/// Kelebihan bayar menang atas status lain (H-23), lalu utang yang dihapuskan
/// (H-24). Selain itu tampil sisa biasa.
String debtTargetStatusText(MoneyFormat money, DebtProgress progress) {
  if (progress.overpaid > 0) {
    return 'Lunas, lebih ${money.rupiah(progress.overpaid)}';
  }
  if (progress.isForgiven) {
    return 'Sisa dihapuskan ${money.rupiah(progress.remaining)}';
  }
  return 'Sisa ${money.rupiah(progress.remaining)}';
}
