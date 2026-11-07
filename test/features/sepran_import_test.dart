import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/features/transactions/sepran_import.dart';

/// Membentuk berkas `.xlsx` di memori, seperti berkas ekspor Sepran.
List<int> xlsx(List<List<CellValue?>> rows, {String sheet = 'Transaksi'}) {
  final excel = Excel.createExcel();
  excel.rename('Sheet1', sheet);
  final table = excel[sheet];
  for (final row in rows) {
    table.appendRow(row);
  }
  return excel.save()!;
}

List<CellValue?> textRow(List<String?> cells) => cells
    .map<CellValue?>((cell) => cell == null ? null : TextCellValue(cell))
    .toList();

List<CellValue?> header() => textRow(const [
  'TANGGAL',
  'JUDUL',
  'KATEGORI',
  'PEMASUKAN',
  'PENGELUARAN',
  'KETERANGAN',
  'REKENING',
]);

String? cellText(Data? cell) {
  final value = cell?.value;
  if (value == null) return null;
  if (value is TextCellValue) return value.value.text;
  return value.toString();
}

void main() {
  const parser = SepranWorkbookParser();

  test('membaca kolom Sepran menjadi nominal bertanda', () {
    final preview = parser.parse(
      xlsx([
        header(),
        textRow([
          '20/10/2026',
          'Gaji',
          'Gaji',
          '5.000.000',
          '',
          'gaji bulan ini',
          'BCA',
        ]),
        textRow([
          '21/10/2026',
          'Makan',
          'Makanan',
          '',
          '25.000',
          'ayam',
          'Tunai',
        ]),
      ]),
    );

    expect(preview.rows, hasLength(2));
    final income = preview.rows.first;
    expect(income.date, '2026-10-20');
    expect(income.amount, 5000000);
    expect(income.title, 'Gaji');
    expect(income.category, 'Gaji');
    expect(income.note, 'gaji bulan ini');
    expect(income.walletName, 'BCA');
    expect(income.isIncome, isTrue);

    final expense = preview.rows.last;
    expect(expense.amount, -25000);
    expect(expense.isIncome, isFalse);

    expect(preview.income, 5000000);
    expect(preview.expense, 25000);
    expect(preview.walletNames, ['BCA', 'Tunai']);
    expect(preview.skipped, 0);
  });

  test('kolom dicari lewat nama, bukan urutan', () {
    final preview = parser.parse(
      xlsx([
        textRow([
          'PENGELUARAN',
          'TANGGAL',
          'KETERANGAN',
          'JUDUL',
          'KATEGORI',
          'PEMASUKAN',
        ]),
        textRow(['10.000', '19/10/2026', 'kopi', 'Ngaso', 'Minuman', '']),
      ]),
    );

    expect(preview.rows.single.amount, -10000);
    expect(preview.rows.single.title, 'Ngaso');
    expect(preview.rows.single.note, 'kopi');
    expect(preview.rows.single.date, '2026-10-19');
  });

  test('judul laporan di atas tabel tidak mengacaukan pembacaan', () {
    final preview = parser.parse(
      xlsx([
        textRow(['Laporan Transaksi']),
        textRow([null]),
        header(),
        textRow(['19/10/2026', 'Makan', 'Makanan', '', '15.000', '', '']),
      ]),
    );

    expect(preview.rows.single.amount, -15000);
    expect(preview.sheetName, 'Transaksi');
  });

  test('nominal berupa angka Excel tetap terbaca', () {
    final preview = parser.parse(
      xlsx([
        header(),
        [
          TextCellValue('19/10/2026'),
          TextCellValue('Makan'),
          TextCellValue('Makanan'),
          null,
          IntCellValue(25000),
          null,
        ],
      ]),
    );

    expect(preview.rows.single.amount, -25000);
  });

  test('tanggal ISO dan seri Excel dikenali', () {
    final preview = parser.parse(
      xlsx([
        header(),
        textRow(['2026-10-19', 'A', 'B', '1.000', '', '', '']),
        textRow(['46300', 'C', 'D', '2.000', '', '', '']),
      ]),
    );

    final dates = preview.rows.map((row) => row.date).toList();
    expect(dates.first, '2026-10-19');
    // 46300 hari sesudah 30 Desember 1899.
    expect(dates.last, '2026-10-05');
  });

  test('baris tanpa tanggal atau nominal dilewati dan dihitung', () {
    final preview = parser.parse(
      xlsx([
        header(),
        textRow(['TOTAL', '', '', '10.000', '5.000', '', '']),
        textRow(['19/10/2026', '', '', '0', '', '', '']),
        textRow([null]),
        textRow(['19/10/2026', 'Makan', 'Makanan', '', '10.000', '', '']),
      ]),
    );

    expect(preview.rows, hasLength(1));
    // Baris TOTAL dan nominal nol dilewati. Baris yang benar-benar kosong
    // tidak dihitung: itu hanya jarak, bukan data yang gagal dibaca.
    expect(preview.skipped, 2);
  });

  test('pemisah ribuan dan desimal dibaca sebagai rupiah utuh', () {
    final amounts = <String, int>{
      'Rp 1.234.567': 1234567,
      '1234567': 1234567,
      '1.234.567,89': 1234567,
      ' 50.000 ': 50000,
    };

    for (final entry in amounts.entries) {
      final preview = parser.parse(
        xlsx([
          header(),
          textRow(['19/10/2026', 'A', 'B', entry.key, '', '', '']),
        ]),
      );
      expect(preview.rows.single.amount, entry.value, reason: entry.key);
    }
  });

  test('berkas tanpa kolom TANGGAL ditolak dengan pesan yang jelas', () {
    expect(
      () => parser.parse(
        xlsx([
          textRow(['NAMA', 'NILAI']),
          textRow(['A', '1']),
        ]),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('TANGGAL'),
        ),
      ),
    );
  });

  test('nama rekening kosong tidak dianggap rekening', () {
    final preview = parser.parse(
      xlsx([
        header(),
        textRow(['19/10/2026', 'A', 'B', '1.000', '', '', '']),
        textRow(['19/10/2026', 'C', 'D', '1.000', '', '', '  ']),
      ]),
    );

    expect(preview.walletNames, isEmpty);
    expect(preview.rows.first.walletName, isNull);
  });
}
