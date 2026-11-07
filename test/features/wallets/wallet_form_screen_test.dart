import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/wallets/wallet_form_screen.dart';

/// Test layar Ubah Rekening.
///
/// Yang dijaga di sini adalah keputusan SPEC K-6: kolom saldo pada layar ubah
/// berisi **saldo saat ini**, dan selisihnya menjadi Koreksi Saldo. Saldo awal
/// tidak boleh ikut berubah, karena itu akan menggeser seluruh riwayat.
void main() {
  late AppDatabase db;
  late WalletRepository wallets;
  late TransactionRepository transactions;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    wallets = WalletRepository(db);
    transactions = TransactionRepository(db);
  });

  tearDown(() => db.close());

  Future<WalletBalance> createWalletWithIncome() async {
    final id = await wallets.create(
      name: 'Gopay',
      type: WalletType.ewallet,
      openingBalance: 100000,
      iconKey: 'phone',
      color: 0xFF1E88E5,
    );
    await transactions.createSimple(
      kind: TxKind.income,
      amount: 50000,
      walletId: id,
      title: 'Gaji',
      category: 'Gaji',
      date: '2026-10-19',
    );

    final list = await wallets.watchBalances().first;
    return list.firstWhere((wallet) => wallet.id == id);
  }

  Future<void> pumpForm(WidgetTester tester, WalletBalance wallet) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: WalletFormScreen(initial: wallet)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan saldo saat ini, bukan saldo awal', (tester) async {
    final wallet = await createWalletWithIncome();
    expect(wallet.openingBalance, 100000);
    expect(wallet.balance, 150000);

    await pumpForm(tester, wallet);

    expect(find.text('Saldo Saat Ini'), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('wallet_balance')),
    );
    expect(field.controller?.text, '150.000');
  });

  testWidgets('mengubah saldo mencatat Koreksi Saldo dan menjaga saldo awal', (
    tester,
  ) async {
    final wallet = await createWalletWithIncome();
    await pumpForm(tester, wallet);

    await tester.enterText(find.byKey(const Key('wallet_balance')), '200000');
    await tester.tap(find.byKey(const Key('wallet_save')));
    await tester.pumpAndSettle();

    // Jangan membaca `watchBalances()` lagi di dalam test widget: stream drift
    // yang ditutup di akhir test meninggalkan timer pending. Cukup periksa
    // baris tersimpan; saldo adalah saldo awal + pemasukan + koreksi.
    final walletRow = await (db.select(
      db.wallets,
    )..where((row) => row.id.equals(wallet.id))).getSingle();
    expect(walletRow.openingBalance, 100000);

    final rows = await db.select(db.transactions).get();
    final corrections = rows
        .where((row) => row.kind == TxKind.correction.storageValue)
        .toList();
    expect(corrections, hasLength(1));
    expect(corrections.single.amount, 50000);
    expect(corrections.single.note, 'Penyesuaian dari Ubah Rekening');
    expect(
      walletRow.openingBalance + 50000 + corrections.single.amount,
      200000,
    );
  });
}
