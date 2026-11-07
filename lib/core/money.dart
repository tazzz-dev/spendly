import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Format uang gaya Indonesia. Menerapkan SPEC G-1 dan G-2.
///
/// Pemisah ribuan titik, pemisah desimal koma. Nilai selalu bilangan bulat
/// rupiah utuh; setelan desimal hanya memengaruhi tampilan.
class MoneyFormat {
  MoneyFormat({required this.showDecimals});

  /// SPEC ST-3: sakelar "Tampilkan Angka Desimal", aktif secara bawaan.
  final bool showDecimals;

  late final NumberFormat _number = NumberFormat.decimalPatternDigits(
    locale: 'id_ID',
    decimalDigits: showDecimals ? 2 : 0,
  );

  /// `Rp1.234.567` atau `Rp1.234.567,00`.
  String rupiah(int amount) => 'Rp${_number.format(amount)}';

  /// Tanpa awalan `Rp`, dengan tanda minus di depan.
  /// Dipakai di daftar transaksi, tempat nominal pengeluaran ditampilkan
  /// sebagai `-4.000`.
  String plain(int amount) => _number.format(amount);
}

/// Membaca angka yang diketik pengguna menjadi rupiah utuh.
///
/// Menerima gaya Indonesia (`1.234.567`, `1.234.567,89`) maupun angka polos
/// (`1234567`). Mengembalikan null bila tidak bisa dibaca.
///
/// Simpanan kita selalu rupiah utuh (SPEC G-11), jadi bagian pecahan
/// dibulatkan ke bilangan terdekat.
class MoneyInput {
  const MoneyInput._();

  static final RegExp _junk = RegExp(r'[^0-9,-]');
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _maybeDigits = RegExp(r'^\d*$');

  static int? tryParse(String raw) {
    // Buang "Rp", spasi, dan titik pemisah ribuan sekaligus.
    var text = raw.trim().replaceAll(_junk, '');
    if (text.isEmpty) return null;

    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    }
    // Tanda minus di tengah atau di ujung: salah ketik, bukan angka.
    if (text.contains('-') || text.isEmpty) return null;

    final parts = text.split(',');
    if (parts.length > 2) return null;

    final whole = parts.first.isEmpty ? '0' : parts.first;
    if (!_digits.hasMatch(whole)) return null;

    var value = int.tryParse(whole);
    if (value == null) return null;

    if (parts.length == 2) {
      final fraction = parts[1];
      if (!_maybeDigits.hasMatch(fraction)) return null;
      // Satu angka di belakang koma sudah cukup untuk membulatkan.
      if (fraction.isNotEmpty && int.parse(fraction[0]) >= 5) {
        value += 1;
      }
    }

    return negative ? -value : value;
  }
}

/// Memisahkan ribuan saat pengguna mengetik nominal.
///
/// `1000` berubah menjadi `1.000` begitu digit keempat masuk. Pemisah yang
/// sudah diketik atau ditempel (titik maupun koma) dibuang lebih dulu, lalu
/// angka dikelompokkan ulang memakai titik sesuai gaya Indonesia (SPEC G-1).
///
/// Kursor dijaga pada posisi relatif terhadap jumlah digit, sehingga menyisipkan
/// atau menghapus angka di tengah tidak melompat ke ujung teks.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({this.allowNegative = false});

  /// SPEC K-5: hanya koreksi saldo yang boleh bernilai negatif.
  final bool allowNegative;

  static final RegExp _notDigit = RegExp(r'[^0-9]');
  static final RegExp _leadingZeros = RegExp(r'^0+(?=\d)');

  /// Teks siap pakai untuk controller, mis. `1.000.000` atau `-25.000`.
  static String formatValue(int value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}${_group(value.abs().toString())}';
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final negative = allowNegative && text.trimLeft().startsWith('-');

    // Titik dan koma sama-sama pemisah tampilan, bukan bagian dari nilai.
    // Nilai tersimpan selalu rupiah utuh (SPEC G-11).
    var digits = text.replaceAll(_notDigit, '');

    // Jumlah digit di kiri kursor, dihitung sebelum nol di depan dibuang.
    var digitsBeforeCursor = 0;
    if (newValue.selection.isValid) {
      final end = newValue.selection.baseOffset.clamp(0, text.length);
      for (var i = 0; i < end; i++) {
        if (_isDigit(text.codeUnitAt(i))) digitsBeforeCursor++;
      }
    }

    // "007" dibaca sebagai 7 supaya nol di depan tidak menumpuk.
    final stripped = digits.replaceFirst(_leadingZeros, '');
    digitsBeforeCursor =
        (digitsBeforeCursor - (digits.length - stripped.length)).clamp(
          0,
          stripped.length,
        );
    digits = stripped;

    final grouped = _group(digits);
    final formatted = '${negative ? '-' : ''}$grouped';

    var cursor = negative ? 1 : 0;
    var seen = 0;
    for (var i = 0; i < grouped.length; i++) {
      if (!_isDigit(grouped.codeUnitAt(i))) continue;
      seen++;
      if (seen == digitsBeforeCursor) {
        cursor = (negative ? 1 : 0) + i + 1;
        break;
      }
    }
    if (digitsBeforeCursor >= digits.length) cursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
