import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/features/debts/debt_detail_screen.dart';

import 'debt_test_harness.dart';

void main() {
  late DebtTestHarness harness;

  const date = '2026-10-19';

  setUp(() async {
    harness = await DebtTestHarness.create();
  });

  tearDown(() => harness.close());

  Future<void> pumpDetail(WidgetTester tester, String debtId) async {
    await tester.pumpWidget(harness.app(DebtDetailScreen(debtId: debtId)));
    await tester.pumpAndSettle();
  }

  debtWidgetTest('detail target menampilkan progress dan aksi Bayar', (
    tester,
  ) async {
    final debtId = await harness.repository.createTarget(
      partyName: 'Kakak',
      date: date,
      targetAmount: 5000000,
      direction: DebtTargetDirection.owe,
    );
    final cash = await harness.cashWalletId();
    await harness.repository.addPayment(
      debtId: debtId,
      magnitude: 200000,
      date: date,
      walletId: cash,
    );

    await pumpDetail(tester, debtId);

    expect(find.text('Terbayar Rp200.000 dari Rp5.000.000'), findsOneWidget);
    expect(find.text('Sisa Rp4.800.000'), findsOneWidget);
    expect(find.text('Bayar'), findsOneWidget);
    expect(find.text('Ubah target'), findsOneWidget);
    expect(find.text('Hapus target'), findsOneWidget);
    // Tiga aksi H-13 tidak ditambah.
    expect(find.byIcon(Icons.how_to_reg_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  debtWidgetTest('catatan Normal menawarkan Jadikan Target', (tester) async {
    final debtId = await harness.repository.createDebt(
      partyName: 'Fajar',
      date: date,
    );

    await pumpDetail(tester, debtId);

    expect(find.text('Jadikan Target'), findsOneWidget);
    expect(find.text('Ubah target'), findsNothing);
    expect(find.text('Hapus target'), findsNothing);
  });

  debtWidgetTest('status Lunas otomatis tampil saat target terbayar penuh', (
    tester,
  ) async {
    final debtId = await harness.repository.createTarget(
      partyName: 'Kakak',
      date: date,
      targetAmount: 1000000,
      direction: DebtTargetDirection.owe,
      paidOpening: 1000000,
    );

    await pumpDetail(tester, debtId);

    // Satu di anak judul AppBar, satu di badge kartu progress.
    expect(find.text('Lunas'), findsNWidgets(2));
    expect(find.text('Sisa Rp0'), findsOneWidget);
  });
}
