import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/wallet_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  group('WalletName', () {
    test('spasi di ujung dipangkas', () {
      expect(WalletName.normalize('  BCA  '), 'BCA');
    });

    test('nama kosong atau hanya spasi ditolak', () {
      expect(WalletName.validate(''), isNotNull);
      expect(WalletName.validate('    '), isNotNull);
    });

    test('nama wajar diterima', () {
      expect(WalletName.validate('BCA'), isNull);
      expect(WalletName.validate('  Dompet Digital  '), isNull);
    });

    test('batas panjang ditegakkan tepat di tepinya', () {
      expect(WalletName.validate('a' * WalletName.maxLength), isNull);
      expect(WalletName.validate('a' * (WalletName.maxLength + 1)), isNotNull);
    });

    test('bentuk pembanding dipangkas dan jadi huruf kecil', () {
      expect(WalletName.fold('  BCA  '), 'bca');
      expect(WalletName.fold('Dompet Digital'), 'dompet digital');
    });

    test('keunikan nama tidak peka huruf besar-kecil', () {
      expect(WalletName.isSame('BCA', 'bca'), isTrue);
      expect(WalletName.isSame('  BcA ', 'BCA'), isTrue);
      expect(WalletName.isSame('BCA', 'BCA Digital'), isFalse);
    });

    test('pesan nama terpakai persis kalimat spesifikasi', () {
      // SPEC §8 kasus tepi "Nama rekening sama".
      expect(WalletName.duplicateMessage, 'Nama Rekening sudah digunakan');
    });
  });

  group('WalletDeleteVerdict', () {
    test('allowed berarti tidak ada penghalang', () {
      const verdict = WalletDeleteVerdict.allowed();
      expect(verdict.allowed, isTrue);
      expect(verdict.block, isNull);
    });

    test('blocked membawa sebabnya', () {
      const verdict = WalletDeleteVerdict.blocked(WalletDeleteBlock.inUse, 3);
      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.inUse);
      expect(verdict.usageCount, 3);
    });

    test('pesan bawaan menyebut rekening bawaan tidak bisa dihapus', () {
      const verdict = WalletDeleteVerdict.blocked(
        WalletDeleteBlock.isDefault,
        0,
      );
      expect(
        deleteBlockMessage(verdict),
        'Rekening bawaan tidak bisa dihapus, hanya bisa diubah.',
      );
    });

    test('pesan masih dipakai menyebut jumlah pergerakan', () {
      const verdict = WalletDeleteVerdict.blocked(WalletDeleteBlock.inUse, 2);
      final message = deleteBlockMessage(verdict);
      expect(message, contains('2 pergerakan'));
      expect(message, contains('Hapus dulu transaksinya'));
    });

    test('pesan punya kalimat cadangan bila tidak ada penghalang', () {
      expect(
        deleteBlockMessage(const WalletDeleteVerdict.allowed()),
        isNotEmpty,
      );
    });
  });

  group('WalletType', () {
    test('setiap jenis punya nilai simpanan yang berbeda', () {
      final values = WalletType.values.map((type) => type.storageValue).toSet();
      expect(values.length, WalletType.values.length);
    });

    test('bolak-balik dari dan ke teks berjalan', () {
      for (final type in WalletType.values) {
        expect(WalletType.fromStorage(type.storageValue), type);
      }
    });

    test('nilai tak dikenal jatuh ke other, bukan melempar galat', () {
      expect(WalletType.fromStorage('bitcoin'), WalletType.other);
      expect(WalletType.fromStorage(''), WalletType.other);
    });
  });
}
