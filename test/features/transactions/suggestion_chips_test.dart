import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/tx_suggestion.dart';
import 'package:pencatatan_keuangan/features/transactions/suggestion_chips.dart';

/// Saran kategori harus ringkas: satu baris, beberapa chip awal, lalu
/// menyempit mengikuti teks yang diketik.
void main() {
  final suggestions = [
    for (final (index, name) in [
      'Makanan',
      'Minuman',
      'Transportasi',
      'Belanja',
      'Gaji',
    ].indexed)
      TxSuggestion(
        id: 's$index',
        type: SuggestionRules.categoryType,
        name: name,
        kind: TxKind.expense,
        useCount: 10 - index,
      ),
  ];

  Future<void> pumpChips(
    WidgetTester tester, {
    required String query,
    ValueChanged<String>? onSelected,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suggestionsProvider.overrideWith(
            (ref, key) => Stream.value(suggestions),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SuggestionChips(
              type: SuggestionRules.categoryType,
              kind: TxKind.expense,
              query: query,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('awalnya hanya tiga chip dalam satu baris', (tester) async {
    await pumpChips(tester, query: '');

    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Minuman'), findsOneWidget);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('Belanja'), findsNothing);
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('mengetik menyaring saran seperti pencarian', (tester) async {
    await pumpChips(tester, query: 'makan');

    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Minuman'), findsNothing);

    await pumpChips(tester, query: 'min');
    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.text('Minuman'), findsOneWidget);
  });

  testWidgets('teks tanpa saran yang cocok menyembunyikan deretan chip', (
    tester,
  ) async {
    await pumpChips(tester, query: 'tidak-ada');

    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('menekan chip memilih teksnya', (tester) async {
    String? selected;
    await pumpChips(tester, query: '', onSelected: (value) => selected = value);

    await tester.tap(find.widgetWithText(ActionChip, 'Minuman'));
    expect(selected, 'Minuman');
  });
}
