import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/domain/report_range.dart';
import 'package:pencatatan_keuangan/domain/report_rules.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('ReportRange.monthOf', () {
    test('mencakup awal sampai akhir bulan', () {
      final range = ReportRange.monthOf('2026-10-18');

      expect(range.start, '2026-10-01');
      expect(range.end, '2026-10-31');
      expect(range.dayCount, 31);
    });

    test('Februari tahun kabisat berakhir tanggal 29', () {
      final range = ReportRange.monthOf('2028-02-10');

      expect(range.start, '2028-02-01');
      expect(range.end, '2028-02-29');
    });
  });

  group('ReportRange.cycleOf (SPEC L-7b)', () {
    test('Tanggal Mulai 1 berarti mengikuti awal bulan', () {
      final range = ReportRange.cycleOf('2026-10-18', 1);

      expect(range.start, '2026-10-01');
      expect(range.end, '2026-10-31');
    });

    test(
      'Tanggal Mulai 25: sebelum tanggal 25 masuk siklus bulan sebelumnya',
      () {
        final range = ReportRange.cycleOf('2026-10-19', 25);

        expect(range.start, '2026-09-25');
        expect(range.end, '2026-10-24');
      },
    );

    test('Tanggal Mulai 25: mulai tanggal 25 masuk siklus baru', () {
      final range = ReportRange.cycleOf('2026-10-25', 25);

      expect(range.start, '2026-10-25');
      expect(range.end, '2026-11-24');
    });

    test('siklus melintasi pergantian tahun', () {
      final range = ReportRange.cycleOf('2027-01-05', 25);

      expect(range.start, '2026-12-25');
      expect(range.end, '2027-01-24');
    });

    test('hari mulai dibatasi 1 sampai 28', () {
      expect(ReportRange.cycleOf('2026-10-18', 31).start, '2026-09-28');
      expect(ReportRange.cycleOf('2026-10-18', 0).start, '2026-10-01');
    });
  });

  group('keanggotaan rentang', () {
    const range = ReportRange(start: '2026-10-01', end: '2026-10-31');

    test('kedua ujung ikut dihitung', () {
      expect(range.contains('2026-10-01'), isTrue);
      expect(range.contains('2026-10-31'), isTrue);
    });

    test('di luar rentang tidak ikut', () {
      expect(range.contains('2026-09-30'), isFalse);
      expect(range.contains('2026-11-01'), isFalse);
    });

    test('isBefore hanya benar untuk hari sebelum rentang', () {
      expect(range.isBefore('2026-09-30'), isTrue);
      expect(range.isBefore('2026-10-01'), isFalse);
      expect(range.isBefore('2026-10-20'), isFalse);
    });
  });

  group('ReportCycles.recent', () {
    test('urut dari yang terbaru dan berhenti di siklus paling awal', () {
      final cycles = ReportCycles.recent(
        earliest: '2026-08-10',
        latest: '2026-10-18',
        startDay: 1,
      );

      expect(cycles.map((range) => range.label).toList(), [
        'Okt 2026',
        'Sep 2026',
        'Agu 2026',
      ]);
    });

    test(
      'siklus pertama memuat tanggal terbaru, terakhir memuat yang awal',
      () {
        final cycles = ReportCycles.recent(
          earliest: '2026-08-10',
          latest: '2026-10-18',
          startDay: 1,
        );

        expect(cycles.first.contains('2026-10-18'), isTrue);
        expect(cycles.last.contains('2026-08-10'), isTrue);
      },
    );

    test('menghormati Tanggal Mulai selain 1', () {
      final cycles = ReportCycles.recent(
        earliest: '2026-09-26',
        latest: '2026-10-19',
        startDay: 25,
      );

      expect(cycles.first.start, '2026-09-25');
      expect(cycles.first.end, '2026-10-24');
      expect(cycles, hasLength(1));
    });
  });

  group('label', () {
    test('siklus awal bulan memakai nama bulan', () {
      expect(ReportRange.monthOf('2026-10-18').label, 'Okt 2026');
    });

    test('siklus bukan awal bulan memakai rentang tanggal', () {
      final range = ReportRange.cycleOf('2026-10-19', 25);
      expect(range.label, '25 Sep – 24 Okt 2026');
    });
  });

  group('ReportRules.validateCustom (SPEC L-8)', () {
    test('nama wajib diisi', () {
      expect(
        ReportRules.validateCustom(
          name: '  ',
          start: '2026-10-01',
          end: '2026-10-31',
        ),
        ReportRules.customNameRequired,
      );
    });

    test('tanggal akhir lebih kecil dari tanggal awal ditolak', () {
      expect(
        ReportRules.validateCustom(
          name: 'Liburan',
          start: '2026-10-31',
          end: '2026-10-01',
        ),
        ReportRules.customRangeInvalid,
      );
    });

    test('tanggal akhir sama dengan tanggal awal diterima', () {
      expect(
        ReportRules.validateCustom(
          name: 'Liburan',
          start: '2026-10-01',
          end: '2026-10-01',
        ),
        isNull,
      );
    });

    test('nama kepanjangan ditolak', () {
      expect(
        ReportRules.validateCustom(
          name: 'a' * (ReportRules.maxCustomNameLength + 1),
          start: '2026-10-01',
          end: '2026-10-31',
        ),
        ReportRules.customNameTooLong,
      );
    });
  });
}
