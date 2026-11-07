import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/core/dates.dart';
import 'package:pencatatan_keuangan/core/money.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('MoneyFormat', () {
    test('pemisah ribuan memakai titik, desimal memakai koma', () {
      final money = MoneyFormat(showDecimals: true);
      expect(money.rupiah(1234567), 'Rp1.234.567,00');
    });

    test('desimal dimatikan menghilangkan bagian pecahan', () {
      final money = MoneyFormat(showDecimals: false);
      expect(money.rupiah(1234567), 'Rp1.234.567');
    });

    test('nominal kecil tetap terbaca wajar', () {
      final money = MoneyFormat(showDecimals: false);
      expect(money.rupiah(4000), 'Rp4.000');
      expect(money.rupiah(0), 'Rp0');
    });

    test('nilai negatif memakai tanda minus', () {
      final money = MoneyFormat(showDecimals: true);
      expect(money.plain(-4000), '-4.000,00');
    });
  });

  group('MoneyInput', () {
    test('menerima gaya Indonesia bertitik', () {
      expect(MoneyInput.tryParse('1.234.567'), 1234567);
    });

    test('menerima angka polos', () {
      expect(MoneyInput.tryParse('1234567'), 1234567);
      expect(MoneyInput.tryParse('0'), 0);
    });

    test('membuang awalan Rp dan spasi', () {
      expect(MoneyInput.tryParse('Rp 1.234.567'), 1234567);
      expect(MoneyInput.tryParse(' Rp250.000 '), 250000);
    });

    test('menerima nilai negatif', () {
      expect(MoneyInput.tryParse('-2.500'), -2500);
    });

    test('pecahan dibulatkan ke rupiah utuh', () {
      expect(MoneyInput.tryParse('1.234,4'), 1234);
      expect(MoneyInput.tryParse('1.234,5'), 1235);
      expect(MoneyInput.tryParse('1.234,89'), 1235);
    });

    test('masukan tidak sah dikembalikan sebagai null', () {
      expect(MoneyInput.tryParse(''), isNull);
      expect(MoneyInput.tryParse('   '), isNull);
      expect(MoneyInput.tryParse('-'), isNull);
      expect(MoneyInput.tryParse('abc'), isNull);
      expect(MoneyInput.tryParse('1,2,3'), isNull);
      expect(MoneyInput.tryParse('12-34'), isNull);
    });
  });

  group('AppDate', () {
    test('kunci tanggal memakai format YYYY-MM-DD', () {
      expect(AppDate.key(DateTime(2026, 10, 18)), '2026-10-18');
    });

    test('hari terakhir bulan menangani Februari kabisat', () {
      expect(AppDate.lastDayOfMonth('2024-02-10'), '2024-02-29');
      expect(AppDate.lastDayOfMonth('2026-02-10'), '2026-02-28');
    });

    test('hari pertama bulan', () {
      expect(AppDate.firstDayOfMonth('2026-10-18'), '2026-10-01');
    });

    test('kunci dan pembacaan ulang bersifat bolak-balik', () {
      const key = '2026-10-18';
      expect(AppDate.key(AppDate.parseKey(key)), key);
    });
  });
}
