import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/dates.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_entry.dart';
import '../../domain/tx_kind.dart';

/// Membangun berkas **Excel** dan **PDF** untuk rentang tanggal pilihan
/// pengguna, lalu membagikannya lewat lembar berbagi Android. SPEC §5.10.
///
/// Enam kolomnya persis yang tercatat di SPEC X-3: TANGGAL, JUDUL, KATEGORI,
/// PEMASUKAN, PENGELUARAN, KETERANGAN.
///
/// Pembentuk isi berkas dipisah dari penulis berkas ([buildExcelBytes] dan
/// [buildPdfBytes]) supaya isinya bisa diuji tanpa plugin penyimpanan Android.
class TransactionExportService {
  TransactionExportService(this._repository);

  final TransactionRepository _repository;

  static const List<String> headers = [
    'TANGGAL',
    'JUDUL',
    'KATEGORI',
    'PEMASUKAN',
    'PENGELUARAN',
    'KETERANGAN',
  ];

  static final NumberFormat _money = NumberFormat.decimalPattern('id_ID');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');

  /// Menulis berkas `.xlsx` untuk rentang tanggal.
  Future<File> writeExcel({required String from, required String until}) async {
    final entries = await _readOldestFirst(from: from, until: until);
    final file = await _targetFile(extension: 'xlsx', from: from, until: until);
    await file.writeAsBytes(buildExcelBytes(entries), flush: true);
    return file;
  }

  /// Menulis berkas `.pdf` dengan tabel yang sama dan tiga baris total.
  Future<File> writePdf({required String from, required String until}) async {
    final entries = await _readOldestFirst(from: from, until: until);
    final file = await _targetFile(extension: 'pdf', from: from, until: until);
    final bytes = await buildPdfBytes(entries, from: from, until: until);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Membuka lembar berbagi Android untuk berkas yang baru dibuat.
  Future<void> shareFile(File file, {required String subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: file.path.endsWith('.pdf') ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: subject,
        text: subject,
      ),
    );
  }

  /// Isi berkas Excel. Nominal disimpan sebagai **angka**, bukan teks, supaya
  /// bisa langsung dijumlahkan di Excel.
  static List<int> buildExcelBytes(List<TransactionEntry> entries) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Transaksi');
    final sheet = excel['Transaksi'];

    sheet.appendRow(<CellValue?>[
      for (final header in headers) TextCellValue(header),
    ]);

    for (final entry in entries) {
      final note = _noteOf(entry);
      sheet.appendRow(<CellValue?>[
        TextCellValue(_shortDate.format(AppDate.parseKey(entry.date))),
        TextCellValue(_titleOf(entry)),
        TextCellValue(_categoryOf(entry)),
        entry.amount > 0 ? IntCellValue(entry.amount) : null,
        entry.amount < 0 ? IntCellValue(-entry.amount) : null,
        note == null ? null : TextCellValue(note),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Berkas Excel tidak bisa dibentuk');
    }
    return bytes;
  }

  /// Isi berkas PDF: tabel yang sama ditambah tiga baris total.
  static Future<List<int>> buildPdfBytes(
    List<TransactionEntry> entries, {
    required String from,
    required String until,
  }) async {
    var totalIn = 0;
    var totalOut = 0;
    final data = <List<String>>[];

    for (final entry in entries) {
      if (entry.amount > 0) {
        totalIn += entry.amount;
      } else {
        totalOut += -entry.amount;
      }
      data.add([
        _shortDate.format(AppDate.parseKey(entry.date)),
        _titleOf(entry),
        _categoryOf(entry),
        entry.amount > 0 ? _money.format(entry.amount) : '',
        entry.amount < 0 ? _money.format(-entry.amount) : '',
        _noteOf(entry) ?? '',
      ]);
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            'Laporan Transaksi',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Periode ${_shortDate.format(AppDate.parseKey(from))} sampai '
            '${_shortDate.format(AppDate.parseKey(until))}',
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
            cellAlignments: {
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(2.4),
            },
          ),
          pw.SizedBox(height: 14),
          pw.Text('Total pemasukan: ${_money.format(totalIn)}'),
          pw.Text('Total pengeluaran: ${_money.format(totalOut)}'),
          pw.Text('Selisih: ${_money.format(totalIn - totalOut)}'),
        ],
      ),
    );

    return document.save();
  }

  Future<List<TransactionEntry>> _readOldestFirst({
    required String from,
    required String until,
  }) async {
    final entries = await _repository.readRange(from: from, until: until);
    return entries.reversed.toList(growable: false);
  }

  Future<File> _targetFile({
    required String extension,
    required String from,
    required String until,
  }) async {
    final directory = await getTemporaryDirectory();
    final name =
        'Transaksi_${from.replaceAll('-', '')}'
        '_${until.replaceAll('-', '')}.$extension';
    return File('${directory.path}${Platform.pathSeparator}$name');
  }

  static String _titleOf(TransactionEntry entry) {
    final title = entry.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    if (entry.kind.isTransfer) return 'Pindah Saldo';
    if (entry.kind == TxKind.correction) return 'Koreksi Saldo';
    return entry.kind.label;
  }

  static String _categoryOf(TransactionEntry entry) {
    final category = entry.category?.trim() ?? '';
    if (category.isNotEmpty) return category;
    // Pindah saldo tidak berkategori; sebutan jenisnya dipakai apa adanya,
    // bukan "Pindah Saldo Keluar/Masuk" yang membingungkan di berkas.
    if (entry.kind.isTransfer) return 'Pindah Saldo';
    return entry.kind.label;
  }

  static String? _noteOf(TransactionEntry entry) {
    final note = entry.note?.trim() ?? '';
    return note.isEmpty ? null : note;
  }
}
