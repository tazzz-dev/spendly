import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pencatatan_keuangan/core/money.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/providers.dart';
import 'package:pencatatan_keuangan/domain/notification_draft.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_balance.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/notifications/notification_review_screen.dart';

/// Layar konfirmasi adalah satu-satunya pintu dari draft notifikasi ke
/// transaksi resmi. Test ini menjaga dua hal yang mudah rusak saat UI diubah:
/// judul/kategori tetap wajib, dan transaksi baru memakai nominal bertanda.
void main() {
  late AppDatabase db;
  late String cashId;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final wallets = await db.select(db.wallets).get();
    cashId = wallets.firstWhere((wallet) => wallet.isDefault).id;
  });

  tearDown(() => db.close());

  NotificationDraft draft() => NotificationDraft(
    id: 'draft-1',
    packageName: 'id.dana',
    appName: 'DANA',
    rawTitle: 'Pembayaran Berhasil',
    rawMessage: 'Pembayaran berhasil Rp25.000 ke Kopi Kenangan',
    amount: 25000,
    type: NotificationDraftType.expense,
    walletId: cashId,
    occurredAt: DateTime(2026, 10, 22, 14, 5).millisecondsSinceEpoch,
    date: '2026-10-22',
    time: '14:05',
    status: NotificationDraftStatus.pending,
    sourceKey: 'id.dana|1|Pembayaran Berhasil|Pembayaran berhasil Rp25.000 ke Kopi Kenangan',
    approvedTransactionId: null,
    createdAt: 1,
    updatedAt: 1,
  );

  Future<void> pumpReview(WidgetTester tester) async {
    final draftValue = draft();
    await db
        .into(db.notificationDrafts)
        .insert(
          NotificationDraftsCompanion.insert(
            id: draftValue.id,
            packageName: draftValue.packageName,
            appName: draftValue.appName,
            rawTitle: draftValue.rawTitle,
            rawMessage: draftValue.rawMessage,
            amount: draftValue.amount,
            type: draftValue.type.storageValue,
            walletId: Value(draftValue.walletId),
            occurredAt: draftValue.occurredAt,
            date: draftValue.date,
            time: Value(draftValue.time),
            sourceKey: draftValue.sourceKey,
            createdAt: draftValue.createdAt,
            updatedAt: draftValue.updatedAt,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          moneyFormatProvider.overrideWithValue(
            MoneyFormat(showDecimals: true),
          ),
          walletBalancesProvider.overrideWith(
            (ref) => Stream.value([
              WalletBalance(
                id: cashId,
                name: 'Uang Tunai',
                type: WalletType.cash,
                openingBalance: 0,
                balance: 0,
                isDefault: true,
              ),
            ]),
          ),
          suggestionsProvider.overrideWith(
            (ref, query) => Stream.value(const []),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => NotificationReviewScreen(draft: draftValue),
                  ),
                ),
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

  testWidgets('judul dan kategori wajib diisi sebelum transaksi dibuat', (
    tester,
  ) async {
    await pumpReview(tester);

    await tester.tap(find.byKey(const Key('notification_save')));
    await tester.pumpAndSettle();
    expect(find.text(TransactionRules.requiredFields), findsOneWidget);
    // Snackbar validasi menutupi tombol simpan; tunggu sampai hilang.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('notification_title')),
      'Kopi Kenangan',
    );
    await tester.tap(find.byKey(const Key('notification_save')));
    await tester.pumpAndSettle();
    expect(find.text(TransactionRules.requiredFields), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('notification_category')),
      'Makanan & Minuman',
    );
    await tester.tap(find.byKey(const Key('notification_save')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.amount, -25000);
    expect(rows.single.title, 'Kopi Kenangan');
    expect(rows.single.category, 'Makanan & Minuman');
    expect(rows.single.note, 'Dari notifikasi DANA');
  });
}
