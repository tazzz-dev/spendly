import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_direction.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';

void main() {
  group('DebtTargetDirection (H-17)', () {
    test('nilai simpanan dan label sesuai dokumen', () {
      expect(DebtTargetDirection.owe.storageValue, 'owe');
      expect(DebtTargetDirection.owed.storageValue, 'owed');
      expect(DebtTargetDirection.owe.label, 'Saya berutang');
      expect(DebtTargetDirection.owed.label, 'Orang berutang ke saya');
    });

    test('pembayaran bergerak ke arah sebaliknya', () {
      expect(DebtTargetDirection.owe.paymentDirection, DebtDirection.give);
      expect(DebtTargetDirection.owed.paymentDirection, DebtDirection.receive);
    });

    test('tanda pembayaran owe negatif dan owed positif', () {
      expect(DebtTargetDirection.owe.paymentDirection.apply(200000), -200000);
      expect(DebtTargetDirection.owed.paymentDirection.apply(200000), 200000);
    });

    test('bolak-balik dari teks berjalan', () {
      for (final direction in DebtTargetDirection.values) {
        expect(
          DebtTargetDirection.fromStorage(direction.storageValue),
          direction,
        );
      }
    });

    test('nilai kosong atau asing menjadi null, bukan melempar', () {
      expect(DebtTargetDirection.fromStorage(null), isNull);
      expect(DebtTargetDirection.fromStorage(''), isNull);
      expect(DebtTargetDirection.fromStorage('lainnya'), isNull);
    });
  });
}
