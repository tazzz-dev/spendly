import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/notification_draft.dart';
import 'package:pencatatan_keuangan/domain/notification_parser.dart';

void main() {
  const engine = NotificationParserEngine();

  NotificationParseResult? parse(
    String packageName,
    String title,
    String message,
  ) => engine.parse(packageName: packageName, title: title, message: message);

  group('setiap aplikasi target', () {
    test('BCA debit menjadi pengeluaran', () {
      final result = parse(
        'com.bca',
        'Transaksi Debit',
        'Transaksi Debit Rp125.000 BERHASIL. Saldo Rp1.500.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 125000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('BCA kredit menjadi pemasukan', () {
      final result = parse(
        'com.bca',
        'Transaksi Kredit',
        'Transaksi Kredit Rp2.000.000 BERHASIL. Saldo Rp3.500.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 2000000);
      expect(result.type, NotificationDraftType.income);
    });

    test('Livin Mandiri transfer ke menjadi pengeluaran', () {
      final result = parse(
        'id.co.bankmandiri.livin',
        'Transfer Berhasil',
        'Transfer berhasil ke BUDI Rp75.000. Saldo Rp500.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 75000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('Livin Mandiri transfer dari menjadi pemasukan', () {
      final result = parse(
        'id.co.bankmandiri.livin',
        'Transfer Masuk',
        'Transfer berhasil dari BUDI Rp75.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 75000);
      expect(result.type, NotificationDraftType.income);
    });

    test('BRImo QRIS menjadi pengeluaran', () {
      final result = parse(
        'id.co.bri.brimo',
        'Pembayaran QRIS',
        'Pembayaran QRIS Rp45.000 berhasil di WARUNG',
      );

      expect(result, isNotNull);
      expect(result!.amount, 45000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('GoPay pembayaran menjadi pengeluaran', () {
      final result = parse(
        'com.gojek.app',
        'Pembayaran Berhasil',
        'Pembayaran berhasil Rp25.000 ke Kopi Kenangan',
      );

      expect(result, isNotNull);
      expect(result!.amount, 25000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('GoPay top up menjadi pemasukan', () {
      final result = parse(
        'com.gojek.gopay',
        'Top Up Berhasil',
        'Top up berhasil Rp100.000. Saldo Rp150.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 100000);
      expect(result.type, NotificationDraftType.income);
    });

    test('GoPay transfer masuk dengan judul Transfer masuk dikenali', () {
      final result = parse(
        'com.gojek.gopay',
        'Transfer masuk',
        'Rp10.000 dari Budi udah masuk ke GoPay kamu.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 10000);
      expect(result.type, NotificationDraftType.income);
    });

    test('GoPay tanpa judul tetap terbaca dari frasa masuk ke GoPay', () {
      final result = parse(
        'com.gojek.gopay',
        '',
        'Rp10.000 dari Budi udah masuk ke GoPay kamu.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 10000);
      expect(result.type, NotificationDraftType.income);
    });

    test('OVO top up menjadi pemasukan', () {
      final result = parse(
        'ovo.id',
        'Top Up Berhasil',
        'OVO Cash kamu berhasil top up Rp150.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 150000);
      expect(result.type, NotificationDraftType.income);
    });

    test('DANA menerima uang menjadi pemasukan', () {
      final result = parse(
        'id.dana',
        'DANA',
        'Kamu menerima Rp50.000 dari Budi',
      );

      expect(result, isNotNull);
      expect(result!.amount, 50000);
      expect(result.type, NotificationDraftType.income);
    });

    test('DANA top up saldo dari bank menjadi pemasukan', () {
      // Contoh notifikasi nyata: kata "saldo" di sini adalah tujuan top up,
      // bukan saldo akhir, jadi nominalnya harus tetap dipakai.
      final result = parse(
        'id.dana',
        'DANA',
        'Berhasil top up saldo Rp172.000 dari Bank Mandiri. '
            'Lihat detailnya di sini!',
      );

      expect(result, isNotNull);
      expect(result!.amount, 172000);
      expect(result.type, NotificationDraftType.income);
    });

    test('DANA uang yang telah diterima menjadi pemasukan', () {
      final result = parse(
        'id.dana',
        'DANA',
        'Rp100.000 telah diterima dari MUHAMMAD. Lihat detailnya di sini!',
      );

      expect(result, isNotNull);
      expect(result!.amount, 100000);
      expect(result.type, NotificationDraftType.income);
    });

    test('GoPay top up lewat bank menjadi pemasukan', () {
      final result = parse(
        'com.gojek.gopay',
        'Top up berhasil',
        'Top up Rp250.000 via CIMB udah masuk.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 250000);
      expect(result.type, NotificationDraftType.income);
    });

    test('blu autodebit transfer menjadi pengeluaran', () {
      final result = parse(
        'com.bcadigital.blu',
        'Hore, Autodebit Transfer berhasil!',
        'Autodebit Transfer Bayar Uang Pinjaman ke Fildzah Zarifah Nur '
            'Sabrina sebesar Rp200.000 berhasil dilakukan',
      );

      expect(result, isNotNull);
      expect(result!.amount, 200000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('nama paket lama blu tetap dikenali', () {
      final result = parse(
        'id.co.bankbkemobile.digital',
        'Transfer berhasil',
        'Transfer ke Budi Rp15.000 berhasil',
      );

      expect(result, isNotNull);
      expect(result!.amount, 15000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('blu transfer masuk menjadi pemasukan', () {
      final result = parse(
        'com.bcadigital.blu',
        'Transfer masuk',
        'Rp50.000 dari Budi sudah masuk ke blu kamu.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 50000);
      expect(result.type, NotificationDraftType.income);
    });

    test('ShopeePay pembayaran menjadi pengeluaran', () {
      final result = parse(
        'com.shopee.id',
        'Pembayaran Berhasil',
        'Pembayaran Berhasil Rp35.000 ke Merchant',
      );

      expect(result, isNotNull);
      expect(result!.amount, 35000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('alias paket ShopeePay juga dikenali', () {
      final result = parse(
        'com.shopeepay.id',
        'Pembayaran Berhasil',
        'Pembayaran Berhasil Rp35.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 35000);
      expect(result.type, NotificationDraftType.expense);
    });
  });

  group('penyaringan dan nominal', () {
    test('OTP dibuang', () {
      final result = parse(
        'id.dana',
        'Kode OTP',
        'Kode OTP kamu 123456. Jangan berikan kepada siapa pun.',
      );

      expect(result, isNull);
    });

    test('promo dan cashback dibuang', () {
      expect(
        parse(
          'com.shopee.id',
          'Promo Spesial',
          'Cashback Rp20.000 untuk pembelian hari ini',
        ),
        isNull,
      );
    });

    test('notifikasi login dibuang tanpa membuang frasa dana masuk', () {
      expect(
        parse('id.dana', 'Login', 'Kamu berhasil masuk ke akun DANA'),
        isNull,
      );
      expect(
        parse('id.dana', 'DANA', 'Dana masuk Rp100.000 dari Budi'),
        isNotNull,
      );
    });

    test('memilih nominal transaksi, bukan saldo', () {
      final result = parse(
        'id.co.bankmandiri.livin',
        'Transaksi',
        'Saldo Rp1.000.000. Pembayaran Rp20.000 berhasil',
      );

      expect(result, isNotNull);
      expect(result!.amount, 20000);
    });

    test('saldo Anda saat ini tidak dipakai sebagai nominal', () {
      final result = parse(
        'com.bca',
        'Transaksi Debit',
        'Saldo Anda saat ini Rp1.000.000. Transaksi Debit Rp20.000 berhasil',
      );

      expect(result, isNotNull);
      expect(result!.amount, 20000);
      expect(result.type, NotificationDraftType.expense);
    });

    test('notifikasi yang hanya memuat saldo dibuang', () {
      expect(
        parse(
          'id.dana',
          'Pembayaran',
          'Pembayaran berhasil. Saldo Anda saat ini Rp1.000.000',
        ),
        isNull,
      );
    });

    test('frasa saldo masuk tetap menghasilkan pemasukan', () {
      final result = parse(
        'id.dana',
        'DANA',
        'Saldo masuk Rp100.000 dari Budi',
      );

      expect(result, isNotNull);
      expect(result!.amount, 100000);
      expect(result.type, NotificationDraftType.income);
    });

    test('top up saldo memilih nominal top up, bukan saldo akhir', () {
      final result = parse(
        'id.dana',
        'DANA',
        'Top up saldo Rp100.000 berhasil. Saldo Rp250.000',
      );

      expect(result, isNotNull);
      expect(result!.amount, 100000);
      expect(result.type, NotificationDraftType.income);
    });

    test('isi saldo tanpa kata top up tetap terbaca', () {
      final result = parse(
        'com.gojek.gopay',
        'Isi saldo berhasil',
        'Isi saldo Rp75.000 sudah masuk ke GoPay kamu.',
      );

      expect(result, isNotNull);
      expect(result!.amount, 75000);
      expect(result.type, NotificationDraftType.income);
    });

    test('tanpa Rp dibuang', () {
      expect(
        parse('id.dana', 'Pembayaran', 'Pembayaran berhasil 50.000'),
        isNull,
      );
    });

    test('tanpa arah uang dibuang', () {
      expect(parse('id.dana', 'DANA', 'Transaksi Rp50.000 berhasil'), isNull);
    });

    test('paket di luar daftar target dibuang', () {
      expect(
        parse('com.example.bank', 'Pembayaran', 'Pembayaran Rp50.000'),
        isNull,
      );
    });
  });
}
