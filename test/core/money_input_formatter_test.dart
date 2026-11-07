import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/core/money.dart';

void main() {
  TextEditingValue edit(
    String text, {
    bool allowNegative = false,
    int? cursor,
    TextEditingValue? previous,
  }) {
    final offset = cursor ?? text.length;
    return MoneyInputFormatter(allowNegative: allowNegative).formatEditUpdate(
      previous ?? TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset),
      ),
    );
  }

  group('pemisah ribuan saat mengetik', () {
    test('ribuan pertama menambahkan titik', () {
      expect(edit('1000').text, '1.000');
    });

    test('tiga digit belum diberi pemisah', () {
      expect(edit('999').text, '999');
    });

    test('angka besar dikelompokkan tiap tiga digit', () {
      expect(edit('1000000').text, '1.000.000');
      expect(edit('123456789').text, '123.456.789');
    });

    test('mengetik digit demi digit tetap terbaca wajar', () {
      var value = TextEditingValue.empty;
      for (final typed in ['1', '10', '100', '1000', '10000']) {
        value = edit(typed, previous: value);
      }
      expect(value.text, '10.000');
      expect(value.selection.baseOffset, value.text.length);
    });

    test('nol di depan dibuang, satu nol tetap dipertahankan', () {
      expect(edit('007000').text, '7.000');
      expect(edit('0').text, '0');
      expect(edit('000').text, '0');
    });
  });

  group('tempel dan pemisah lama', () {
    test('tempelan angka polos diformat', () {
      expect(edit('2500000').text, '2.500.000');
    });

    test('tempelan bergaya Indonesia diformat ulang', () {
      expect(edit('Rp 2.500.000').text, '2.500.000');
    });

    test('tempelan bergaya koma tetap menjadi angka yang sama', () {
      // Pengguna sering menempel "1,000,000" dari aplikasi lain.
      expect(edit('1,000,000').text, '1.000.000');
    });
  });

  group('kursor', () {
    test('menyisipkan digit di tengah tidak melompat ke ujung', () {
      // "1.000" dengan kursor setelah "1", lalu mengetik "5".
      final result = edit('15.000', cursor: 2);
      expect(result.text, '15.000');
      expect(result.selection.baseOffset, 2);
    });

    test('menghapus titik membuat pengelompokan baru', () {
      final result = edit('1000', cursor: 4);
      expect(result.text, '1.000');
      expect(result.selection.baseOffset, 5);
    });

    test('kursor di awal angka tetap di awal', () {
      final result = edit('25000', cursor: 0);
      expect(result.text, '25.000');
      expect(result.selection.baseOffset, 0);
    });
  });

  group('nilai negatif', () {
    test('koreksi saldo boleh minus', () {
      final result = edit('-25000', allowNegative: true);
      expect(result.text, '-25.000');
      expect(result.selection.baseOffset, 7);
    });

    test('minus diabaikan bila mode tidak mengizinkan', () {
      expect(edit('-25000').text, '25.000');
    });

    test('minus saja tetap bisa diketik', () {
      expect(edit('-', allowNegative: true).text, '-');
    });
  });

  test('formatValue menyiapkan teks awal controller', () {
    expect(MoneyInputFormatter.formatValue(0), '0');
    expect(MoneyInputFormatter.formatValue(25000), '25.000');
    expect(MoneyInputFormatter.formatValue(-25000), '-25.000');
  });
}
