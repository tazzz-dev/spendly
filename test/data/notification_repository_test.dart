import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/notification_repository.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/captured_notification.dart';
import 'package:pencatatan_keuangan/domain/notification_draft.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  late AppDatabase db;
  late NotificationRepository notifications;
  late TransactionRepository transactions;
  late WalletRepository wallets;
  late String cashId;
  late String bankId;

  final occurred = DateTime(2026, 10, 22, 14, 5);
  final postedAt = occurred.millisecondsSinceEpoch;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    transactions = TransactionRepository(db);
    notifications = NotificationRepository(db, transactions);
    wallets = WalletRepository(db);
    cashId = (await wallets.watchBalances().first)
        .firstWhere((wallet) => wallet.isDefault)
        .id;
    bankId = await wallets.create(
      name: 'DANA',
      type: WalletType.ewallet,
      openingBalance: 0,
      iconKey: 'phone',
      color: 0xFF1E88E5,
    );
  });

  tearDown(() => db.close());

  CapturedNotification danaExpense({
    String id = 'event-1',
    String message = 'Pembayaran berhasil Rp25.000 ke Kopi Kenangan',
    int? time,
  }) => CapturedNotification(
    id: id,
    packageName: 'id.dana',
    title: 'Pembayaran Berhasil',
    message: message,
    postedAt: time ?? postedAt,
  );

  Future<List<NotificationDraft>> pending() =>
      notifications.watchPending().first;

  test('notifikasi valid menjadi draft pending dengan tanggal lokal', () async {
    expect(await notifications.ingest(danaExpense()), isTrue);

    final drafts = await pending();
    expect(drafts, hasLength(1));
    final draft = drafts.single;
    expect(draft.appName, 'DANA');
    expect(draft.amount, 25000);
    expect(draft.type, NotificationDraftType.expense);
    expect(draft.date, '2026-10-22');
    expect(draft.time, '14:05');
    expect(draft.walletId, isNull);
    expect(draft.status, NotificationDraftStatus.pending);
    expect(await notifications.watchPendingCount().first, 1);
    expect(await notifications.countPending(), 1);
  });

  test('rekening hasil pemetaan dipakai otomatis', () async {
    await notifications.setMapping(packageName: 'id.dana', walletId: bankId);
    await notifications.ingest(danaExpense());

    final draft = (await pending()).single;
    expect(draft.walletId, bankId);
  });

  test('pemetaan yang dibuat setelah draft mengisi draft pending', () async {
    await notifications.ingest(danaExpense());
    expect((await pending()).single.walletId, isNull);

    await notifications.setMapping(packageName: 'id.dana', walletId: bankId);

    expect((await pending()).single.walletId, bankId);
  });

  test('notifikasi yang sama tidak menjadi dua draft', () async {
    final event = danaExpense();
    await notifications.ingest(event);
    await notifications.ingest(event);

    expect(await pending(), hasLength(1));
  });

  test('notifikasi OTP dibuang dan tidak menjadi draft', () async {
    await notifications.ingest(
      danaExpense(
        id: 'otp',
        message: 'Kode OTP kamu 123456. Jangan berikan kepada siapa pun.',
      ),
    );

    expect(await pending(), isEmpty);
  });

  test('menyetujui draft menulis transaksi dan mengubah saldo', () async {
    await notifications.ingest(danaExpense());
    final draft = (await pending()).single;

    final txId = await notifications.approve(
      draft: draft,
      title: 'Kopi Kenangan',
      category: 'Makanan & Minuman',
      walletId: cashId,
    );

    final tx = await (db.select(
      db.transactions,
    )..where((row) => row.id.equals(txId))).getSingle();
    expect(tx.amount, -25000);
    expect(tx.title, 'Kopi Kenangan');
    expect(tx.category, 'Makanan & Minuman');
    expect(tx.date, '2026-10-22');
    expect(tx.note, contains('DANA'));

    final row = await (db.select(
      db.notificationDrafts,
    )..where((row) => row.id.equals(draft.id))).getSingle();
    expect(row.status, NotificationDraftStatus.approved.storageValue);
    expect(row.approvedTransactionId, txId);
    expect(await pending(), isEmpty);

    final wallet = (await wallets.watchBalances().first).firstWhere(
      (item) => item.id == cashId,
    );
    expect(wallet.balance, -25000);
  });

  test('menolak draft menyembunyikannya dari inbox', () async {
    await notifications.ingest(danaExpense());
    final draft = (await pending()).single;

    await notifications.ignore(draft.id);

    expect(await pending(), isEmpty);
    final row = await (db.select(
      db.notificationDrafts,
    )..where((row) => row.id.equals(draft.id))).getSingle();
    expect(row.status, NotificationDraftStatus.ignored.storageValue);
    expect(row.deletedAt, isNotNull);
  });

  test('judul dan kategori wajib diisi saat menyetujui', () async {
    await notifications.ingest(danaExpense());
    final draft = (await pending()).single;

    expect(
      () => notifications.approve(
        draft: draft,
        title: '  ',
        category: 'Makanan',
        walletId: cashId,
      ),
      throwsArgumentError,
    );
    expect(
      () => notifications.approve(
        draft: draft,
        title: 'Kopi',
        category: '',
        walletId: cashId,
      ),
      throwsArgumentError,
    );
    expect(await pending(), hasLength(1));
  });
}
