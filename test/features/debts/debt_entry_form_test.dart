import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/features/debts/debt_entry_form_screen.dart';

import 'debt_test_harness.dart';

void main() {
  late DebtTestHarness harness;

  const date = '2026-10-19';

  setUp(() async {
    harness = await DebtTestHarness.create();
  });

  tearDown(() => harness.close());

  Future<String> createTarget() {
    return harness.repository.createTarget(
      partyName: 'Kakak',
      date: date,
      targetAmount: 5000000,
      direction: DebtTargetDirection.owe,
    );
  }

  Future<void> pumpPaymentForm(WidgetTester tester, String debtId) async {
    await tester.pumpWidget(
      harness.app(
        DebtEntryFormScreen(
          debtId: debtId,
          targetDirection: DebtTargetDirection.owe,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  debtWidgetTest(
    'menyimpan tanpa rekening menampilkan peringatan dan ditolak',
    (tester) async {
      final debtId = await createTarget();
      await pumpPaymentForm(tester, debtId);

      expect(find.text('Bayar Target'), findsOneWidget);
      expect(
        find.text('Rekening (wajib diisi untuk pembayaran target)'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, '200000');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tanpa rekening, saldo tidak berkurang'),
        findsOneWidget,
      );
      expect(await harness.repository.watchEntries(debtId).first, isEmpty);
      expect(
        (await harness.repository.watchRecord(debtId).first)!.progress!.paid,
        0,
      );
    },
  );

  debtWidgetTest('memilih rekening lalu menyimpan mencatat pembayaran', (
    tester,
  ) async {
    final debtId = await createTarget();
    await pumpPaymentForm(tester, debtId);

    await tester.enterText(find.byType(TextField).first, '200000');

    // Buka pemilih rekening, lalu pilih rekening bawaan.
    await tester.tap(find.text('Tanpa rekening'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang Tunai'));
    await tester.pumpAndSettle();
    expect(find.text('Uang Tunai'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final entries = await harness.repository.watchEntries(debtId).first;
    expect(entries, hasLength(1));
    expect(entries.single.amount, -200000);
    expect(entries.single.walletId, await harness.cashWalletId());

    final record = await harness.repository.watchRecord(debtId).first;
    expect(record!.progress!.paid, 200000);
    expect(record.progress!.remaining, 4800000);
  });
}
