import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/movement.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';

/// Impor menulis banyak baris sekaligus lewat [TransactionRepository.createMany].
/// Berkas uji ini menjaga tiga janji: nominal bertanda benar, saldo mengikuti,
/// dan saran tidak dibanjiri judul lama.
void main() {
  late AppDatabase db;
  late TransactionRepository repository;
  late WalletRepository wallets;
  late String cashId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
    wallets = WalletRepository(db);
    cashId = (await wallets.watchBalances().first)
        .firstWhere((wallet) => wallet.isDefault)
        .id;
  });

  tearDown(() => db.close());

  Future<int> balanceOf(String walletId) async =>
      (await wallets.watchBalances().first)
          .firstWhere((wallet) => wallet.id == walletId)
          .balance;

  Future<int> useCountOf(String walletId) async {
    final row = await (db.select(
      db.wallets,
    )..where((wallet) => wallet.id.equals(walletId))).getSingle();
    return row.useCount;
  }

  TxDraft income(int amount, String date, {String title = 'Gaji'}) =>
      Movement.income(
        amount: amount,
        walletId: cashId,
        title: title,
        category: 'Gaji',
        date: date,
      );

  TxDraft expense(int amount, String date, {String title = 'Makan'}) =>
      Movement.expense(
        amount: amount,
        walletId: cashId,
        title: title,
        category: 'Makanan',
        date: date,
      );

  test('menyimpan semua baris dalam satu kali jalan', () async {
    final count = await repository.createMany([
      income(100000, '2026-10-01'),
      expense(25000, '2026-10-02'),
      expense(15000, '2026-10-02'),
    ]);

    expect(count, 3);
    expect(await db.select(db.transactions).get(), hasLength(3));
    expect(await balanceOf(cashId), 60000);

    final rows = await repository.watchAll().first;
    expect(rows, hasLength(3));
    // Terbaru lebih dulu.
    expect(rows.first.date, '2026-10-02');
  });

  test('daftar kosong tidak menulis apa pun', () async {
    expect(await repository.createMany(const []), 0);
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test(
    'saran tidak dinaikkan, pemakaian rekening naik sekali per rekening',
    () async {
      final before = await useCountOf(cashId);

      await repository.createMany([income(1000, '2026-10-01')]);
      final afterOne = await useCountOf(cashId);

      await repository.createMany([
        income(1000, '2026-10-02'),
        income(1000, '2026-10-03'),
        income(1000, '2026-10-04'),
      ]);
      final afterFour = await useCountOf(cashId);

      // Satu impor = satu kenaikan untuk rekening itu, bukan satu per baris.
      expect(afterOne - before, greaterThan(0));
      expect(afterFour - afterOne, afterOne - before);

      // Impor seratus baris lama bukan bukti judul itu sering dipakai sekarang.
      expect(
        await repository
            .watchSuggestions(
              type: SuggestionRules.titleType,
              kind: TxKind.income,
            )
            .first,
        isEmpty,
      );
    },
  );
}
