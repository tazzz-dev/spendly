import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/features/transactions/transfer_form_screen.dart';

/// Test form Pindah Saldo: pesan galat S-2 apa adanya dan tanpa field judul.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> pumpTransfer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletBalancesProvider.overrideWith(
            (ref) => Stream.value(const <WalletBalance>[]),
          ),
        ],
        child: const MaterialApp(home: TransferFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('belum diisi menampilkan pesan pindah saldo dari tx_rules', (
    tester,
  ) async {
    await pumpTransfer(tester);

    await tester.tap(find.byKey(const Key('transfer_save')));
    await tester.pumpAndSettle();

    expect(find.text(TransactionRules.requiredTransfer), findsOneWidget);
  });

  testWidgets('SPEC S-9: tidak ada field Judul maupun Kategori', (
    tester,
  ) async {
    await pumpTransfer(tester);

    expect(find.text('Judul'), findsNothing);
    expect(find.text('Kategori'), findsNothing);
    // Jumlah memakai kalkulator, bukan papan tik, jadi belum terisi.
    expect(find.text('Belum diisi'), findsOneWidget);
  });
}
