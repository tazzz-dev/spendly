import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/daily_summary.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';

TransactionEntry _entry({
  required String id,
  required TxKind kind,
  required int amount,
  String? category,
  String? title,
}) {
  return TransactionEntry(
    id: id,
    kind: kind,
    amount: amount,
    date: '2026-10-19',
    category: category,
    title: title,
  );
}

void main() {
  group('DailySummary', () {
    test('hari kosong menghasilkan nol di ketiga kolom', () {
      final summary = DailySummary.of(const []);

      expect(summary.income, 0);
      expect(summary.expense, 0);
      expect(summary.difference, 0);
      expect(summary.isEmpty, isTrue);
    });

    test('pengeluaran dihitung sebagai besar mutlak, bukan negatif', () {
      final summary = DailySummary.of([
        _entry(id: 'a', kind: TxKind.expense, amount: -4000),
        _entry(id: 'b', kind: TxKind.expense, amount: -41000),
        _entry(id: 'c', kind: TxKind.expense, amount: -113000),
      ]);

      expect(summary.income, 0);
      expect(summary.expense, 158000);
    });

    test('pemasukan dan pengeluaran dijumlahkan terpisah', () {
      final summary = DailySummary.of([
        _entry(id: 'a', kind: TxKind.income, amount: 500000),
        _entry(id: 'b', kind: TxKind.expense, amount: -158000),
      ]);

      expect(summary.income, 500000);
      expect(summary.expense, 158000);
      expect(summary.difference, 342000);
    });

    test(
      'INV-6: pindah saldo tidak pernah masuk pemasukan atau pengeluaran',
      () {
        final summary = DailySummary.of([
          _entry(id: 'out', kind: TxKind.transferOut, amount: -5000000),
          _entry(id: 'in', kind: TxKind.transferIn, amount: 5000000),
        ]);

        expect(summary.income, 0);
        expect(summary.expense, 0);
        expect(summary.isEmpty, isTrue);
      },
    );

    test('INV-6: koreksi saldo juga tidak masuk hitungan', () {
      final summary = DailySummary.of([
        _entry(id: 'k', kind: TxKind.correction, amount: 75000),
      ]);

      expect(summary.income, 0);
      expect(summary.expense, 0);
    });

    test('urutan baris tidak memengaruhi hasil', () {
      final rows = [
        _entry(id: 'a', kind: TxKind.income, amount: 100000),
        _entry(id: 'b', kind: TxKind.expense, amount: -25000),
        _entry(id: 'c', kind: TxKind.transferOut, amount: -10000),
        _entry(id: 'd', kind: TxKind.transferIn, amount: 10000),
      ];

      final forward = DailySummary.of(rows);
      final backward = DailySummary.of(rows.reversed);

      expect(forward.income, backward.income);
      expect(forward.expense, backward.expense);
    });

    test('SPEC T-17: Selisih tampil tanpa tanda minus', () {
      // Satu-satunya hari yang terverifikasi dari Sepran: pemasukan 0,
      // pengeluaran 158.000, Selisih tertulis 158.000 — bukan −158.000.
      final summary = DailySummary.of([
        _entry(id: 'a', kind: TxKind.expense, amount: -4000),
        _entry(id: 'b', kind: TxKind.expense, amount: -41000),
        _entry(id: 'c', kind: TxKind.expense, amount: -113000),
      ]);

      expect(summary.difference, 158000);
      // Nilai bertanda tetap tersedia untuk pemakaian lain.
      expect(summary.netDifference, -158000);
    });

    test('Selisih adalah besar mutlak pada kedua arah', () {
      final untung = DailySummary.of([
        _entry(id: 'a', kind: TxKind.income, amount: 200000),
        _entry(id: 'b', kind: TxKind.expense, amount: -50000),
      ]);
      final rugi = DailySummary.of([
        _entry(id: 'a', kind: TxKind.income, amount: 50000),
        _entry(id: 'b', kind: TxKind.expense, amount: -200000),
      ]);

      expect(untung.difference, 150000);
      expect(rugi.difference, 150000);
    });
  });

  group('label baris daftar (SPEC T-11)', () {
    test('pemasukan dan pengeluaran memakai kategori sebagai baris utama', () {
      final entry = _entry(
        id: 'a',
        kind: TxKind.expense,
        amount: -25000,
        category: 'Makanan',
        title: 'Nasi goreng',
      );

      expect(entry.primaryLabel, 'Makanan');
      expect(entry.secondaryLabel, 'Nasi goreng');
    });

    test('kategori kosong jatuh ke judul', () {
      final entry = _entry(
        id: 'a',
        kind: TxKind.income,
        amount: 10000,
        title: 'Gaji',
      );

      expect(entry.primaryLabel, 'Gaji');
    });

    test('pindah saldo menyebut arahnya, bukan kategori yang tidak ada', () {
      const out = TransactionEntry(
        id: 'out',
        kind: TxKind.transferOut,
        amount: -250000,
        date: '2026-10-19',
        counterWalletName: 'BCA',
      );
      const incoming = TransactionEntry(
        id: 'in',
        kind: TxKind.transferIn,
        amount: 250000,
        date: '2026-10-19',
        counterWalletName: 'Uang Tunai',
      );

      expect(out.primaryLabel, 'Pindah Saldo');
      expect(out.secondaryLabel, 'Ke BCA');
      expect(incoming.secondaryLabel, 'Dari Uang Tunai');
    });

    test('koreksi saldo jatuh ke nama rekening bila tanpa keterangan', () {
      const withNote = TransactionEntry(
        id: 'a',
        kind: TxKind.correction,
        amount: -15000,
        date: '2026-10-19',
        note: 'Selisih catatan',
        walletName: 'BCA',
      );
      const withoutNote = TransactionEntry(
        id: 'b',
        kind: TxKind.correction,
        amount: 15000,
        date: '2026-10-19',
        walletName: 'BCA',
      );
      const bare = TransactionEntry(
        id: 'c',
        kind: TxKind.correction,
        amount: 15000,
        date: '2026-10-19',
      );

      expect(withNote.secondaryLabel, 'Selisih catatan');
      expect(withoutNote.secondaryLabel, 'BCA');
      expect(bare.secondaryLabel, 'Koreksi Saldo');
    });
  });
}
