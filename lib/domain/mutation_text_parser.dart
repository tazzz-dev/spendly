import 'category_guesser.dart';
import 'scanned_transaction.dart';
import 'tx_rules.dart';

/// Mengurai teks hasil OCR (tangkapan layar mutasi bank/dompet digital)
/// menjadi daftar transaksi yang bisa ditinjau pengguna.
///
/// Aturannya heuristik dan sengaja hidup di `domain/`: tidak menyentuh Flutter,
/// tidak memanggil jaringan, dan bisa diuji cepat dengan teks sungguhan. Tidak
/// ada klaim bahwa hasilnya sempurna; layar tinjauan justru ada karena hasil
/// OCR selalu perlu diperiksa manusia.
class MutationTextParser {
  const MutationTextParser();

  /// Pagar supaya satu gambar panjang tidak menghasilkan ratusan ribu baris di
  /// memori.
  static const int maxItems = 200;

  static const Map<String, int> _months = {
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
    'november': 11,
    'des': 12,
    'desember': 12,
    'dec': 12,
    'december': 12,
  };

  static final RegExp _isoDate = RegExp(
    r'\b(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})\b',
  );
  static final RegExp _shortDate = RegExp(
    r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
  );
  static final RegExp _namedDate = RegExp(
    r'\b(\d{1,2})\s+([A-Za-z]{3,9})\.?\s*(\d{2,4})?\b',
  );
  static final RegExp _time = RegExp(
    r'(?<![\d.,])([01]?\d|2[0-3])[:.]([0-5]\d)(?![\d])',
  );

  static final RegExp _prefixedAmount = RegExp(
    r'(?:rp\.?\s*|idr\s*)([+-])?\s*(\d[\d.,]*)',
    caseSensitive: false,
  );
  static final RegExp _signedAmount = RegExp(
    r'(?<![\d.,])([+-])\s*(?:rp\.?\s*)?(\d[\d.,]*)',
  );
  static final RegExp _groupedAmount = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?)(?![\d])',
  );
  static final RegExp _plainAmount = RegExp(r'(?<![\d.,-])(\d{4,9})(?![\d.,])');

  static final RegExp _incomeWords = RegExp(
    r'\b(masuk|diterima|menerima|terima|top\s*up|topup|isi saldo|refund|'
    r'cashback|gaji|salary|bonus|thr|pendapatan|income|credit|cr|'
    r'transfer masuk|dana masuk|uang masuk)\b',
    caseSensitive: false,
  );
  static final RegExp _expenseWords = RegExp(
    r'\b(keluar|dibayar|pembayaran|bayar|transfer ke|kirim ke|penarikan|'
    r'tarik tunai|tarik|pembelian|belanja|debit|db|biaya|potongan|tagihan|'
    r'pengeluaran|expense)\b',
    caseSensitive: false,
  );

  /// Baris yang jelas bukan transaksi: saldo berjalan, judul kolom, dan
  /// keterangan status.
  static final RegExp _metadata = RegExp(
    r'^(saldo|total saldo|saldo akhir|saldo tersedia|saldo saat ini|'
    r'total|subtotal|tanggal|tgl|waktu|jam|nominal|jumlah|status|berhasil|'
    r'selesai|detail|transaksi berhasil|bukti|struk|no\.?\s*ref|referensi|'
    r'kode|id transaksi|metode|sumber dana|lihat detail|unduh|bagikan)\b',
    caseSensitive: false,
  );

  /// `Rp` atau `IDR` yang berdiri sendiri tanpa angka.
  static final RegExp _bareCurrency = RegExp(
    r'\b(rp|idr)\b\.?',
    caseSensitive: false,
  );

  /// Nomor rekening/kartu yang disamarkan, mis. "•••• 1234" atau "**** 5678".
  /// Angka di belakangnya sering terbaca sebagai nominal oleh heuristik biasa.
  static final RegExp _maskedAccount = RegExp(
    r'([*•·∙⋅]{2,}|\.{3,}|x{4,})\s*\d{2,}',
    caseSensitive: false,
  );

  /// Label identitas rekening, mis. "No. Rekening 1234567890".
  static final RegExp _accountLabel = RegExp(
    r'^(no\.?\s*)?(rek(ening)?|kartu|akun|a/n|atas\s+nama|card|account)\b',
    caseSensitive: false,
  );

  /// Nama bank di awal baris hampir selalu kepala halaman, bukan transaksi.
  static final RegExp _bankHeader = RegExp(
    r'^(bank|bca|bri|bni|mandiri|cimb|permata|danamon|bsi|btn|jago|'
    r'seabank|blu|octo)\b',
    caseSensitive: false,
  );

  static final RegExp _dateLikeText = RegExp(
    r'\b(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|'
    r'20\d{2}[/\-.]\d{1,2}[/\-.]\d{1,2}|'
    r'\d{1,2}\s+[A-Za-z]{3,9}\.?\s*\d{2,4})\b',
    caseSensitive: false,
  );

  /// Mengurai [text]. [now] hanya dipakai untuk tanggal "hari ini"/"kemarin"
  /// dan tahun pada tanggal tanpa tahun.
  List<ScannedTransaction> parse(String text, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final rawLines = text
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .toList(growable: false);

    final items = <ScannedTransaction>[];
    final seen = <String>{};
    var counter = 0;

    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (line.isEmpty) continue;
      if (_isBalanceLine(line)) continue;
      if (_isSummaryLine(line)) continue;
      if (_isAccountLine(line)) continue;

      final amounts = _amountsIn(line);
      if (amounts.isEmpty) continue;

      final dateHit =
          _findDate(line, clock) ?? _nearestDate(rawLines, i, clock);
      final timeHit =
          _findTime(line, dateHit?.span) ??
          _nearestTime(rawLines, i, dateHit?.span);

      final date = dateHit?.date ?? clock;
      final dateKey = _dateKey(date);
      final time = timeHit;

      var description = _cleanDescription(line);
      if (!_isDescriptionLine(description)) {
        description = _cleanDescription(_nearestDescription(rawLines, i));
      }

      for (final amount in amounts) {
        if (amount.value <= 0 || amount.value > TransactionRules.maxAmount) {
          continue;
        }

        final type = _typeOf(
          line: _contextAround(rawLines, i),
          description: description,
          sign: amount.sign,
        );
        final title = description.isEmpty ? 'Transaksi' : description;
        final category = CategoryGuesser.guess('$title $line', type);

        final key =
            '$dateKey|${time ?? ''}|${amount.value}|'
            '${type.name}|${title.toLowerCase()}';
        if (!seen.add(key)) continue;

        items.add(
          ScannedTransaction(
            id: 'scan-${counter++}',
            date: dateKey,
            time: time,
            amount: amount.value,
            type: type,
            title: title,
            category: category,
            rawText: '$description ${line.trim()}'.trim(),
            dateGuessed: dateHit == null,
          ),
        );

        if (items.length >= maxItems) return items;
      }
    }

    return items;
  }

  // -------------------------------------------------------------- tanggal

  _DateHit? _findDate(String line, DateTime now) {
    final iso = _isoDate.firstMatch(line);
    if (iso != null) {
      final date = _buildDate(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
      if (date != null) {
        return _DateHit(date, _Span(iso.start, iso.end));
      }
    }

    final short = _shortDate.firstMatch(line);
    if (short != null) {
      final first = int.parse(short.group(1)!);
      final second = int.parse(short.group(2)!);
      final year = _fullYear(int.parse(short.group(3)!), now);
      // Indonesia memakai dd/mm/yyyy. Bila angka pertama jelas bulan
      // (mis. 10/18/2026), baru ditukar.
      final swap = second > 12 && first <= 12;
      final day = swap ? second : first;
      final month = swap ? first : second;
      final date = _buildDate(year, month, day);
      if (date != null) {
        return _DateHit(date, _Span(short.start, short.end));
      }
    }

    for (final match in _namedDate.allMatches(line)) {
      final month = _months[match.group(2)!.toLowerCase()];
      if (month == null) continue;
      final day = int.parse(match.group(1)!);
      final rawYear = match.group(3);
      final year = rawYear == null
          ? now.year
          : _fullYear(int.parse(rawYear), now);
      final date = _buildDate(year, month, day);
      if (date != null) {
        return _DateHit(date, _Span(match.start, match.end));
      }
    }

    final lower = line.toLowerCase();
    if (lower.contains('hari ini')) {
      return _DateHit(
        DateTime(now.year, now.month, now.day),
        _Span(lower.indexOf('hari ini'), lower.indexOf('hari ini') + 8),
      );
    }
    if (lower.contains('kemarin')) {
      return _DateHit(
        DateTime(now.year, now.month, now.day - 1),
        _Span(lower.indexOf('kemarin'), lower.indexOf('kemarin') + 7),
      );
    }

    return null;
  }

  _DateHit? _nearestDate(List<String> lines, int index, DateTime now) {
    // Utamakan baris di atas: kebanyakan mutasi menaruh tanggal sebagai kepala
    // kelompok. Nominal transaksi sebelumnya boleh dilewati, karena tanggal
    // kelompok masih berlaku untuk baris berikutnya. Bila tidak ada, lihat
    // beberapa baris di bawah (DANA kadang menaruhnya setelah nominal).
    for (var distance = 1; distance <= 6; distance++) {
      final above = index - distance;
      if (above < 0) break;
      final hit = _findDate(lines[above], now);
      if (hit != null) return hit;
    }
    for (var distance = 1; distance <= 4; distance++) {
      final below = index + distance;
      if (below >= lines.length) break;
      if (_amountsIn(lines[below]).isNotEmpty) break;
      final hit = _findDate(lines[below], now);
      if (hit != null) return hit;
    }
    return null;
  }

  DateTime? _buildDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    // DateTime menormalkan tanggal mustahil (31 Feb menjadi 2 Mar). Tolak bila
    // hasilnya tidak sama dengan yang diminta.
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  int _fullYear(int value, DateTime now) {
    if (value >= 100) return value;
    return 2000 + value;
  }

  // ------------------------------------------------------------------- jam

  String? _findTime(String line, _Span? dateSpan) {
    for (final match in _time.allMatches(line)) {
      if (dateSpan != null && dateSpan.contains(match.start)) continue;
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) continue;
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? _nearestTime(List<String> lines, int index, _Span? dateSpan) {
    for (var distance = 0; distance <= 3; distance++) {
      final above = index - distance;
      if (above >= 0) {
        if (distance > 0 && _amountsIn(lines[above]).isNotEmpty) break;
        final hit = _findTime(lines[above], distance == 0 ? dateSpan : null);
        if (hit != null) return hit;
      }
    }
    for (var distance = 1; distance <= 2; distance++) {
      final below = index + distance;
      if (below >= lines.length) break;
      if (_amountsIn(lines[below]).isNotEmpty) break;
      final hit = _findTime(lines[below], null);
      if (hit != null) return hit;
    }
    return null;
  }

  // ------------------------------------------------------------- deskripsi

  String _nearestDescription(List<String> lines, int index) {
    for (var distance = 1; distance <= 4; distance++) {
      final above = index - distance;
      if (above < 0) break;
      if (_amountsIn(lines[above]).isNotEmpty) break;
      if (_isDescriptionLine(lines[above])) return lines[above];
    }
    for (var distance = 1; distance <= 2; distance++) {
      final below = index + distance;
      if (below >= lines.length) break;
      if (_amountsIn(lines[below]).isNotEmpty) break;
      if (_isDescriptionLine(lines[below])) return lines[below];
    }
    return '';
  }

  /// Dua baris di atas dan satu di bawah cukup untuk menangkap kalimat seperti
  /// "Kamu menerima transfer" yang menjelaskan arah uang.
  String _contextAround(List<String> lines, int index) {
    final start = index - 2 < 0 ? 0 : index - 2;
    final end = index + 1 >= lines.length ? lines.length - 1 : index + 1;
    return lines.sublist(start, end + 1).join(' ');
  }

  bool _isDescriptionLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_metadata.hasMatch(trimmed)) return false;
    if (_isBalanceLine(trimmed)) return false;
    if (_isAccountLine(trimmed)) return false;
    if (_dateLikeText.hasMatch(trimmed) && _stripMeta(trimmed).isEmpty) {
      return false;
    }
    final stripped = _stripMeta(trimmed);
    if (stripped.isEmpty) return false;
    // Baris yang hampir seluruhnya angka bukan deskripsi.
    final letters = RegExp(r'[A-Za-z]').allMatches(stripped).length;
    return letters >= 2;
  }

  String _cleanDescription(String raw) {
    var value = _stripMeta(raw);
    value = value.replaceAll(RegExp(r'\s{2,}'), ' ');
    value = value.replaceAll(RegExp(r'^[\s\-•*:]+|[\s\-•*:]+$'), '');
    value = value.trim();
    if (value.length > TransactionRules.maxTitleLength) {
      value = value.substring(0, TransactionRules.maxTitleLength).trimRight();
    }
    return value;
  }

  /// Membuang potongan tanggal, jam, nominal, dan kata mata uang dari baris.
  String _stripMeta(String raw) {
    var value = raw
        .replaceAll(_isoDate, ' ')
        .replaceAll(_shortDate, ' ')
        .replaceAll(_namedDate, ' ')
        .replaceAll(_time, ' ')
        .replaceAll(_prefixedAmount, ' ')
        .replaceAll(_signedAmount, ' ')
        .replaceAll(_groupedAmount, ' ')
        .replaceAll(_plainAmount, ' ')
        .replaceAll(_bareCurrency, ' ');
    value = value.replaceAll(RegExp(r'[|]+'), ' ');
    return value.trim();
  }

  // ---------------------------------------------------------------- nominal

  List<_AmountHit> _amountsIn(String line) {
    final found = <_AmountHit>[];
    final dateSpans = <_Span>[];
    for (final match in _isoDate.allMatches(line)) {
      dateSpans.add(_Span(match.start, match.end));
    }
    for (final match in _shortDate.allMatches(line)) {
      dateSpans.add(_Span(match.start, match.end));
    }

    void add(RegExpMatch match, {int valueGroup = 2, int? signGroup}) {
      final start = match.start;
      if (dateSpans.any((span) => span.contains(start))) return;
      if (found.any((hit) => hit.start == start)) return;

      final value = _parseNumber(match.group(valueGroup));
      if (value == null || value <= 0) return;
      final signText = signGroup == null ? null : match.group(signGroup);
      found.add(
        _AmountHit(value: value, sign: signText, start: start, end: match.end),
      );
    }

    for (final match in _prefixedAmount.allMatches(line)) {
      add(match, valueGroup: 2, signGroup: 1);
    }
    for (final match in _signedAmount.allMatches(line)) {
      add(match, valueGroup: 2, signGroup: 1);
    }
    for (final match in _groupedAmount.allMatches(line)) {
      add(match, valueGroup: 1);
    }
    for (final match in _plainAmount.allMatches(line)) {
      // Hindari menangkap tahun dan nomor referensi.
      final value = int.tryParse(match.group(1)!);
      if (value == null || (value >= 1900 && value <= 2100)) continue;
      add(match, valueGroup: 1);
    }

    found.sort((a, b) => a.start.compareTo(b.start));
    return found;
  }

  int? _parseNumber(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;

    // Buang spasi pemisah yang kadang muncul dari OCR: "1 234 567".
    value = value.replaceAll(RegExp(r'\s+'), '');

    final hasDot = value.contains('.');
    final hasComma = value.contains(',');
    if (hasDot && hasComma) {
      // Pemisah terakhir adalah desimal.
      if (value.lastIndexOf(',') > value.lastIndexOf('.')) {
        value = value.substring(0, value.lastIndexOf(','));
      } else {
        value = value.substring(0, value.lastIndexOf('.'));
      }
      value = value.replaceAll(RegExp(r'[.,]'), '');
    } else if (hasComma) {
      value = _stripSeparator(value, ',');
    } else if (hasDot) {
      value = _stripSeparator(value, '.');
    }

    return int.tryParse(value);
  }

  String _stripSeparator(String value, String separator) {
    final parts = value.split(separator);
    // Satu pemisah dengan 1-2 digit di belakang = desimal.
    if (parts.length == 2 && parts[1].length <= 2) return parts.first;
    return parts.join();
  }

  // ------------------------------------------------------------------ jenis

  ScannedTransactionType _typeOf({
    required String line,
    required String description,
    required String? sign,
  }) {
    if (sign == '-') return ScannedTransactionType.expense;
    if (sign == '+') return ScannedTransactionType.income;

    final text = '$description $line';
    final income = _incomeWords.hasMatch(text);
    final expense = _expenseWords.hasMatch(text);
    if (income && !expense) return ScannedTransactionType.income;
    // Pengeluaran adalah tebakan aman: sebagian besar baris mutasi adalah
    // pembayaran, dan pengguna melihat serta bisa membalik arahnya.
    return ScannedTransactionType.expense;
  }

  bool _isBalanceLine(String line) {
    final lower = line.toLowerCase().trim();
    if (!lower.startsWith('saldo')) return false;
    return !RegExp(r'(masuk|bertambah|berkurang|terpotong|diterima|keluar)')
        .hasMatch(lower);
  }

  /// Baris identitas rekening/kartu bukan transaksi. Tanpa ini, angka pada
  /// "Bank Sejahtera •••• 1234" bisa lolos sebagai nominal Rp1.234.
  bool _isAccountLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_maskedAccount.hasMatch(trimmed)) return true;
    if (_accountLabel.hasMatch(trimmed)) return true;
    if (_bankHeader.hasMatch(trimmed)) {
      final lower = trimmed.toLowerCase();
      return !_incomeWords.hasMatch(lower) && !_expenseWords.hasMatch(lower);
    }
    return false;
  }

  /// Baris ringkasan seperti "Total pengeluaran Rp1.000.000" bukan transaksi.
  bool _isSummaryLine(String line) {
    return RegExp(
      r'^(total|subtotal|jumlah transaksi)\b',
      caseSensitive: false,
    ).hasMatch(line.trim());
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;

  bool contains(int position) => position >= start && position < end;
}

class _DateHit {
  const _DateHit(this.date, this.span);
  final DateTime date;
  final _Span span;
}

class _AmountHit {
  const _AmountHit({
    required this.value,
    required this.sign,
    required this.start,
    required this.end,
  });

  final int value;
  final String? sign;
  final int start;
  final int end;
}
