import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_rules.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/features/debts/debt_target_form_screen.dart';

import 'debt_test_harness.dart';

void main() {
  late DebtTestHarness harness;

  const date = '2026-10-19';

  setUp(() async {
    harness = await DebtTestHarness.create();
  });

  tearDown(() => harness.close());

  Future<String> createOwe() {
    return harness.repository.createTarget(
      partyName: 'Kakak',
      date: date,
      targetAmount: 5000000,
      direction: DebtTargetDirection.owe,
    );
  }

  debtWidgetTest('target nol ditolak dengan pesan yang jelas', (tester) async {
    await tester.pumpWidget(harness.app(const DebtTargetFormScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Kakak');
    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text(DebtRules.targetNotPositive), findsOneWidget);
    expect(await harness.repository.watchRecords().first, isEmpty);
  });

  debtWidgetTest('target lebih kecil dari yang dibayar meminta konfirmasi', (
    tester,
  ) async {
    final debtId = await createOwe();
    final cash = await harness.cashWalletId();
    await harness.repository.addPayment(
      debtId: debtId,
      magnitude: 3000000,
      date: date,
      walletId: cash,
    );

    final record = await harness.repository.watchRecord(debtId).first;
    expect(record, isNotNull);

    await tester.pumpWidget(harness.app(DebtTargetFormScreen(initial: record)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '2000000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text(DebtRules.targetBelowPaidWarning), findsOneWidget);

    // Batal berarti tidak ada yang berubah.
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(
      (await harness.repository.watchRecord(debtId).first)!.targetAmount,
      5000000,
    );

    // Lanjutkan menyimpan target baru; kelebihan bayar tampil sebagai Lunas.
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    final updated = await harness.repository.watchRecord(debtId).first;
    expect(updated!.targetAmount, 2000000);
    expect(updated.progress!.paid, 3000000);
    expect(updated.progress!.overpaid, 1000000);
    expect(updated.progress!.isSettled, isTrue);
  });
}
