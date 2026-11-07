import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/core/dates.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/tx_suggestion.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/transactions/transaction_form_screen.dart';

/// Test layar form transaksi: pesan galat, tanggal awal, salin transaksi, dan
/// saran judul/kategori.
///
/// Basis datanya sungguhan (SQLite di memori) supaya penulisan benar-benar
/// diuji, tetapi penyedia yang membaca `Stream` drift diganti dengan nilai
/// tetap. Tanpa itu, `flutter_test` mengeluh "Timer is still pending" saat
/// stream drift ditutup di akhir test.
void main() {
  late AppDatabase db;
  late String cashId;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Membaca rekening bawaan sekaligus memicu pembuatan skema (SPEC G-8).
    final wallets = await db.select(db.wallets).get();
    cashId = wallets.firstWhere((wallet) => wallet.isDefault).id;
  });

  tearDown(() => db.close());

  List<WalletBalance> walletList() => [
    WalletBalance(
      id: cashId,
      name: 'Uang Tunai',
      type: WalletType.cash,
      openingBalance: 0,
      balance: 0,
      isDefault: true,
    ),
  ];

  List<TxSuggestion> suggestionList(SuggestionQuery query) => [
    TxSuggestion(
      id: 's-${query.type}',
      type: query.type,
      name: query.type == SuggestionRules.titleType ? 'Gaji' : 'Gaji Bulanan',
      kind: query.kind,
      useCount: 1,
    ),
  ];

  Future<void> pumpForm(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          walletBalancesProvider.overrideWith(
            (ref) => Stream.value(walletList()),
          ),
          suggestionsProvider.overrideWith(
            (ref, query) => Stream.value(suggestionList(query)),
          ),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tx_save')));
    await tester.pumpAndSettle();
  }

  Future<void> pickCashWallet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tx_wallet_from')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang Tunai').last);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String? amount,
    String? title,
    String? category,
  }) async {
    if (amount != null) {
      await tester.enterText(find.byKey(const Key('tx_amount')), amount);
    }
    if (title != null) {
      await tester.enterText(find.byKey(const Key('tx_title')), title);
    }
    if (category != null) {
      await tester.enterText(find.byKey(const Key('tx_category')), category);
    }
  }

  testWidgets('pemasukan menampilkan pesan wajib persis dari tx_rules', (
    tester,
  ) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.income),
    );

    await tapSave(tester);

    expect(find.text(TransactionRules.requiredFields), findsOneWidget);
  });

  testWidgets('koreksi saldo memakai pesan wajibnya sendiri', (tester) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.correction),
    );

    await tapSave(tester);

    expect(find.text(TransactionRules.requiredCorrection), findsOneWidget);
  });

  testWidgets('judul kepanjangan ditolak dengan pesan dari aturan domain', (
    tester,
  ) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.expense),
    );

    await fill(
      tester,
      amount: '10000',
      title: 'a' * (TransactionRules.maxTitleLength + 1),
      category: 'Makanan',
    );
    await pickCashWallet(tester);
    await tapSave(tester);

    expect(
      find.text(
        'Judul paling panjang ${TransactionRules.maxTitleLength} huruf.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('nominal melewati batas ditolak dengan pesan dari tx_rules', (
    tester,
  ) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.income),
    );

    await fill(
      tester,
      amount: '${TransactionRules.maxAmount + 1}',
      title: 'Gaji',
      category: 'Gaji',
    );
    await pickCashWallet(tester);
    await tapSave(tester);

    expect(
      find.text(
        'Jumlah paling besar ${TransactionRules.maxAmount ~/ 1000000000} miliar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('form membuka pemilih dompet kosong, tanpa dompet bawaan', (
    tester,
  ) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.expense),
    );

    expect(find.text('Pilih Dompet / Rekening'), findsOneWidget);

    await fill(tester, amount: '10000', title: 'Kopi', category: 'Minuman');
    await tapSave(tester);

    expect(find.text(TransactionRules.walletRequired), findsOneWidget);
    final rows = await db.select(db.transactions).get();
    expect(rows, isEmpty);
  });

  testWidgets('koreksi saldo menerima nominal negatif', (tester) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.correction),
    );

    await tester.tap(find.byKey(const Key('tx_wallet_from')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uang Tunai').last);
    await tester.pumpAndSettle();

    await fill(tester, amount: '-25000');
    await tapSave(tester);

    expect(find.text(TransactionRules.requiredCorrection), findsNothing);

    final rows = await db.select(db.transactions).get();
    expect(rows.single.amount, -25000);
    expect(rows.single.kind, TxKind.correction.storageValue);
  });

  testWidgets('Salin Transaksi membuka form dengan jumlah terisi', (
    tester,
  ) async {
    const copy = TransactionEntry(
      id: 'x',
      kind: TxKind.expense,
      amount: -25000,
      date: '2026-10-19',
      title: 'Kopi',
      category: 'Minuman',
    );

    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.expense, copyFrom: copy),
    );

    final amount = tester.widget<TextField>(find.byKey(const Key('tx_amount')));
    expect(amount.controller?.text, '25.000');

    final title = tester.widget<TextField>(find.byKey(const Key('tx_title')));
    expect(title.controller?.text, 'Kopi');
  });

  testWidgets('tanggal form mengikuti hari yang sedang dilihat', (
    tester,
  ) async {
    await pumpForm(
      tester,
      const TransactionFormScreen(
        mode: TxFormMode.income,
        initialDate: '2026-01-02',
      ),
    );

    expect(find.text(AppDate.readable('2026-01-02')), findsOneWidget);
  });

  testWidgets('memilih saran judul mengisi kategori yang pernah dipakai', (
    tester,
  ) async {
    await TransactionRepository(db).createSimple(
      kind: TxKind.income,
      amount: 1000000,
      walletId: cashId,
      title: 'Gaji',
      category: 'Gaji Bulanan',
      date: '2026-10-01',
      time: '08:00',
    );

    await pumpForm(
      tester,
      const TransactionFormScreen(mode: TxFormMode.income),
    );

    // Dua chip muncul: satu untuk judul, satu untuk kategori.
    expect(find.widgetWithText(ActionChip, 'Gaji'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Gaji Bulanan'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Gaji'));
    await tester.pumpAndSettle();

    final title = tester.widget<TextField>(find.byKey(const Key('tx_title')));
    final category = tester.widget<TextField>(
      find.byKey(const Key('tx_category')),
    );
    expect(title.controller?.text, 'Gaji');
    expect(category.controller?.text, 'Gaji Bulanan');
  });
}
