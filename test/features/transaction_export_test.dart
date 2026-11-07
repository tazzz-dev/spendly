import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/features/transactions/transaction_export.dart';

String? cellText(Data? cell) {
  final value = cell?.value;
  if (value == null) return null;
  if (value is TextCellValue) return value.value.text;
  return value.toString();
}

void main() {
  final entries = [
    const TransactionEntry(
      id: '1',
      kind: TxKind.income,
      amount: 150000,
      date: '2026-10-01',
      title: 'Gaji',
      category: 'Gaji',
      note: 'gaji Oktober',
    ),
    const TransactionEntry(
      id: '2',
      kind: TxKind.expense,
      amount: -25000,
      date: '2026-10-02',
      title: 'Makan',
      category: 'Makanan',
    ),
    const TransactionEntry(
      id: '3',
      kind: TxKind.transferOut,
      amount: -100000,
      date: '2026-10-03',
      counterWalletName: 'BCA',
    ),
    const TransactionEntry(
      id: '4',
      kind: TxKind.correction,
      amount: 500,
      date: '2026-10-03',
      note: 'Pembulatan',
    ),
  ];

  test('berkas Excel berisi enam kolom SPEC X-3 dan nominal bertanda', () {
    final bytes = TransactionExportService.buildExcelBytes(entries);
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Transaksi']!;

    expect(sheet.rows.first.map(cellText).toList(), [
      'TANGGAL',
      'JUDUL',
      'KATEGORI',
      'PEMASUKAN',
      'PENGELUARAN',
      'KETERANGAN',
    ]);
    expect(sheet.rows, hasLength(entries.length + 1));

    // Pemasukan: nominal di kolom PEMASUKAN, kolom PENGELUARAN kosong.
    final income = sheet.rows[1];
    expect(cellText(income[0]), '01/10/2026');
    expect(cellText(income[1]), 'Gaji');
    expect(cellText(income[2]), 'Gaji');
    expect(income[3]?.value, isA<IntCellValue>());
    expect((income[3]!.value as IntCellValue).value, 150000);
    expect(income[4]?.value, isNull);
    expect(cellText(income[5]), 'gaji Oktober');

    // Pengeluaran: nominal tanpa tanda di kolom PENGELUARAN.
    final expense = sheet.rows[2];
    expect(expense[3]?.value, isNull);
    expect((expense[4]!.value as IntCellValue).value, 25000);
    expect(cellText(expense[5]), isNull);

    // Pindah saldo tidak punya judul maupun kategori: dipakai sebutan jenisnya.
    final transfer = sheet.rows[3];
    expect(cellText(transfer[1]), 'Pindah Saldo');
    expect(cellText(transfer[2]), 'Pindah Saldo');
    expect((transfer[4]!.value as IntCellValue).value, 100000);

    // Koreksi memakai sebutan jenisnya sebagai judul, keterangan tetap asli.
    final correction = sheet.rows[4];
    expect(cellText(correction[1]), 'Koreksi Saldo');
    expect(cellText(correction[5]), 'Pembulatan');
  });

  test('berkas PDF terbentuk dan berawalan tanda PDF', () async {
    final bytes = await TransactionExportService.buildPdfBytes(
      entries,
      from: '2026-10-01',
      until: '2026-10-03',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('rentang kosong tetap menghasilkan berkas yang bisa dibuka', () async {
    final excel = Excel.decodeBytes(
      TransactionExportService.buildExcelBytes([]),
    );
    expect(excel.tables['Transaksi']!.rows, hasLength(1));

    final pdf = await TransactionExportService.buildPdfBytes(
      const [],
      from: '2026-10-01',
      until: '2026-10-31',
    );
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });
}
