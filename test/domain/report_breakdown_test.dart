import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/report_breakdown.dart';
import 'package:pencatatan_keuangan/domain/report_rules.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';

ReportLine _expense(int amount, {String? category, String? title}) =>
    ReportLine(
      kind: TxKind.expense,
      amount: -amount,
      category: category,
      title: title,
    );

ReportLine _income(int amount, {String? category, String? title}) => ReportLine(
  kind: TxKind.income,
  amount: amount,
  category: category,
  title: title,
);

void main() {
  group('per kategori', () {
    test('dikelompokkan dan diurutkan dari yang terbesar', () {
      final items = ReportBreakdown.build(
        lines: [
          _expense(10000, category: 'Makanan'),
          _expense(50000, category: 'Transportasi'),
          _expense(25000, category: 'Makanan'),
        ],
        kind: TxKind.expense,
      );

      expect(items.map((item) => item.label).toList(), [
        'Transportasi',
        'Makanan',
      ]);
      expect(items.first.amount, 50000);
      expect(items.last.amount, 35000);
    });

    test('hanya jenis yang diminta ikut dihitung', () {
      final items = ReportBreakdown.build(
        lines: [
          _expense(10000, category: 'Makanan'),
          _income(90000, category: 'Gaji'),
        ],
        kind: TxKind.expense,
      );

      expect(items, hasLength(1));
      expect(items.single.label, 'Makanan');
    });

    test('kategori kosong memakai sebutan cadangan', () {
      final items = ReportBreakdown.build(
        lines: [_expense(10000)],
        kind: TxKind.expense,
      );

      expect(items.single.label, ReportRules.noCategoryLabel);
    });

    test('porsi seluruh baris berjumlah satu', () {
      final items = ReportBreakdown.build(
        lines: [
          _expense(30000, category: 'A'),
          _expense(70000, category: 'B'),
        ],
        kind: TxKind.expense,
      );

      final total = items.fold<double>(0, (sum, item) => sum + item.share);
      expect(total, closeTo(1.0, 1e-9));
      expect(items.first.share, closeTo(0.7, 1e-9));
    });

    test('tidak ada baris berarti tidak ada rincian', () {
      expect(
        ReportBreakdown.build(lines: const [], kind: TxKind.expense),
        isEmpty,
      );
    });
  });

  group('per judul', () {
    test('mengelompokkan menurut judul, bukan kategori', () {
      final items = ReportBreakdown.build(
        lines: [
          _expense(10000, category: 'Makanan', title: 'Kopi'),
          _expense(20000, category: 'Makanan', title: 'Nasi'),
          _expense(15000, category: 'Makanan', title: 'Kopi'),
        ],
        kind: TxKind.expense,
        byTitle: true,
      );

      expect(items.map((item) => item.label).toList(), ['Kopi', 'Nasi']);
      expect(items.first.amount, 25000);
    });

    test('judul kosong memakai sebutan cadangan', () {
      final items = ReportBreakdown.build(
        lines: [_expense(10000, category: 'Makanan')],
        kind: TxKind.expense,
        byTitle: true,
      );

      expect(items.single.label, ReportRules.noTitleLabel);
    });
  });

  group('baris Lainnya (SPEC L-4)', () {
    test('sisanya digabung setelah batas', () {
      final lines = [
        for (var index = 0; index < 10; index++)
          _expense((index + 1) * 1000, category: 'Kategori$index'),
      ];

      final items = ReportBreakdown.build(
        lines: lines,
        kind: TxKind.expense,
        limit: 3,
      );

      expect(items, hasLength(4));
      expect(items.last.label, ReportRules.expenseOtherLabel);
      // Tiga terbesar: 10.000, 9.000, 8.000 → sisanya 7.000+...+1.000.
      expect(items.last.amount, 28000);
    });

    test('pemasukan memakai sebutan Lainnya sendiri', () {
      final lines = [
        for (var index = 0; index < 5; index++)
          _income((index + 1) * 1000, category: 'Sumber$index'),
      ];

      final items = ReportBreakdown.build(
        lines: lines,
        kind: TxKind.income,
        limit: 2,
      );

      expect(items.last.label, ReportRules.incomeOtherLabel);
    });

    test('tidak ada baris Lainnya bila semuanya muat', () {
      final items = ReportBreakdown.build(
        lines: [
          _expense(10000, category: 'A'),
          _expense(5000, category: 'B'),
        ],
        kind: TxKind.expense,
        limit: 5,
      );

      expect(items.any((item) => item.label.contains('Lainnya')), isFalse);
    });
  });

  group('urutan stabil', () {
    test('nilai sama diurutkan abjad supaya tidak berubah-ubah', () {
      final first = ReportBreakdown.build(
        lines: [
          _expense(10000, category: 'Beta'),
          _expense(10000, category: 'Alfa'),
        ],
        kind: TxKind.expense,
      );

      expect(first.map((item) => item.label).toList(), ['Alfa', 'Beta']);
    });
  });
}
