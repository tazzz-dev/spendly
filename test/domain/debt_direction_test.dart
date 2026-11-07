import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_direction.dart';

void main() {
  group('DebtDirection (SPEC H-2, H-3)', () {
    test('Memberi bertanda negatif, Menerima bertanda positif', () {
      expect(DebtDirection.give.sign, -1);
      expect(DebtDirection.receive.sign, 1);

      expect(DebtDirection.give.apply(200000), -200000);
      expect(DebtDirection.receive.apply(200000), 200000);
    });

    test('urutan menu: Memberi lebih dulu, baru Menerima', () {
      expect(
        DebtDirection.values.map((direction) => direction.label).toList(),
        ['Memberi', 'Menerima'],
      );
    });

    test('tanda ditempelkan ke besar nominal, apa pun tanda masukannya', () {
      // Pengguna boleh saja mengetik nilai yang sudah bertanda; arah tetap
      // yang menentukan.
      expect(DebtDirection.give.apply(-50000), -50000);
      expect(DebtDirection.receive.apply(-50000), 50000);
    });

    test('nol ditolak, karena amount entri tidak pernah boleh nol (RW-8)', () {
      expect(() => DebtDirection.give.apply(0), throwsArgumentError);
      expect(() => DebtDirection.receive.apply(0), throwsArgumentError);
    });

    test('of membaca arah dari nominal bertanda', () {
      expect(DebtDirection.of(1), DebtDirection.receive);
      expect(DebtDirection.of(999999), DebtDirection.receive);
      expect(DebtDirection.of(-1), DebtDirection.give);
      expect(DebtDirection.of(-999999), DebtDirection.give);
      expect(DebtDirection.of(0), isNull);
    });
  });
}
