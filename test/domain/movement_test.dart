import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/movement.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';

void main() {
  group('tanda nominal ditentukan di satu tempat (RW-5)', () {
    test('pemasukan selalu positif walau dikirim negatif', () {
      final draft = Movement.income(
        amount: -50000,
        walletId: 'w1',
        title: 'Gaji',
        category: 'Gaji',
        date: '2026-10-19',
      );

      expect(draft.kind, TxKind.income);
      expect(draft.amount, 50000);
    });

    test('pengeluaran selalu negatif', () {
      final draft = Movement.expense(
        amount: 30000,
        walletId: 'w1',
        title: 'Makan',
        category: 'Makanan',
        date: '2026-10-19',
      );

      expect(draft.kind, TxKind.expense);
      expect(draft.amount, -30000);
    });

    test('nominal nol ditolak, sesuai INV-9 dan D3', () {
      expect(
        () => Movement.income(
          amount: 0,
          walletId: 'w1',
          title: 'x',
          category: 'y',
          date: '2026-10-19',
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            Movement.correction(amount: 0, walletId: 'w1', date: '2026-10-19'),
        throwsArgumentError,
      );
    });
  });

  group('pindah saldo', () {
    test('menghasilkan dua baris berlawanan tanda dengan grup yang sama', () {
      final draft = Movement.transfer(
        amount: 250000,
        fromWalletId: 'w1',
        toWalletId: 'w2',
        groupId: 'g1',
        date: '2026-10-19',
      );

      expect(draft.rows, hasLength(2));
      expect(draft.outgoing.kind, TxKind.transferOut);
      expect(draft.incoming.kind, TxKind.transferIn);

      expect(draft.outgoing.walletId, 'w1');
      expect(draft.outgoing.counterWalletId, 'w2');
      expect(draft.incoming.walletId, 'w2');
      expect(draft.incoming.counterWalletId, 'w1');

      expect(draft.outgoing.transferGroupId, 'g1');
      expect(draft.incoming.transferGroupId, 'g1');
    });

    test('INV-4: dampak kedua sisi sama besar dan berlawanan tanda', () {
      final draft = Movement.transfer(
        amount: 125000,
        fromWalletId: 'w1',
        toWalletId: 'w2',
        groupId: 'g1',
        date: '2026-10-19',
      );

      expect(draft.isBalanced, isTrue);
      expect(draft.outgoing.amount, -125000);
      expect(draft.incoming.amount, 125000);
      expect(draft.outgoing.amount + draft.incoming.amount, 0);
    });

    test('rekening asal sama dengan tujuan ditolak, sesuai SPEC M-3', () {
      expect(
        () => Movement.transfer(
          amount: 10000,
          fromWalletId: 'w1',
          toWalletId: 'w1',
          groupId: 'g1',
          date: '2026-10-19',
        ),
        throwsArgumentError,
      );
    });

    test('RW-12: kedua baris tanpa judul dan tanpa kategori', () {
      final draft = Movement.transfer(
        amount: 10000,
        fromWalletId: 'w1',
        toWalletId: 'w2',
        groupId: 'g1',
        date: '2026-10-19',
      );

      for (final row in draft.rows) {
        expect(row.title, isNull);
        expect(row.category, isNull);
      }
    });
  });

  group('koreksi saldo', () {
    test('boleh positif maupun negatif, sesuai SPEC K-5', () {
      final up = Movement.correction(
        amount: 15000,
        walletId: 'w1',
        date: '2026-10-19',
      );
      final down = Movement.correction(
        amount: -15000,
        walletId: 'w1',
        date: '2026-10-19',
      );

      expect(up.amount, 15000);
      expect(down.amount, -15000);
    });

    test('judulnya diisi otomatis, kategorinya kosong', () {
      final draft = Movement.correction(
        amount: 5000,
        walletId: 'w1',
        date: '2026-10-19',
      );

      expect(draft.title, 'Koreksi Saldo');
      expect(draft.category, isNull);
    });
  });

  group('TxKind', () {
    test('bolak-balik lewat nilai simpanan', () {
      for (final kind in TxKind.values) {
        expect(TxKind.fromStorage(kind.storageValue), kind);
      }
    });

    test(
      'nilai simpanan tidak boleh berubah, karena baris lama memakainya',
      () {
        expect(TxKind.income.storageValue, 'income');
        expect(TxKind.expense.storageValue, 'expense');
        expect(TxKind.transferOut.storageValue, 'transfer_out');
        expect(TxKind.transferIn.storageValue, 'transfer_in');
        expect(TxKind.correction.storageValue, 'correction');
      },
    );

    test('jenis tak dikenal melempar, bukan diam-diam jadi pemasukan', () {
      expect(() => TxKind.fromStorage('entah'), throwsArgumentError);
    });

    test('hanya pemasukan dan pengeluaran yang masuk hitungan rekap', () {
      expect(TxKind.income.countsInReport, isTrue);
      expect(TxKind.expense.countsInReport, isTrue);
      expect(TxKind.transferOut.countsInReport, isFalse);
      expect(TxKind.transferIn.countsInReport, isFalse);
      expect(TxKind.correction.countsInReport, isFalse);
    });
  });
}
