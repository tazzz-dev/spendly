import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_progress.dart';

void main() {
  group('DebtProgress pembayaran sebagian (H-22)', () {
    test('owe: sisa berkurang sebesar entri pembayaran', () {
      const progress = DebtProgress(target: 5000000, paidEntries: 200000);

      expect(progress.paid, 200000);
      expect(progress.remaining, 4800000);
      expect(progress.overpaid, 0);
      expect(progress.fraction, 0.04);
      expect(progress.isSettled, isFalse);
      expect(progress.isForgiven, isFalse);
    });

    test('owed: rumus progress sama, hanya arah entrinya berbeda', () {
      const progress = DebtProgress(
        target: 2000000,
        paidOpening: 500000,
        paidEntries: 500000,
      );

      expect(progress.paid, 1000000);
      expect(progress.remaining, 1000000);
      expect(progress.fraction, 0.5);
    });

    test('paid_opening ikut dihitung sebagai titik awal', () {
      const progress = DebtProgress(
        target: 5000000,
        paidOpening: 500000,
        paidEntries: 200000,
      );

      expect(progress.paid, 700000);
      expect(progress.remaining, 4300000);
    });

    test('entri arah berlawanan tidak pernah mengurangi progress', () {
      // Repository hanya menjumlahkan entri yang searah pembayaran; entri arah
      // pokok tidak masuk ke paidEntries sama sekali.
      const progress = DebtProgress(
        target: 5000000,
        paidEntries: 200000,
        paidOpening: 0,
      );

      expect(progress.paid, 200000);
      expect(progress.remaining, 4800000);
    });
  });

  group('DebtProgress target nol atau negatif', () {
    test('target nol diperlakukan sebagai tanpa target', () {
      const progress = DebtProgress(target: 0, paidEntries: 5000);

      expect(progress.isTargeted, isFalse);
      expect(progress.remaining, 0);
      expect(progress.overpaid, 0);
      expect(progress.fraction, 0);
      expect(progress.isSettled, isFalse);
    });

    test('target negatif tidak membuat pembagian aneh', () {
      const progress = DebtProgress(target: -1000, paidEntries: 500);

      expect(progress.isTargeted, isFalse);
      expect(progress.remaining, 0);
      expect(progress.overpaid, 0);
      expect(progress.fraction, 0);
    });
  });

  group('DebtProgress kelebihan bayar (H-23)', () {
    test('lunas dengan lebih Rp200.000', () {
      const progress = DebtProgress(target: 5000000, paidEntries: 5200000);

      expect(progress.paid, 5200000);
      expect(progress.remaining, 0);
      expect(progress.overpaid, 200000);
      expect(progress.fraction, 1);
      expect(progress.isSettled, isTrue);
      expect(progress.isForgiven, isFalse);
    });

    test('fraction dibatasi paling tinggi 1', () {
      const progress = DebtProgress(target: 5000000, paidEntries: 10000000);

      expect(progress.fraction, 1);
    });
  });

  group('DebtProgress status lunas (H-24)', () {
    test('utang dihapuskan: ditandai lunas padahal masih ada sisa', () {
      const progress = DebtProgress(
        target: 5000000,
        paidEntries: 200000,
        manualSettled: true,
      );

      expect(progress.remaining, 4800000);
      expect(progress.isSettled, isTrue);
      expect(progress.isForgiven, isTrue);
    });

    test('lunas penuh tanpa flag manual tetap dianggap lunas', () {
      const progress = DebtProgress(target: 1000000, paidEntries: 1000000);

      expect(progress.remaining, 0);
      expect(progress.isSettled, isTrue);
      expect(progress.isForgiven, isFalse);
    });

    test('flag manual pada pembayaran penuh bukan penghapusan', () {
      const progress = DebtProgress(
        target: 1000000,
        paidEntries: 1200000,
        manualSettled: true,
      );

      expect(progress.overpaid, 200000);
      expect(progress.isSettled, isTrue);
      expect(progress.isForgiven, isFalse);
    });
  });
}
