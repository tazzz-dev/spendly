import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/mutation_source.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  const detector = MutationSourceDetector();

  WalletBalance wallet(String id, String name, WalletType type) =>
      WalletBalance(
        id: id,
        name: name,
        type: type,
        openingBalance: 0,
        balance: 0,
      );

  group('deteksi sumber mutasi', () {
    test('mengenali DANA dari teks tangkapan layar', () {
      final source = detector.detect('''
        Activity
        DANA
        Saldo DANA Rp100.000
        Shopee -Rp31.675 26 Oct 2026 • 10:15
      ''');

      expect(source?.key, 'dana');
      expect(source?.label, 'DANA');
    });

    test('mengenali DANA walau nama merek tidak terlihat di gambar', () {
      // Tangkapan layar Activity DANA tidak selalu memuat kata "DANA".
      final source = detector.detect('''
        Activity
        Search send money
        This Month
        Statement
        Shopee Indonesia -Rp31.675 26 Oct 2026 • 14:32
      ''');

      expect(source?.key, 'dana');
    });

    test('frasa "sumber dana" tidak membuat mutasi bank terbaca DANA', () {
      final source = detector.detect('''
        BCA
        Sumber Dana: 1234567890
        Transfer ke Budi -Rp100.000
      ''');

      expect(source?.key, 'bca');
    });

    test('alias yang lebih panjang memenangkan "BCA Digital" sebagai Blu', () {
      final source = detector.detect('''
        Blu by BCA Digital
        Transaksi berhasil
        Kopi -Rp25.000
      ''');

      expect(source?.key, 'blu');
    });

    test('mengenali ShopeePay dan GoPay', () {
      expect(
        detector.detect('ShopeePay\nPembayaran -Rp15.000')?.key,
        'shopeepay',
      );
      expect(detector.detect('GoPay\nTop up Rp50.000')?.key, 'gopay');
    });

    test('teks tanpa nama sumber mengembalikan null', () {
      expect(detector.detect('Warung Makan\n-Rp25.000'), isNull);
      expect(detector.detect('   '), isNull);
    });
  });

  group('pencocokan rekening', () {
    test('memilih rekening DANA yang sudah dimiliki', () {
      final source = detector.detect('DANA\nRiwayat transaksi');
      final wallets = [
        wallet('cash', 'Uang Tunai', WalletType.cash),
        wallet('dana', 'DANA', WalletType.ewallet),
      ];

      expect(detector.matchWallet(source, wallets)?.id, 'dana');
    });

    test('nama rekening yang mengandung alias juga cocok', () {
      final source = detector.detect('BCA mobile\nMutasi rekening');
      final wallets = [
        wallet('bca', 'BCA Tahapan', WalletType.bank),
        wallet('cash', 'Uang Tunai', WalletType.cash),
      ];

      expect(detector.matchWallet(source, wallets)?.id, 'bca');
    });

    test('BCA Digital dipilih untuk sumber Blu, bukan rekening BCA', () {
      final source = detector.detect('Blu by BCA Digital\nMutasi');
      final wallets = [
        wallet('bca', 'BCA', WalletType.bank),
        wallet('blu', 'BCA Digital', WalletType.bank),
      ];

      expect(detector.matchWallet(source, wallets)?.id, 'blu');
    });

    test('tanpa sumber atau tanpa rekening cocok mengembalikan null', () {
      final wallets = [wallet('cash', 'Uang Tunai', WalletType.cash)];
      expect(detector.matchWallet(null, wallets), isNull);
      expect(detector.matchWallet(detector.detect('OVO'), wallets), isNull);
    });
  });
}
