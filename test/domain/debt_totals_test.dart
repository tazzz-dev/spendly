import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_entry.dart';
import 'package:pencatatan_keuangan/domain/debt_record.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/domain/debt_totals.dart';

void main() {
  DebtRecord record(String id, int net) =>
      DebtRecord(id: id, partyName: id, date: '2026-10-19', net: net);

  DebtRecord target(
    String id,
    DebtTargetDirection direction, {
    required int amount,
    int paidOpening = 0,
    int paidEntries = 0,
    bool isSettled = false,
    String date = '2026-10-19',
  }) => DebtRecord(
    id: id,
    partyName: id,
    date: date,
    net: 0,
    targetAmount: amount,
    targetDirection: direction,
    paidOpening: paidOpening,
    paidEntries: paidEntries,
    isSettled: isSettled,
  );

  DebtEntry entry(String id, int amount, {String? note}) => DebtEntry(
    id: id,
    debtId: 'd1',
    amount: amount,
    date: '2026-10-19',
    note: note,
  );

  group('DebtTotals (SPEC H-1)', () {
    test('dua total dijumlahkan terpisah, tidak pernah disatukan', () {
      final totals = DebtTotals.of([
        record('Fajar', 250000),
        record('Bayu', -200000),
        record('Reimburse', 75000),
        record('Pinjaman', -100000),
      ]);

      expect(totals.receiving, 325000);
      expect(totals.giving, 300000);
    });

    test('catatan bertanda nol tidak menyumbang ke sisi mana pun', () {
      final totals = DebtTotals.of([
        record('Kosong', 0),
        record('Berimbang', 0),
        record('Fajar', 10000),
      ]);

      expect(totals.receiving, 10000);
      expect(totals.giving, 0);
    });

    test('hanya menerima', () {
      final totals = DebtTotals.of([record('a', 5000), record('b', 15000)]);
      expect(totals.receiving, 20000);
      expect(totals.giving, 0);
    });

    test('hanya memberi', () {
      final totals = DebtTotals.of([record('a', -5000), record('b', -15000)]);
      expect(totals.receiving, 0);
      expect(totals.giving, 20000);
    });

    test('tanpa catatan berarti dua-duanya nol', () {
      final totals = DebtTotals.of(const []);
      expect(totals.receiving, 0);
      expect(totals.giving, 0);
      expect(totals.isEmpty, isTrue);
    });
  });

  group('DebtSummary tiga sel (SPEC H-14)', () {
    test('menerima dan memberi dijumlahkan terpisah', () {
      final summary = DebtSummary.of([
        entry('a', 150000),
        entry('b', -200000),
        entry('c', 50000),
      ]);

      expect(summary.receiving, 200000);
      expect(summary.giving, 200000);
    });

    test('sisa adalah besar mutlak selisih kedua arah', () {
      final summary = DebtSummary.of([entry('a', 150000), entry('b', -200000)]);

      // Selisih bertanda negatif (lebih banyak memberi), sisanya positif.
      expect(summary.net, -50000);
      expect(summary.remaining, 50000);
    });

    test('contoh pengamatan SPEC H-14: 0 · 200.000 · 200.000', () {
      // Pada contoh itu hanya ada satu sisi yang terisi; sel ketiga tetap cocok
      // dengan besar mutlak selisihnya.
      final summary = DebtSummary.of([entry('a', -200000)]);

      expect(summary.receiving, 0);
      expect(summary.giving, 200000);
      expect(summary.remaining, 200000);
    });

    test('tanpa entri berarti ketiganya nol', () {
      final summary = DebtSummary.of(const []);
      expect(summary.receiving, 0);
      expect(summary.giving, 0);
      expect(summary.net, 0);
      expect(summary.remaining, 0);
      expect(summary.isEmpty, isTrue);
    });
  });

  group('DebtTargetTotals dua arah terpisah (H-20)', () {
    test('sisa utang dan sisa piutang tidak pernah dijumlahkan', () {
      final totals = DebtTargetTotals.of([
        target(
          'Kakak',
          DebtTargetDirection.owe,
          amount: 5000000,
          paidEntries: 200000,
        ),
        target('Bayu', DebtTargetDirection.owed, amount: 2000000),
      ]);

      expect(totals.owe, 4800000);
      expect(totals.owed, 2000000);
      expect(totals.isEmpty, isFalse);
    });

    test('catatan lunas tidak menambah total sisa', () {
      final totals = DebtTargetTotals.of([
        target(
          'Lunas',
          DebtTargetDirection.owe,
          amount: 1000000,
          paidEntries: 1000000,
        ),
        target(
          'Dihapuskan',
          DebtTargetDirection.owe,
          amount: 2000000,
          paidEntries: 200000,
          isSettled: true,
        ),
        target('Aktif', DebtTargetDirection.owed, amount: 500000),
      ]);

      expect(totals.owe, 0);
      expect(totals.owed, 500000);
    });

    test('catatan tanpa target tidak ikut dihitung', () {
      final totals = DebtTargetTotals.of([
        record('Biasa', -200000),
        target('Aktif', DebtTargetDirection.owe, amount: 1000000),
      ]);

      expect(totals.owe, 1000000);
      expect(totals.owed, 0);
    });
  });

  group('sortDebtTargets (H-29)', () {
    test('sisa terbesar lebih dulu, lalu tanggal terbaru, lunas di bawah', () {
      final rows = sortDebtTargets([
        target(
          'lunas',
          DebtTargetDirection.owe,
          amount: 9000000,
          paidEntries: 9000000,
          date: '2026-10-20',
        ),
        target(
          'kecil',
          DebtTargetDirection.owe,
          amount: 1000000,
          date: '2026-10-21',
        ),
        target(
          'besar',
          DebtTargetDirection.owe,
          amount: 5000000,
          date: '2026-10-10',
        ),
        target(
          'seri-lebih-baru',
          DebtTargetDirection.owed,
          amount: 1000000,
          date: '2026-10-22',
        ),
      ]);

      expect(rows.map((row) => row.id), [
        'besar',
        'seri-lebih-baru',
        'kecil',
        'lunas',
      ]);
    });

    test('catatan tanpa target tidak pernah masuk tab Target', () {
      final rows = sortDebtTargets([
        record('biasa', -500000),
        target('target', DebtTargetDirection.owe, amount: 100000),
      ]);

      expect(rows.map((row) => row.id), ['target']);
    });
  });

  group('INV-10', () {
    test('jumlah entri bertanda sama dengan nominal yang tampil di daftar', () {
      final entries = [
        entry('a', 150000),
        entry('b', -200000),
        entry('c', 50000),
      ];
      final net = entries.fold<int>(0, (sum, item) => sum + item.amount);
      final summary = DebtSummary.of(entries);

      // Ringkasan dan catatan dihitung dari sumber yang sama.
      expect(summary.net, net);
      expect(summary.net, 0);
    });
  });
}
