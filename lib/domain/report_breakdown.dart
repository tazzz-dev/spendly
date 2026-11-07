import 'report_rules.dart';
import 'tx_kind.dart';

/// Satu baris pemasukan atau pengeluaran, cukup untuk menyusun rincian rekap.
///
/// Sengaja lebih ringan daripada `TransactionEntry`: rincian hanya butuh jenis,
/// judul, kategori, dan nominal.
class ReportLine {
  const ReportLine({
    required this.kind,
    required this.amount,
    this.title,
    this.category,
  });

  final TxKind kind;

  /// Bertanda, mengikuti nilai yang tersimpan.
  final int amount;

  final String? title;
  final String? category;
}

/// Satu baris rincian: label, total, dan porsinya terhadap keseluruhan.
class BreakdownItem {
  const BreakdownItem({
    required this.label,
    required this.amount,
    required this.share,
  });

  final String label;

  /// Total nominal, selalu ≥ 0.
  final int amount;

  /// Porsi terhadap keseluruhan, 0.0–1.0.
  final double share;

  @override
  String toString() => 'BreakdownItem($label, $amount, $share)';
}

/// Penyusun rincian rekap: per kategori atau per judul. SPEC L-2 dan L-3.
class ReportBreakdown {
  const ReportBreakdown._();

  /// Mengelompokkan [lines] menurut kategori (bawaan) atau judul
  /// ([byTitle]), dari yang terbesar ke terkecil.
  ///
  /// Setelah [limit] baris, sisanya digabung menjadi satu baris
  /// "Pengeluaran Lainnya" atau "Pemasukan Lainnya". SPEC L-4.
  static List<BreakdownItem> build({
    required Iterable<ReportLine> lines,
    required TxKind kind,
    bool byTitle = false,
    int limit = ReportRules.breakdownLimit,
  }) {
    final totals = <String, int>{};
    var grand = 0;

    for (final line in lines) {
      if (line.kind != kind) continue;
      final label = labelOf(line, byTitle: byTitle);
      final value = line.amount.abs();
      totals.update(label, (old) => old + value, ifAbsent: () => value);
      grand += value;
    }

    if (grand == 0) return const [];

    final entries = totals.entries.toList()
      ..sort((a, b) {
        final byAmount = b.value.compareTo(a.value);
        // Urutan abjad sebagai pemecah seri supaya hasilnya stabil, tidak
        // berubah-ubah setiap kali rekap dibuka.
        return byAmount != 0 ? byAmount : a.key.compareTo(b.key);
      });

    final items = <BreakdownItem>[];
    var rest = 0;

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      if (index < limit) {
        items.add(
          BreakdownItem(
            label: entry.key,
            amount: entry.value,
            share: entry.value / grand,
          ),
        );
      } else {
        rest += entry.value;
      }
    }

    if (rest > 0) {
      items.add(
        BreakdownItem(
          label: kind == TxKind.income
              ? ReportRules.incomeOtherLabel
              : ReportRules.expenseOtherLabel,
          amount: rest,
          share: rest / grand,
        ),
      );
    }

    return items;
  }

  /// Label kelompok sebuah baris, dengan sebutan cadangan bila kosong.
  static String labelOf(ReportLine line, {required bool byTitle}) {
    final raw = (byTitle ? line.title : line.category)?.trim() ?? '';
    if (raw.isNotEmpty) return raw;
    return byTitle ? ReportRules.noTitleLabel : ReportRules.noCategoryLabel;
  }
}
