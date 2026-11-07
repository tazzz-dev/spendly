import 'package:excel/excel.dart';

import '../../core/dates.dart';

/// Satu baris hasil pembacaan berkas ekspor Sepran.
class ImportedTransaction {
  const ImportedTransaction({
    required this.date,
    required this.amount,
    this.title,
    this.category,
    this.note,
    this.walletName,
  });

  /// `YYYY-MM-DD`.
  final String date;

  /// **Bertanda**: pemasukan positif, pengeluaran negatif. Tanda inilah yang
  /// nanti diserahkan ke [Movement][], jadi berkas tidak bisa menyelipkan
  /// nominal bertanda salah ke basis data.
  final int amount;

  final String? title;
  final String? category;
  final String? note;

  /// Nama rekening bila berkas memuatnya. Sepran menyebutnya "REKENING".
  final String? walletName;

  bool get isIncome => amount > 0;
}

/// Hasil membaca satu berkas: baris yang terbaca dan jumlah yang dilewati.
class ImportPreview {
  const ImportPreview({
    required this.rows,
    required this.skipped,
    required this.sheetName,
  });

  final List<ImportedTransaction> rows;

  /// Baris yang tidak punya tanggal atau nominal — biasanya baris judul,
  /// baris kosong, dan baris "Total".
  final int skipped;

  final String sheetName;

  int get income => rows
      .where((row) => row.amount > 0)
      .fold<int>(0, (sum, row) => sum + row.amount);

  int get expense => rows
      .where((row) => row.amount < 0)
      .fold<int>(0, (sum, row) => sum + row.amount.abs());

  /// Nama rekening yang muncul di berkas, urut abjad.
  List<String> get walletNames {
    final names = <String>{};
    for (final row in rows) {
      final name = row.walletName?.trim() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return names.toList()..sort();
  }
}

/// Membaca berkas `.xlsx` ekspor Sepran. SPEC X-3.
///
/// Enam kolom yang dikenali: TANGGAL, JUDUL, KATEGORI, PEMASUKAN, PENGELUARAN,
/// KETERANGAN — ditambah REKENING bila ada. Kolom dicari lewat **namanya**,
/// bukan urutannya, supaya berkas yang kolomnya bergeser tetap terbaca.
class SepranWorkbookParser {
  const SepranWorkbookParser();

  static const Map<String, int> _monthNumbers = {
    'jan': 1,
    'januari': 1,
    'january': 1,
    'feb': 2,
    'februari': 2,
    'february': 2,
    'mar': 3,
    'maret': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'mei': 5,
    'may': 5,
    'jun': 6,
    'juni': 6,
    'june': 6,
    'jul': 7,
    'juli': 7,
    'july': 7,
    'agu': 8,
    'agt': 8,
    'ags': 8,
    'agustus': 8,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'okt': 10,
    'oktober': 10,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'nop': 11,
    'nopember': 11,
    'november': 11,
    'des': 12,
    'desember': 12,
    'dec': 12,
    'december': 12,
  };

  static final RegExp _dayFirst = RegExp(
    r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})$',
  );
  static final RegExp _yearFirst = RegExp(
    r'^(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})$',
  );
  static final RegExp _named = RegExp(r'^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$');

  ImportPreview parse(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);

    for (final entry in excel.tables.entries) {
      final rows = entry.value.rows;
      final headerIndex = _findHeader(rows);
      if (headerIndex == null) continue;
      return _readRows(entry.key, rows, headerIndex);
    }

    throw const FormatException(
      'Berkas ini tidak punya kolom TANGGAL. Pastikan itu berkas Excel '
      'hasil ekspor Sepran.',
    );
  }

  /// Baris judul dicari sampai lima belas baris pertama, karena sebagian
  /// ekspor menaruh nama laporan di atas tabel.
  int? _findHeader(List<List<Data?>> rows) {
    final limit = rows.length < 15 ? rows.length : 15;
    for (var index = 0; index < limit; index++) {
      final cells = rows[index].map(_textOf).map(_normalize).toList();
      if (cells.contains('TANGGAL')) return index;
    }
    return null;
  }

  ImportPreview _readRows(
    String sheetName,
    List<List<Data?>> rows,
    int headerIndex,
  ) {
    final header = rows[headerIndex]
        .map(_textOf)
        .map(_normalize)
        .toList(growable: false);

    int? column(List<String> names) {
      for (final name in names) {
        final index = header.indexOf(name);
        if (index >= 0) return index;
      }
      return null;
    }

    final dateColumn = column(['TANGGAL']);
    final titleColumn = column(['JUDUL', 'KETERANGAN JUDUL']);
    final categoryColumn = column(['KATEGORI']);
    final incomeColumn = column(['PEMASUKAN', 'MASUK']);
    final expenseColumn = column(['PENGELUARAN', 'KELUAR']);
    final noteColumn = column(['KETERANGAN', 'CATATAN', 'MEMO']);
    final walletColumn = column([
      'REKENING',
      'REKENING ASAL',
      'DOMPET',
      'WALLET',
      'AKUN',
    ]);

    if (dateColumn == null) {
      throw const FormatException('Kolom TANGGAL tidak ditemukan.');
    }

    final result = <ImportedTransaction>[];
    var skipped = 0;

    for (var index = headerIndex + 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.every((cell) => _textOf(cell).isEmpty)) continue;

      String cellAt(int? column) =>
          column == null || column >= row.length ? '' : _textOf(row[column]);

      final date = _parseDate(cellAt(dateColumn));
      final income = _parseAmount(cellAt(incomeColumn));
      final expense = _parseAmount(cellAt(expenseColumn));

      final amount = income != null && income > 0
          ? income
          : (expense != null && expense > 0 ? -expense : null);

      if (date == null || amount == null) {
        skipped++;
        continue;
      }

      result.add(
        ImportedTransaction(
          date: date,
          amount: amount,
          title: _nullIfEmpty(cellAt(titleColumn)),
          category: _nullIfEmpty(cellAt(categoryColumn)),
          note: _nullIfEmpty(cellAt(noteColumn)),
          walletName: _nullIfEmpty(cellAt(walletColumn)),
        ),
      );
    }

    return ImportPreview(rows: result, skipped: skipped, sheetName: sheetName);
  }

  static String _textOf(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) {
      final text = value.value.text;
      return (text ?? value.toString()).trim();
    }
    if (value is DateCellValue) {
      return '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/${value.year}';
    }
    if (value is DateTimeCellValue) {
      return '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/${value.year}';
    }
    return value.toString().trim();
  }

  static String _normalize(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Tanggal bisa datang sebagai teks (`20/10/2026`), teks berbulan
  /// (`20 Okt 2026`), atau angka seri Excel (jumlah hari sejak 30 Desember
  /// 1899). Dibaca tanpa `intl` supaya tidak bergantung pada data bahasa yang
  /// hanya dimuat di aplikasi.
  static String? _parseDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final serial = int.tryParse(text);
    if (serial != null && serial > 20000 && serial < 80000) {
      final date = DateTime(1899, 12, 30).add(Duration(days: serial));
      return AppDate.key(date);
    }

    final yearFirst = _yearFirst.firstMatch(text);
    if (yearFirst != null) {
      return _dateKey(
        year: int.parse(yearFirst[1]!),
        month: int.parse(yearFirst[2]!),
        day: int.parse(yearFirst[3]!),
      );
    }

    final dayFirst = _dayFirst.firstMatch(text);
    if (dayFirst != null) {
      var year = int.parse(dayFirst[3]!);
      if (year < 100) year += 2000;
      return _dateKey(
        year: year,
        month: int.parse(dayFirst[2]!),
        day: int.parse(dayFirst[1]!),
      );
    }

    final named = _named.firstMatch(text);
    if (named != null) {
      final month = _monthNumbers[named[2]!.toLowerCase()];
      if (month != null) {
        return _dateKey(
          year: int.parse(named[3]!),
          month: month,
          day: int.parse(named[1]!),
        );
      }
    }

    return null;
  }

  /// Menolak tanggal yang tidak ada di kalender, seperti 31 Februari.
  static String? _dateKey({
    required int year,
    required int month,
    required int day,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return AppDate.key(date);
  }

  /// Nominal ditulis "1.234.567", "1234567", atau "1.234.567,89".
  static int? _parseAmount(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    final negative =
        text.startsWith('-') || (text.startsWith('(') && text.endsWith(')'));

    text = text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (text.isEmpty) return null;

    if (text.contains(',')) {
      // Koma selalu desimal di sini; titik adalah pemisah ribuan.
      text = text.split(',').first.replaceAll('.', '');
    } else if (text.contains('.')) {
      final parts = text.split('.');
      text = parts.last.length == 3 ? parts.join() : parts.first;
    }

    final value = int.tryParse(text);
    if (value == null || value == 0) return null;
    return negative ? -value : value;
  }
}
