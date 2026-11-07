import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/features/transactions/calculator_sheet.dart';

/// Test kalkulator nominal. Perilakunya harus sama dengan
/// `lib/domain/calculator.dart`, termasuk menolak angka tunggal yang melewati
/// batas nominal.
void main() {
  Future<void> openCalculator(WidgetTester tester, {int? initial}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showCalculator(context, initial: initial),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }

  FilledButton useButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const Key('calculator_use')));

  testWidgets('hasil dihitung dan bisa dipakai', (tester) async {
    await openCalculator(tester, initial: 2500);

    await tester.tap(find.widgetWithText(FilledButton, '×'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '3'));
    await tester.pumpAndSettle();

    expect(find.text('Rp7.500'), findsOneWidget);
    expect(useButton(tester).onPressed, isNotNull);
  });

  testWidgets('angka tunggal yang melewati batas nominal ditolak', (
    tester,
  ) async {
    await openCalculator(tester, initial: 1000000000000);

    expect(find.text('—'), findsOneWidget);
    expect(useButton(tester).onPressed, isNull);
  });

  testWidgets('nilai tepat di batas nominal masih diterima', (tester) async {
    await openCalculator(tester, initial: 999999999999);

    expect(find.text('Rp999.999.999.999'), findsOneWidget);
    expect(useButton(tester).onPressed, isNotNull);
  });

  testWidgets('pembagian dengan nol ditolak, bukan menghasilkan tak-hingga', (
    tester,
  ) async {
    await openCalculator(tester);

    await tester.tap(find.widgetWithText(FilledButton, '5'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '÷'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '0'));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(useButton(tester).onPressed, isNull);
  });
}
