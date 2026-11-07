import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/core/dates.dart';
import 'package:pencatatan_keuangan/core/money.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/transactions/transaction_list_screen.dart';

/// Test daftar harian: navigasi antar hari, kartu ringkasan, dan tampilan baris.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  TransactionEntry entry({
    required String id,
    required TxKind kind,
    required int amount,
    String? title,
    String? category,
    String? walletId,
    String? walletName,
  }) => TransactionEntry(
    id: id,
    kind: kind,
    amount: amount,
    date: AppDate.today(),
    title: title,
    category: category,
    walletId: walletId,
    walletName: walletName,
  );

  Future<void> pumpList(
    WidgetTester tester,
    List<TransactionEntry> entries, {
    List<WalletBalance> wallets = const [],
  }) async {
    final today = AppDate.today();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dayTransactionsProvider.overrideWith(
            (ref, date) => Stream.value(date == today ? entries : const []),
          ),
          walletBalancesProvider.overrideWith((ref) => Stream.value(wallets)),
          moneyFormatProvider.overrideWithValue(
            MoneyFormat(showDecimals: true),
          ),
        ],
        child: const MaterialApp(home: TransactionListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kepala menampilkan hari ini dan kartu ringkasan terisi', (
    tester,
  ) async {
    await pumpList(tester, [
      entry(
        id: 'a',
        kind: TxKind.income,
        amount: 500000,
        title: 'Gaji',
        category: 'Gaji',
      ),
      entry(
        id: 'b',
        kind: TxKind.expense,
        amount: -158000,
        title: 'Nasi goreng',
        category: 'Makanan',
      ),
    ]);

    expect(find.text(AppDate.weekdayReadable(AppDate.today())), findsOneWidget);
    expect(find.text('Rp500.000,00'), findsOneWidget);
    expect(find.text('Rp158.000,00'), findsOneWidget);
    expect(find.text('Rp342.000,00'), findsOneWidget);

    // SPEC T-11: kategori jadi baris utama, judul baris kedua.
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Nasi goreng'), findsOneWidget);

    // SPEC T-11: pengeluaran bertanda minus; pemasukan tanpa tanda plus.
    expect(find.text('500.000,00'), findsOneWidget);
    expect(find.text('-158.000,00'), findsOneWidget);
  });

  testWidgets('SPEC T-17: Selisih ditampilkan tanpa tanda minus', (
    tester,
  ) async {
    await pumpList(tester, [
      entry(
        id: 'a',
        kind: TxKind.expense,
        amount: -4000,
        title: 'Kopi',
        category: 'Minuman',
      ),
      entry(
        id: 'b',
        kind: TxKind.expense,
        amount: -154000,
        title: 'Belanja',
        category: 'Belanja',
      ),
    ]);

    expect(
      find.text('Rp158.000,00'),
      findsNWidgets(2),
    ); // Pengeluaran & Selisih
  });

  testWidgets('tombol kurung memindah hari, lalu kembali', (tester) async {
    await pumpList(tester, [
      entry(
        id: 'a',
        kind: TxKind.income,
        amount: 10000,
        title: 'Judul',
        category: 'Kategori',
      ),
    ]);

    final today = AppDate.today();
    final yesterday = AppDate.shift(today, -1);

    await tester.tap(find.byKey(const Key('day_previous')));
    await tester.pumpAndSettle();

    expect(find.text(AppDate.weekdayReadable(yesterday)), findsOneWidget);
    expect(find.text('Belum ada transaksi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('day_next')));
    await tester.pumpAndSettle();

    expect(find.text(AppDate.weekdayReadable(today)), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
  });

  testWidgets('SPEC T-14/T-15: menu tambah hanya tiga pilihan, tanpa Koreksi', (
    tester,
  ) async {
    await pumpList(tester, const []);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Pindah Saldo'), findsOneWidget);
    // Kartu ringkasan juga memakai kata "Pemasukan" dan "Pengeluaran", jadi
    // keduanya muncul dua kali: sekali di kartu, sekali di menu.
    expect(find.text('Pemasukan'), findsNWidgets(2));
    expect(find.text('Pengeluaran'), findsNWidgets(2));
    expect(find.text('Koreksi Saldo'), findsNothing);
  });

  testWidgets('filter dompet hanya menampilkan transaksi dompet itu', (
    tester,
  ) async {
    const cash = WalletBalance(
      id: 'cash',
      name: 'Uang Tunai',
      type: WalletType.cash,
      openingBalance: 0,
      balance: 0,
      isDefault: true,
    );
    const gopay = WalletBalance(
      id: 'gopay',
      name: 'GoPay',
      type: WalletType.ewallet,
      openingBalance: 0,
      balance: 0,
      isDefault: false,
    );

    await pumpList(
      tester,
      [
        entry(
          id: 'a',
          kind: TxKind.expense,
          amount: -25000,
          title: 'Kopi',
          category: 'Minuman',
          walletId: 'cash',
          walletName: 'Uang Tunai',
        ),
        entry(
          id: 'b',
          kind: TxKind.expense,
          amount: -50000,
          title: 'Top up',
          category: 'Transportasi',
          walletId: 'gopay',
          walletName: 'GoPay',
        ),
      ],
      wallets: const [cash, gopay],
    );

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Top up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wallet_filter_gopay')));
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsNothing);
    expect(find.text('Top up'), findsOneWidget);
    // Ringkasan ikut menyaring, bukan hanya daftar barisnya.
    expect(find.text('Rp50.000,00'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('wallet_filter_all')));
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Top up'), findsOneWidget);
  });
}
