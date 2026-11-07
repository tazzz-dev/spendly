import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/features/transactions/sepran_json_import.dart';

/// Membaca berkas contoh yang bentuknya sama dengan ekspor JSON dari HP.
SepranJsonPreview sample() => const SepranJsonParser().parse(
  File('test/fixtures/sepran_sample.json').readAsStringSync(),
);

void main() {
  const parser = SepranJsonParser();

  test('membaca transaksi dan saldo rekening dari berkas contoh', () {
    final preview = sample();

    expect(preview.rows, hasLength(6));
    expect(preview.skipped, 0);
    expect(preview.skippedBalances, 0);

    expect(preview.income, 300000);
    expect(preview.expense, 50000);
    expect(preview.transferCount, 1);
    expect(preview.firstDate, '2026-10-17');
    expect(preview.lastDate, '2026-10-21');

    final transfer = preview.rows.firstWhere(
      (row) => row.kind == SepranJsonKind.transfer,
    );
    expect(transfer.date, '2026-10-19');
    expect(transfer.time, '09:30');
    expect(transfer.amount, 100000);
    expect(transfer.wallet, 'BLU');
    expect(transfer.counterWallet, 'Gopay');
    // Pindah saldo mengurangi asal dan menambah tujuan.
    expect(transfer.walletDelta, -100000);
    expect(transfer.counterWalletDelta, 100000);

    final income = preview.rows.firstWhere(
      (row) => row.kind == SepranJsonKind.income,
    );
    expect(income.amount, 250000);
    expect(income.title, 'Gaji');
    expect(income.category, 'Gaji');

    final expense = preview.rows.firstWhere(
      (row) => row.kind == SepranJsonKind.expense,
    );
    expect(expense.amount, -10000);
    expect(expense.wallet, 'Gopay');
  });

  test('saldo awal per rekening dihitung dari target dan mutasi', () {
    final preview = sample();
    final byName = {for (final wallet in preview.wallets) wallet.name: wallet};

    expect(preview.walletNames, ['BLU', 'Gopay', 'Tunai']);

    final blu = byName['BLU']!;
    expect(blu.targetBalance, 2500000);
    // 250.000 masuk − 100.000 pindah − 15.000 parkir.
    expect(blu.netFlow, 135000);
    expect(blu.openingBalance, 2365000);
    expect(blu.transactionCount, 3);

    final gopay = byName['Gopay']!;
    expect(gopay.targetBalance, -50000);
    // −10.000 keluar + 100.000 masuk + 50.000 top up.
    expect(gopay.netFlow, 140000);
    expect(gopay.openingBalance, -190000);
    // Pindah saldo dihitung pada rekening asal dan tujuan.
    expect(gopay.transactionCount, 3);

    final tunai = byName['Tunai']!;
    // 175.000,50 dibulatkan menjadi 175.001.
    expect(tunai.targetBalance, 175001);
    expect(tunai.openingBalance, 200001);
    expect(tunai.transactionCount, 1);
  });

  test('baris tidak valid dilewati dan dihitung', () {
    final preview = parser.parse('''
{
  "wallet_balances": [{"name": "Dompet", "balance": "1000"}],
  "transactions": [
    {"date": "2026-02-31", "type": "income", "amount": 1000, "wallet": "Dompet"},
    {"date": "2026-10-01", "type": "expense", "amount": 0, "wallet": "Dompet"},
    {"date": "2026-10-01", "type": "income", "amount": 1000, "wallet": ""},
    {"date": "2026-10-01", "type": "transfer", "amount": 1000, "wallet": "Dompet"},
    {"date": "2026-10-01", "type": "transfer", "amount": 1000, "wallet": "Dompet", "counter_wallet": "dompet"},
    {"date": "2026-10-01", "type": "refund", "amount": 1000, "wallet": "Dompet"},
    {"date": "2026-10-02", "type": "income", "amount": "1.500,4", "title": "Sisa", "category": "Lain", "wallet": "Dompet"}
  ]
}
''');

    expect(preview.rows, hasLength(1));
    expect(preview.rows.single.amount, 1500);
    expect(preview.rows.single.date, '2026-10-02');
    expect(preview.skipped, 6);

    final wallet = preview.wallets.single;
    expect(wallet.targetBalance, 1000);
    expect(wallet.openingBalance, -500);
  });

  test('nominal dan saldo desimal dibulatkan ke rupiah utuh', () {
    final preview = parser.parse('''
{
  "wallet_balances": [
    {"name": "A", "balance": "10.50"},
    {"name": "B", "balance": "-10.50"},
    {"name": "C", "balance": "1.234"}
  ],
  "transactions": [
    {"date": "2026-10-01", "type": "expense", "amount": "-1500.6", "wallet": "A"}
  ]
}
''');

    final byName = {for (final wallet in preview.wallets) wallet.name: wallet};

    // 10,5 dibulatkan menjauhi nol; 1.234 adalah pemisah ribuan Indonesia.
    expect(byName['A']!.targetBalance, 11);
    expect(byName['B']!.targetBalance, -11);
    expect(byName['C']!.targetBalance, 1234);
    expect(byName['A']!.openingBalance, 1512);
    expect(preview.rows.single.amount, -1501);
  });

  test('nama rekening disatukan tanpa memandang besar-kecil huruf', () {
    final preview = parser.parse('''
{
  "wallet_balances": [
    {"name": "BLU", "balance": "100000"},
    {"name": "Gopay", "balance": "50000"}
  ],
  "transactions": [
    {"date": "2026-10-01", "type": "expense", "amount": -10000, "wallet": "blu"},
    {"date": "2026-10-02", "type": "transfer", "amount": 20000, "wallet": "BLU", "counter_wallet": "GOPAY"}
  ]
}
''');

    expect(preview.walletNames, ['BLU', 'Gopay']);
    final byName = {for (final wallet in preview.wallets) wallet.name: wallet};
    expect(byName['BLU']!.transactionCount, 2);
    expect(byName['BLU']!.netFlow, -30000);
    expect(byName['Gopay']!.netFlow, 20000);
  });

  test('rekening tanpa saldo target tetap tampil dengan saldo awal kosong', () {
    final preview = parser.parse('''
{
  "wallet_balances": [],
  "transactions": [
    {"date": "2026-10-01", "type": "income", "amount": 5000, "wallet": "Kas"}
  ]
}
''');

    final wallet = preview.wallets.single;
    expect(wallet.name, 'Kas');
    expect(wallet.hasTarget, isFalse);
    expect(wallet.targetBalance, isNull);
    expect(wallet.openingBalance, isNull);
    expect(wallet.netFlow, 5000);
  });

  test('berkas yang bukan objek JSON ditolak dengan pesan jelas', () {
    expect(() => parser.parse('{'), throwsA(isA<FormatException>()));
    expect(
      () => parser.parse('[]'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('objek JSON'),
        ),
      ),
    );
  });
}
