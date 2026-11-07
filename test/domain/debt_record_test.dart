import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_direction.dart';
import 'package:pencatatan_keuangan/domain/debt_record.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';

void main() {
  DebtRecord record({
    String id = 'd1',
    String partyName = 'Fajar',
    String? phone,
    String date = '2026-10-19',
    String? note,
    bool isSettled = false,
    int net = 0,
    int? targetAmount,
    DebtTargetDirection? targetDirection,
    int paidOpening = 0,
    int paidEntries = 0,
  }) => DebtRecord(
    id: id,
    partyName: partyName,
    phone: phone,
    date: date,
    note: note,
    isSettled: isSettled,
    net: net,
    targetAmount: targetAmount,
    targetDirection: targetDirection,
    paidOpening: paidOpening,
    paidEntries: paidEntries,
  );

  group('DebtRecord nominal dan arah (SPEC H-3, H-4)', () {
    test('net positif berarti Menerima', () {
      final row = record(net: 250000);
      expect(row.magnitude, 250000);
      expect(row.direction, DebtDirection.receive);
      expect(row.isReceiving, isTrue);
    });

    test('net negatif berarti Memberi, besarnya tanpa tanda', () {
      final row = record(net: -200000);
      expect(row.magnitude, 200000);
      expect(row.direction, DebtDirection.give);
      expect(row.isReceiving, isFalse);
    });

    test('net nol tidak punya arah', () {
      final row = record(net: 0);
      expect(row.magnitude, 0);
      expect(row.direction, isNull);
    });
  });

  group('DebtRecord keterangan dan status (SPEC H-5, H-9)', () {
    test('keterangan kosong ditampilkan sebagai "Tanpa keterangan"', () {
      expect(record(note: null).noteLabel, 'Tanpa keterangan');
      expect(record(note: '   ').noteLabel, 'Tanpa keterangan');
      expect(record(note: 'pinjam makan').noteLabel, 'pinjam makan');
    });

    test('status hanya dua: belum lunas dan lunas', () {
      expect(record().statusLabel, 'Belum lunas');
      expect(record(isSettled: true).statusLabel, 'Lunas');
    });
  });

  group('DebtRecord target (H-17, H-22, H-24)', () {
    test('tanpa target berarti tidak punya progress', () {
      expect(record().hasTarget, isFalse);
      expect(record().progress, isNull);
    });

    test('target nol atau negatif tidak dianggap bertarget', () {
      expect(
        record(
          targetAmount: 0,
          targetDirection: DebtTargetDirection.owe,
        ).hasTarget,
        isFalse,
      );
      expect(
        record(
          targetAmount: -1,
          targetDirection: DebtTargetDirection.owe,
        ).progress,
        isNull,
      );
    });

    test('target tanpa arah tidak menghasilkan progress', () {
      expect(record(targetAmount: 5000000).progress, isNull);
    });

    test('progress menghitung paid_opening dan entri searah', () {
      final row = record(
        targetAmount: 5000000,
        targetDirection: DebtTargetDirection.owe,
        paidOpening: 500000,
        paidEntries: 200000,
      );

      expect(row.hasTarget, isTrue);
      expect(row.progress!.paid, 700000);
      expect(row.progress!.remaining, 4300000);
    });

    test('status detail otomatis Lunas saat target terbayar penuh', () {
      expect(record().statusLabel, 'Belum lunas');
      expect(record(isSettled: true).statusLabel, 'Lunas');
      expect(
        record(
          targetAmount: 1000000,
          targetDirection: DebtTargetDirection.owed,
          paidEntries: 1000000,
        ).statusLabel,
        'Lunas',
      );
    });
  });

  group('pencarian daftar (SPEC H-8)', () {
    final rows = [
      record(
        id: 'a',
        partyName: 'Fajar',
        phone: '0812',
        note: 'bayar pinjaman',
      ),
      record(id: 'b', partyName: 'Reimburse Blok M', note: 'transport'),
      record(id: 'c', partyName: 'Bayu'),
    ];

    test('kata kunci kosong mengembalikan semuanya', () {
      expect(filterDebtRecords(rows, ''), rows);
      expect(filterDebtRecords(rows, '   '), rows);
    });

    test('mencari pada nama, nomor HP, dan keterangan', () {
      expect(filterDebtRecords(rows, 'fajar').map((row) => row.id), ['a']);
      expect(filterDebtRecords(rows, '0812').map((row) => row.id), ['a']);
      expect(filterDebtRecords(rows, 'transport').map((row) => row.id), ['b']);
    });

    test(
      'pencocokan tidak peka huruf besar-kecil dan mencari di tengah kata',
      () {
        expect(filterDebtRecords(rows, 'blok m').map((row) => row.id), ['b']);
        expect(filterDebtRecords(rows, 'REIMBURSE').map((row) => row.id), [
          'b',
        ]);
      },
    );

    test('tidak ada yang cocok berarti daftar kosong', () {
      expect(filterDebtRecords(rows, 'zzz'), isEmpty);
    });
  });
}
