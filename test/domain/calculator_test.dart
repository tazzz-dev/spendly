import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/calculator.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';

void main() {
  group('MoneyCalculator', () {
    test('menghitung empat operasi dasar', () {
      expect(MoneyCalculator.evaluate('100+200'), 300);
      expect(MoneyCalculator.evaluate('1000-250'), 750);
      expect(MoneyCalculator.evaluate('2500x3'), 7500);
      expect(MoneyCalculator.evaluate('100/4'), 25);
    });

    test('perkalian dan pembagian dikerjakan lebih dulu', () {
      expect(MoneyCalculator.evaluate('2x3+4x5'), 26);
      expect(MoneyCalculator.evaluate('10+2x3'), 16);
      expect(MoneyCalculator.evaluate('2x3-4'), 2);
    });

    test('dihitung dari kiri ke kanan pada tingkat yang sama', () {
      expect(MoneyCalculator.evaluate('100-30-20'), 50);
      expect(MoneyCalculator.evaluate('100/5/2'), 10);
    });

    test('pembagian dibulatkan ke rupiah utuh terdekat', () {
      // Kita tidak pernah menyimpan pecahan. SPEC G-11.
      expect(MoneyCalculator.evaluate('100/3'), 33);
      expect(MoneyCalculator.evaluate('101/2'), 51);
    });

    test('pembagian dengan nol ditolak, bukan menghasilkan tak-hingga', () {
      expect(MoneyCalculator.evaluate('10/0'), isNull);
    });

    test('ungkapan yang belum selesai tidak dihitung', () {
      expect(MoneyCalculator.evaluate(''), isNull);
      expect(MoneyCalculator.evaluate('5+'), isNull);
      expect(MoneyCalculator.evaluate('+5'), isNull);
      expect(MoneyCalculator.evaluate('5++5'), isNull);
      expect(MoneyCalculator.evaluate('x5'), isNull);
    });

    test('huruf dan lambang asing ditolak', () {
      expect(MoneyCalculator.evaluate('abc'), isNull);
      expect(MoneyCalculator.evaluate('5;5'), isNull);
      expect(MoneyCalculator.evaluate('5,5'), isNull);
    });

    test('spasi diabaikan, sehingga angka bergaya Indonesia tetap terbaca', () {
      expect(MoneyCalculator.evaluate('1 000 + 2 000'), 3000);
    });

    test('hasil yang melewati batas nominal ditolak', () {
      expect(
        MoneyCalculator.evaluate('999999999999'),
        TransactionRules.maxAmount,
      );
      expect(MoneyCalculator.evaluate('1000000x1000000'), isNull);
      expect(MoneyCalculator.evaluate('1000000000000'), isNull);
    });

    test('isOperator mengenali keempat lambang', () {
      expect(MoneyCalculator.isOperator('+'), isTrue);
      expect(MoneyCalculator.isOperator('-'), isTrue);
      expect(MoneyCalculator.isOperator('x'), isTrue);
      expect(MoneyCalculator.isOperator('/'), isTrue);
      expect(MoneyCalculator.isOperator('5'), isFalse);
    });
  });

  group('TransactionRules', () {
    test('SPEC T-1: satu pesan untuk keempat field wajib', () {
      const message = 'Jumlah, judul, kategori, dan rekening harus diisi.';

      expect(
        TransactionRules.validateSimple(
          amount: null,
          title: 'Gaji',
          category: 'Gaji',
          walletId: 'w1',
        ),
        message,
      );
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: '',
          category: 'Gaji',
          walletId: 'w1',
        ),
        message,
      );
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: 'Gaji',
          category: '',
          walletId: 'w1',
        ),
        message,
      );
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: 'Gaji',
          category: 'Gaji',
          walletId: null,
        ),
        message,
      );
    });

    test('keempatnya terisi berarti lolos', () {
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: 'Gaji',
          category: 'Gaji',
          walletId: 'w1',
        ),
        isNull,
      );
    });

    test('SPEC S-2: pesan pindah saldo', () {
      expect(
        TransactionRules.validateTransfer(
          amount: null,
          fromWalletId: 'w1',
          toWalletId: 'w2',
        ),
        'Jumlah, rekening asal, dan rekening tujuan harus diisi.',
      );
      expect(
        TransactionRules.validateTransfer(
          amount: 1000,
          fromWalletId: 'w1',
          toWalletId: null,
        ),
        'Jumlah, rekening asal, dan rekening tujuan harus diisi.',
      );
    });

    test('SPEC M-3: rekening asal dan tujuan tidak boleh sama', () {
      expect(
        TransactionRules.validateTransfer(
          amount: 1000,
          fromWalletId: 'w1',
          toWalletId: 'w1',
        ),
        'Rekening asal dan tujuan harus berbeda.',
      );
    });

    test('nominal nol ditolak karena tidak mengubah apa pun', () {
      expect(
        TransactionRules.validateTransfer(
          amount: 0,
          fromWalletId: 'w1',
          toWalletId: 'w2',
        ),
        'Jumlah, rekening asal, dan rekening tujuan harus diisi.',
      );
    });

    test('SPEC K-2 dan K-5: koreksi saldo boleh negatif', () {
      expect(
        TransactionRules.validateCorrection(amount: -25000, walletId: 'w1'),
        isNull,
      );
      expect(
        TransactionRules.validateCorrection(amount: 0, walletId: 'w1'),
        'Jumlah dan rekening harus diisi.',
      );
      expect(
        TransactionRules.validateCorrection(amount: 25000, walletId: ''),
        'Jumlah dan rekening harus diisi.',
      );
    });

    test('batas panjang teks ditegakkan tepat di tepinya', () {
      expect(
        TransactionRules.validateText(
          'a' * TransactionRules.maxTitleLength,
          label: 'Judul',
          maxLength: TransactionRules.maxTitleLength,
        ),
        isNull,
      );
      expect(
        TransactionRules.validateText(
          'a' * (TransactionRules.maxTitleLength + 1),
          label: 'Judul',
          maxLength: TransactionRules.maxTitleLength,
        ),
        isNotNull,
      );
    });

    test('form pemasukan menolak judul dan kategori kepanjangan', () {
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: 'a' * (TransactionRules.maxTitleLength + 1),
          category: 'Gaji',
          walletId: 'w1',
        ),
        'Judul paling panjang ${TransactionRules.maxTitleLength} huruf.',
      );
      expect(
        TransactionRules.validateSimple(
          amount: 1000,
          title: 'Gaji',
          category: 'a' * (TransactionRules.maxCategoryLength + 1),
          walletId: 'w1',
        ),
        'Kategori paling panjang ${TransactionRules.maxCategoryLength} huruf.',
      );
    });

    test('jumlah melewati batas ditolak setelah field wajib terisi', () {
      expect(
        TransactionRules.validateSimple(
          amount: TransactionRules.maxAmount + 1,
          title: 'Gaji',
          category: 'Gaji',
          walletId: 'w1',
        ),
        'Jumlah paling besar ${TransactionRules.maxAmount ~/ 1000000000} miliar.',
      );
    });

    test('keterangan opsional, tetapi panjangnya tetap dibatasi', () {
      expect(TransactionRules.validateNote(null), isNull);
      expect(TransactionRules.validateNote('  '), isNull);
      expect(
        TransactionRules.validateNote('a' * TransactionRules.maxNoteLength),
        isNull,
      );
      expect(
        TransactionRules.validateNote(
          'a' * (TransactionRules.maxNoteLength + 1),
        ),
        'Keterangan paling panjang ${TransactionRules.maxNoteLength} huruf.',
      );
    });
  });
}
