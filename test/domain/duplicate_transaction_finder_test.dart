import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/duplicate_transaction_finder.dart';
import 'package:pencatatan_keuangan/domain/scanned_transaction.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';

void main() {
  const finder = DuplicateTransactionFinder();

  ScannedTransaction scanned({
    required String id,
    required int amount,
    ScannedTransactionType type = ScannedTransactionType.expense,
    String date = '2026-10-26',
    String? time,
    String title = 'Shopee',
  }) => ScannedTransaction(
    id: id,
    date: date,
    time: time,
    amount: amount,
    type: type,
    title: title,
    category: 'Lainnya',
  );

  TransactionEntry existing({
    required String id,
    required int amount,
    TxKind kind = TxKind.expense,
    String date = '2026-10-26',
    String? time,
    String? title = 'Payung',
    String? walletId = 'dana',
  }) => TransactionEntry(
    id: id,
    kind: kind,
    amount: amount,
    date: date,
    time: time,
    title: title,
    walletId: walletId,
  );

  test(
    'judul berbeda tetap dianggap duplikat bila tanggal, arah, nominal sama',
    () {
      final matches = finder.find(
        scanned: [scanned(id: 'scan-0', amount: 31675)],
        existing: [existing(id: 'tx-1', amount: -31675)],
      );

      expect(matches.keys, ['scan-0']);
      expect(matches['scan-0']?.id, 'tx-1');
    },
  );

  test('tanggal, arah, atau nominal berbeda bukan duplikat', () {
    final matches = finder.find(
      scanned: [
        scanned(id: 'beda-tanggal', amount: 31675, date: '2026-10-25'),
        scanned(
          id: 'beda-arah',
          amount: 31675,
          type: ScannedTransactionType.income,
        ),
        scanned(id: 'beda-nominal', amount: 32000),
      ],
      existing: [existing(id: 'tx-1', amount: -31675)],
    );

    expect(matches, isEmpty);
  });

  test('satu transaksi lama hanya dipakai sekali', () {
    final matches = finder.find(
      scanned: [
        scanned(id: 'scan-0', amount: 10000),
        scanned(id: 'scan-1', amount: 10000),
      ],
      existing: [existing(id: 'tx-1', amount: -10000)],
    );

    expect(matches.keys, ['scan-0']);
  });

  test('dua transaksi lama dengan nominal sama menandai dua baris scan', () {
    final matches = finder.find(
      scanned: [
        scanned(id: 'scan-0', amount: 10000, time: '09:00'),
        scanned(id: 'scan-1', amount: 10000, time: '18:00'),
      ],
      existing: [
        existing(id: 'tx-1', amount: -10000, time: '18:00'),
        existing(id: 'tx-2', amount: -10000, time: '09:00'),
      ],
    );

    expect(matches['scan-0']?.id, 'tx-2');
    expect(matches['scan-1']?.id, 'tx-1');
  });

  test('pindah saldo dihitung, koreksi saldo tidak', () {
    final matches = finder.find(
      scanned: [
        scanned(id: 'scan-transfer', amount: 500000),
        scanned(id: 'scan-correction', amount: 10000, date: '2026-10-22'),
      ],
      existing: [
        existing(
          id: 'tx-1',
          amount: -500000,
          kind: TxKind.transferOut,
          title: null,
        ),
        existing(
          id: 'tx-2',
          amount: 10000,
          kind: TxKind.correction,
          date: '2026-10-22',
          title: null,
        ),
      ],
    );

    expect(matches.keys, ['scan-transfer']);
  });

  group('batas rekening', () {
    final item = scanned(id: 'scan-0', amount: 10000);

    test('nominal sama di rekening lain bukan duplikat', () {
      final matches = finder.find(
        scanned: [item],
        existing: [existing(id: 'tx-1', amount: -10000, walletId: 'gopay')],
        walletByScanId: const {'scan-0': 'dana'},
      );

      expect(matches, isEmpty);
    });

    test('nominal sama di rekening yang sama tetap duplikat', () {
      final matches = finder.find(
        scanned: [item],
        existing: [existing(id: 'tx-1', amount: -10000, walletId: 'dana')],
        walletByScanId: const {'scan-0': 'dana'},
      );

      expect(matches['scan-0']?.id, 'tx-1');
    });

    test('tanpa rekening diketahui, rekening tidak membatasi', () {
      final matches = finder.find(
        scanned: [item],
        existing: [existing(id: 'tx-1', amount: -10000, walletId: 'gopay')],
      );

      expect(matches['scan-0']?.id, 'tx-1');
    });
  });

  test('nominal nol dilewati', () {
    final matches = finder.find(
      scanned: [scanned(id: 'scan-0', amount: 0)],
      existing: [existing(id: 'tx-1', amount: 0)],
    );

    expect(matches, isEmpty);
  });
}
