import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_rules.dart';

void main() {
  group('DebtRules.validate (SPEC H-12, RW-8)', () {
    test('nama dan jumlah wajib diisi', () {
      expect(
        DebtRules.validate(partyName: '', amount: 1000),
        DebtRules.requiredFields,
      );
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: null),
        DebtRules.requiredFields,
      );
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: 0),
        DebtRules.requiredFields,
      );
    });

    test('nama dan jumlah terisi berarti lolos', () {
      expect(DebtRules.validate(partyName: 'Fajar', amount: 1), isNull);
    });

    test('tidak ada batas antara pokok dan cicilan: entri boleh melebihi', () {
      // SPEC H-11: buku besar dua arah, bukan pokok plus cicilan.
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: 1000000000),
        isNull,
      );
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: -1000000000),
        isNull,
      );
    });

    test('nominal di atas batas ditolak', () {
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: DebtRules.maxAmount + 1),
        isNotNull,
      );
      expect(
        DebtRules.validate(partyName: 'Fajar', amount: DebtRules.maxAmount),
        isNull,
      );
      // Boleh negatif selama besarnya di dalam batas (SPEC H-11).
      expect(
        DebtRules.validate(
          partyName: 'Fajar',
          amount: -DebtRules.maxAmount - 1,
        ),
        isNotNull,
      );
    });

    test('batas panjang nama ditegakkan tepat di tepinya', () {
      expect(
        DebtRules.validate(
          partyName: 'a' * DebtRules.maxPartyNameLength,
          amount: 1000,
        ),
        isNull,
      );
      expect(
        DebtRules.validate(
          partyName: 'a' * (DebtRules.maxPartyNameLength + 1),
          amount: 1000,
        ),
        isNotNull,
      );
    });

    test('nomor HP dan keterangan opsional, tapi panjangnya tetap dijaga', () {
      expect(
        DebtRules.validate(
          partyName: 'Fajar',
          amount: 1000,
          phone: '081234567890',
          note: 'pinjam untuk makan',
        ),
        isNull,
      );
      expect(
        DebtRules.validate(
          partyName: 'Fajar',
          amount: 1000,
          phone: '0' * (DebtRules.maxPhoneLength + 1),
        ),
        isNotNull,
      );
      expect(
        DebtRules.validate(
          partyName: 'Fajar',
          amount: 1000,
          note: 'a' * (DebtRules.maxNoteLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('DebtRules.validateRecord', () {
    test('hanya nama yang wajib saat menyunting catatan', () {
      expect(DebtRules.validateRecord(partyName: '  '), DebtRules.nameRequired);
      expect(DebtRules.validateRecord(partyName: 'Fajar'), isNull);
    });

    test('batas panjang tetap berlaku', () {
      expect(
        DebtRules.validateRecord(
          partyName: 'a' * (DebtRules.maxPartyNameLength + 1),
        ),
        isNotNull,
      );
      expect(
        DebtRules.validateRecord(
          partyName: 'Fajar',
          note: 'a' * (DebtRules.maxNoteLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('DebtRules.validateAmount', () {
    test('bertanda boleh, nol ditolak', () {
      expect(DebtRules.validateAmount(500), isNull);
      expect(DebtRules.validateAmount(-500), isNull);
      expect(DebtRules.validateAmount(0), DebtRules.amountNotPositive);
      expect(DebtRules.validateAmount(null), DebtRules.amountNotPositive);
    });
  });

  group('DebtRules.validateTarget (H-17, H-25, H-27)', () {
    test('nama dan target wajib diisi', () {
      expect(
        DebtRules.validateTarget(partyName: '', targetAmount: 5000000),
        DebtRules.nameRequired,
      );
      expect(
        DebtRules.validateTarget(partyName: 'Kakak', targetAmount: null),
        DebtRules.targetNotPositive,
      );
      expect(
        DebtRules.validateTarget(partyName: 'Kakak', targetAmount: 0),
        DebtRules.targetNotPositive,
      );
      expect(
        DebtRules.validateTarget(partyName: 'Kakak', targetAmount: -1),
        DebtRules.targetNotPositive,
      );
    });

    test('target sah dan sudah dibayar opsional', () {
      expect(
        DebtRules.validateTarget(
          partyName: 'Kakak',
          targetAmount: 5000000,
          paidOpening: 200000,
        ),
        isNull,
      );
      expect(
        DebtRules.validateTarget(partyName: 'Kakak', targetAmount: 5000000),
        isNull,
      );
    });

    test('sudah dibayar boleh melebihi target (kelebihan bayar)', () {
      expect(
        DebtRules.validateTarget(
          partyName: 'Kakak',
          targetAmount: 1000000,
          paidOpening: 1200000,
        ),
        isNull,
      );
    });

    test('sudah dibayar negatif ditolak', () {
      expect(
        DebtRules.validateTarget(
          partyName: 'Kakak',
          targetAmount: 1000000,
          paidOpening: -1,
        ),
        DebtRules.paidOpeningNegative,
      );
    });

    test('batas nominal dan panjang tetap berlaku', () {
      expect(
        DebtRules.validateTarget(
          partyName: 'Kakak',
          targetAmount: DebtRules.maxAmount + 1,
        ),
        isNotNull,
      );
      expect(
        DebtRules.validateTarget(
          partyName: 'a' * (DebtRules.maxPartyNameLength + 1),
          targetAmount: 1000,
        ),
        isNotNull,
      );
      expect(
        DebtRules.validateTarget(
          partyName: 'Kakak',
          targetAmount: 1000,
          note: 'a' * (DebtRules.maxNoteLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('teks tetap', () {
    test('peringatan rekening pembayaran target (H-21)', () {
      expect(
        DebtRules.walletRequiredForPayment,
        'Tanpa rekening, saldo tidak berkurang',
      );
    });

    test('konfirmasi hapus memuat kalimat H-7 dan akibatnya (H-26)', () {
      expect(
        DebtRules.deleteConfirmation,
        startsWith(
          'Semua data transaksi pada halaman ini akan dihapus, '
          'termasuk seluruh cicilan dan transaksi cerminnya, '
          'dan saldo rekening akan kembali.',
        ),
      );
      expect(DebtRules.deleteConfirmation, endsWith('Apakah Anda yakin?'));
    });

    test('keterangan kosong dan status lunas punya sebutan tetap', () {
      expect(DebtRules.noNote, 'Tanpa keterangan');
      expect(DebtRules.unsettledStatus, 'Belum lunas');
      expect(DebtRules.settledStatus, 'Lunas');
    });
  });

  group('DebtRules.normalize dan blankToNull', () {
    test('spasi di ujung dipangkas', () {
      expect(DebtRules.normalize('  Fajar  '), 'Fajar');
      expect(DebtRules.normalize(null), '');
    });

    test('teks kosong menjadi null supaya kolomnya benar-benar kosong', () {
      expect(DebtRules.blankToNull('   '), isNull);
      expect(DebtRules.blankToNull('isi'), 'isi');
      expect(DebtRules.blankToNull(null), isNull);
    });
  });
}
