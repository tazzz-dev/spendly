import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/core/money.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/features/debts/debt_list_screen.dart';

import 'debt_test_harness.dart';

void main() {
  late DebtTestHarness harness;

  const date = '2026-10-19';

  setUp(() async {
    harness = await DebtTestHarness.create();
  });

  tearDown(() => harness.close());

  Future<void> pumpList(
    WidgetTester tester, {
    MoneyFormat? money,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      harness.app(const DebtListScreen(), money: money, textScale: textScale),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTargetTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('debt-mode-target')));
    await tester.pumpAndSettle();
  }

  Future<String> createOwe({
    String name = 'Kakak',
    int amount = 5000000,
    int paidOpening = 0,
    String when = date,
  }) {
    return harness.repository.createTarget(
      partyName: name,
      date: when,
      targetAmount: amount,
      direction: DebtTargetDirection.owe,
      paidOpening: paidOpening,
    );
  }

  Future<String> createOwed({
    String name = 'Bayu',
    int amount = 2000000,
    String when = date,
  }) {
    return harness.repository.createTarget(
      partyName: name,
      date: when,
      targetAmount: amount,
      direction: DebtTargetDirection.owed,
    );
  }

  debtWidgetTest('dua mode muncul dan bisa berpindah', (tester) async {
    await pumpList(tester);

    expect(find.byKey(const Key('debt-mode-normal')), findsOneWidget);
    expect(find.byKey(const Key('debt-mode-target')), findsOneWidget);
    expect(find.text('Menerima'), findsOneWidget);
    expect(find.text('Total sisa utang'), findsNothing);

    await openTargetTab(tester);

    expect(find.text('Total sisa utang'), findsOneWidget);
    expect(find.text('Total sisa piutang'), findsOneWidget);
    expect(find.text('Target Baru'), findsOneWidget);
    expect(find.text('Menerima'), findsNothing);
  });

  debtWidgetTest('total utang dan piutang terpisah, tidak dijumlahkan', (
    tester,
  ) async {
    await createOwe();
    await createOwed();

    await pumpList(tester);
    await openTargetTab(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('target-total-owe')),
        matching: find.text('Rp5.000.000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('target-total-owed')),
        matching: find.text('Rp2.000.000'),
      ),
      findsOneWidget,
    );
    // Tidak ada angka gabungan 7 juta atau selisih 3 juta di kepala.
    expect(find.text('Rp7.000.000'), findsNothing);
    expect(find.text('Rp3.000.000'), findsNothing);
  });

  debtWidgetTest('kartu menampilkan terbayar, sisa, dan progress bar', (
    tester,
  ) async {
    final debtId = await createOwe();
    final cash = await harness.cashWalletId();
    await harness.repository.addPayment(
      debtId: debtId,
      magnitude: 200000,
      date: date,
      walletId: cash,
    );

    await pumpList(tester);
    await openTargetTab(tester);

    expect(find.text('Terbayar Rp200.000 dari Rp5.000.000'), findsOneWidget);
    expect(find.text('Sisa Rp4.800.000'), findsOneWidget);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.04, 1e-9));
  });

  debtWidgetTest('badge Lunas dan kelebihan bayar tampil', (tester) async {
    await createOwe(amount: 1000, paidOpening: 1200);

    await pumpList(tester);
    await openTargetTab(tester);

    expect(find.text('Lunas'), findsOneWidget);
    expect(find.text('Lunas, lebih Rp200'), findsOneWidget);
    expect(find.text('Terbayar Rp1.200 dari Rp1.000'), findsOneWidget);
  });

  debtWidgetTest('utang yang dihapuskan menampilkan sisa dihapuskan', (
    tester,
  ) async {
    final debtId = await createOwe();
    await harness.repository.setSettled(debtId, true);

    await pumpList(tester);
    await openTargetTab(tester);

    expect(find.text('Lunas'), findsOneWidget);
    expect(find.text('Sisa dihapuskan Rp5.000.000'), findsOneWidget);
  });

  debtWidgetTest('keadaan kosong tab Target mengajak membuat target', (
    tester,
  ) async {
    await pumpList(tester);
    await openTargetTab(tester);

    expect(find.text('Belum ada target utang'), findsOneWidget);
    expect(
      find.text('Tekan Target Baru untuk membuat target pertama.'),
      findsOneWidget,
    );
  });

  debtWidgetTest('Normal menampilkan badge Target tetapi nominal tetap net', (
    tester,
  ) async {
    final debtId = await createOwe();
    final cash = await harness.cashWalletId();
    await harness.repository.addPayment(
      debtId: debtId,
      magnitude: 200000,
      date: date,
      walletId: cash,
    );

    await pumpList(tester);

    expect(find.byKey(Key('target-badge-$debtId')), findsOneWidget);
    // Nominal baris Normal adalah net entri (-200.000), bukan target/sisa.
    final tile = find.byType(ListTile).first;
    expect(
      find.descendant(of: tile, matching: find.text('200.000')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text('4.800.000')),
      findsNothing,
    );
  });

  debtWidgetTest('pencarian menyaring daftar tanpa mengubah total header', (
    tester,
  ) async {
    final kakakId = await createOwe(name: 'Kakak');
    final bayuId = await createOwed(name: 'Bayu');

    await pumpList(tester);
    await openTargetTab(tester);

    await tester.enterText(find.byType(TextField), 'Kakak');
    await tester.pumpAndSettle();

    expect(find.byKey(Key('target-card-$kakakId')), findsOneWidget);
    expect(find.byKey(Key('target-card-$bayuId')), findsNothing);

    // Total dihitung dari seluruh catatan, bukan hasil pencarian.
    expect(
      find.descendant(
        of: find.byKey(const Key('target-total-owe')),
        matching: find.text('Rp5.000.000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('target-total-owed')),
        matching: find.text('Rp2.000.000'),
      ),
      findsOneWidget,
    );
  });

  debtWidgetTest('format desimal mengikuti setelan', (tester) async {
    await createOwe();

    await pumpList(tester, money: MoneyFormat(showDecimals: true));
    await openTargetTab(tester);

    expect(find.text('Rp5.000.000,00'), findsOneWidget);
    expect(find.text('Rp5.000.000'), findsNothing);
  });

  debtWidgetTest('font 200% tidak memotong nama panjang', (tester) async {
    await createOwe(
      name: 'Kakak Sepupu Jauh Dari Kampung Seberang Sungai',
      amount: 1234567,
    );

    await pumpList(tester, textScale: 2);
    await openTargetTab(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kakak Sepupu'), findsOneWidget);
  });
}
