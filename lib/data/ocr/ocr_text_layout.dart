import 'dart:math' as math;

/// Satu baris teks OCR beserta kotak pembatasnya pada gambar.
class OcrTextLine {
  const OcrTextLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
}

/// Menyusun ulang baris OCR menjadi teks per baris visual.
///
/// ML Kit mengelompokkan teks per blok/kolom. Tanpa penyusunan ulang, nominal
/// di kolom kanan bisa tercerai dari nama merchant dan menempel ke transaksi
/// lain. Di sini baris yang bersebelahan secara vertikal digabung, lalu baris
/// tanggal yang berada tepat di bawah baris nominal ikut ditempelkan supaya
/// tanggal, jam, dan nominal tetap satu transaksi.
String composeOcrText(List<OcrTextLine> lines) {
  final cleaned = [
    for (final line in lines)
      if (line.text.trim().isNotEmpty) line,
  ];
  if (cleaned.isEmpty) return '';

  cleaned.sort((a, b) {
    final byTop = a.top.compareTo(b.top);
    if (byTop != 0) return byTop;
    return a.left.compareTo(b.left);
  });

  final rows = <_VisualRow>[];
  for (final line in cleaned) {
    _VisualRow? target;
    for (var i = rows.length - 1; i >= 0 && i >= rows.length - 4; i--) {
      if (rows[i].overlaps(line)) {
        target = rows[i];
        break;
      }
    }
    if (target == null) {
      rows.add(_VisualRow(line));
    } else {
      target.add(line);
    }
  }

  final out = <String>[];
  for (var i = 0; i < rows.length; i++) {
    final text = rows[i].text;
    if (_hasAmount(text)) {
      if (i + 1 < rows.length && _isDateOnly(rows[i + 1].text)) {
        out.add('$text ${rows[i + 1].text}');
        i++;
        continue;
      }
      // Ikon/logo di kolom kiri kadang terbaca sebagai huruf pendek ("RIS")
      // dan menyelip di antara baris nominal dan tanggal.
      if (i + 2 < rows.length &&
          _isNoise(rows[i + 1].text) &&
          _isDateOnly(rows[i + 2].text)) {
        out.add('$text ${rows[i + 2].text}');
        i += 2;
        continue;
      }
    }
    out.add(text);
  }
  return out.join('\n');
}

class _VisualRow {
  _VisualRow(OcrTextLine line)
      : _lines = [line],
        top = line.top,
        bottom = line.bottom;

  final List<OcrTextLine> _lines;
  double top;
  double bottom;

  bool overlaps(OcrTextLine line) {
    final overlap = math.min(bottom, line.bottom) - math.max(top, line.top);
    if (overlap <= 0) return false;
    final smallest = math.min(bottom - top, line.height);
    return overlap > smallest * 0.5;
  }

  void add(OcrTextLine line) {
    _lines.add(line);
    top = math.min(top, line.top);
    bottom = math.max(bottom, line.bottom);
  }

  String get text {
    final sorted = [..._lines]..sort((a, b) => a.left.compareTo(b.left));
    return sorted.map((line) => line.text.trim()).join(' ').trim();
  }
}

final RegExp _dateToken = RegExp(
  r'\b(\d{1,2}\s+[A-Za-z]{3,9}\.?\s*\d{2,4}|'
  r'\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|'
  r'20\d{2}[/\-.]\d{1,2}[/\-.]\d{1,2})\b',
  caseSensitive: false,
);

final RegExp _amountMarker = RegExp(r'\b(rp|idr)\b', caseSensitive: false);

final RegExp _groupedAmount = RegExp(
  r'(?<![\d.,])\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?(?![\d])',
);

/// Baris tanggal murni (tanpa nominal), ciri khas mutasi DANA/OVO.
bool _isDateOnly(String text) =>
    _dateToken.hasMatch(text) && !_amountMarker.hasMatch(text);

bool _hasAmount(String text) =>
    _amountMarker.hasMatch(text) || _groupedAmount.hasMatch(text);

/// Baris sisa ikon/logo: hanya beberapa huruf, tanpa angka.
bool _isNoise(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || RegExp(r'\d').hasMatch(trimmed)) return false;
  final letters = RegExp(r'[A-Za-z]').allMatches(trimmed).length;
  return letters >= 1 && letters <= 5 && letters == trimmed.length;
}
