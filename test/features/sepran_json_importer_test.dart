import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';
import 'package:pencatatan_keuangan/features/transactions/sepran_json_import.dart';
import 'package:pencatatan_keuangan/features/transactions/sepran_json_importer.dart';

/// Impor JSON harus menghasilkan saldo akhir yang **sama** dengan saldo target
/// di berkas, termasuk untuk pindah saldo yang menyentuh dua rekening.
void main() {
  late AppDatabase db;
  late TransactionRepository transactions;
  late WalletRepository wallets;
  late SepranJsonImporter importer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    transactions = TransactionRepository(db);
    wallets = WalletRepository(db);
    importer = SepranJsonImporter(
      db: db,
      wallets: wallets,
      transactions: transactions,
    );
  });

  tearDown(() => db.close());

  SepranJsonPreview sample() => const SepranJsonParser().parse(
    File('test/fixtures/sepran_sample.json').readAsStringSync(),
  );

  List<SepranNewWallet> createAll(SepranJsonPreview preview) => [
    for (final wallet in preview.wallets)
      SepranNewWallet(
        name: wallet.name,
        openingBalance: wallet.openingBalance ?? 0,
        type: WalletType.other,
        iconKey: 'wallet',
        color: 0xFF1E88E5,
      ),
  ];

  Future<List<Wallet>> walletRows() => db.select(db.wallets).get();

  test('membuat rekening dan menyisipkan semua transaksi', () async {
    final preview = sample();
    final result = await importer.import(
      preview: preview,
      newWallets: createAll(preview),
    );

    expect(result.transactionCount, 6);
    expect(result.newWalletCount, 3);

    final balances = await wallets.watchBalances().first;
    final byName = {for (final wallet in balances) wallet.name: wallet};

    expect(byName, contains('BLU'));
    expect(byName, contains('Gopay'));
    expect(byName, contains('Tunai'));

    // Sesudah impor, saldo akhir setiap rekening sama dengan target di berkas.
    expect(byName['BLU']!.balance, 2500000);
    expect(byName['Gopay']!.balance, -50000);
    expect(byName['Tunai']!.balance, 175001);

    // Enam baris berkas menjadi tujuh baris basis data: pindah saldo = dua.
    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(7));
    expect(
      rows.where((row) => row.kind == TxKind.income.storageValue),
      hasLength(2),
    );
    expect(
      rows.where((row) => row.kind == TxKind.expense.storageValue),
      hasLength(3),
    );
    expect(
      rows.where((row) => row.kind == TxKind.transferOut.storageValue),
      hasLength(1),
    );
    expect(
      rows.where((row) => row.kind == TxKind.transferIn.storageValue),
      hasLength(1),
    );

    final gorengan = rows.firstWhere((row) => row.title == 'Gorengan');
    expect(gorengan.amount, -10000);
    expect(gorengan.time, '08:15');
  });

  test('kedua baris pindah saldo masuk dengan grup yang sama', () async {
    final preview = sample();
    await importer.import(preview: preview, newWallets: createAll(preview));

    final balances = await wallets.watchBalances().first;
    final byName = {for (final wallet in balances) wallet.name: wallet};
    final rows = await db.select(db.transactions).get();

    final outgoing = rows.firstWhere(
      (row) => row.kind == TxKind.transferOut.storageValue,
    );
    final incoming = rows.firstWhere(
      (row) => row.kind == TxKind.transferIn.storageValue,
    );

    expect(outgoing.amount, -100000);
    expect(incoming.amount, 100000);
    expect(outgoing.walletId, byName['BLU']!.id);
    expect(outgoing.counterWalletId, byName['Gopay']!.id);
    expect(incoming.walletId, byName['Gopay']!.id);
    expect(incoming.counterWalletId, byName['BLU']!.id);
    expect(outgoing.transferGroupId, isNotNull);
    expect(outgoing.transferGroupId, incoming.transferGroupId);
  });

  test('impor tidak menaikkan saran judul atau kategori', () async {
    final preview = sample();
    await importer.import(preview: preview, newWallets: createAll(preview));

    for (final kind in [TxKind.income, TxKind.expense]) {
      expect(
        await transactions
            .watchSuggestions(type: SuggestionRules.titleType, kind: kind)
            .first,
        isEmpty,
        reason: 'judul tidak boleh menjadi saran',
      );
      expect(
        await transactions
            .watchSuggestions(type: SuggestionRules.categoryType, kind: kind)
            .first,
        isEmpty,
        reason: 'kategori tidak boleh menjadi saran',
      );
    }
  });

  test('memetakan ke rekening lama tanpa mengubah saldo awalnya', () async {
    final existingId = await wallets.create(
      name: 'Dompet Lama',
      type: WalletType.cash,
      openingBalance: 777,
      iconKey: 'cash',
      color: 0xFF43A047,
    );

    final preview = const SepranJsonParser().parse('''
{
  "wallet_balances": [{"name": "Dompet Lama", "balance": "10000"}],
  "transactions": [
    {"date": "2026-10-01", "type": "income", "amount": 3000, "title": "Bonus", "category": "Gaji", "wallet": "Dompet Lama"}
  ]
}
''');

    final result = await importer.import(
      preview: preview,
      existingWalletIds: {'Dompet Lama': existingId},
    );

    expect(result.newWalletCount, 0);

    final rows = await walletRows();
    final wallet = rows.firstWhere((row) => row.id == existingId);
    expect(wallet.openingBalance, 777);

    final balance = (await wallets.watchBalances().first).firstWhere(
      (row) => row.id == existingId,
    );
    // Bukan 10.000: saldo awal rekening lama tidak diubah.
    expect(balance.balance, 3777);
  });

  test('pemetaan yang kurang ditolak sebelum ada yang ditulis', () async {
    final preview = sample();
    final before = (await walletRows()).length;

    await expectLater(
      importer.import(preview: preview),
      throwsA(isA<ArgumentError>()),
    );

    expect(await walletRows(), hasLength(before));
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('gagal di tengah membatalkan rekening yang baru dibuat', () async {
    // Rekening tujuan sengaja tidak ada, sehingga impor gagal sesudah rekening
    // asal dibuat. Satu transaksi basis data harus mengembalikan semuanya.
    final preview = SepranJsonPreview(
      rows: const [
        SepranJsonTransaction(
          date: '2026-10-01',
          kind: SepranJsonKind.transfer,
          amount: 1000,
          title: 'Pindah',
          category: 'Transfer',
          wallet: 'Rekening Baru',
          counterWallet: 'Tidak Ada',
        ),
      ],
      wallets: const [
        SepranJsonWalletSummary(
          name: 'Rekening Baru',
          targetBalance: 5000,
          openingBalance: 6000,
          transactionCount: 1,
          netFlow: -1000,
        ),
      ],
      skipped: 0,
      skippedBalances: 0,
    );

    await expectLater(
      importer.import(
        preview: preview,
        newWallets: const [
          SepranNewWallet(
            name: 'Rekening Baru',
            openingBalance: 6000,
            type: WalletType.other,
            iconKey: 'wallet',
            color: 0xFF1E88E5,
          ),
        ],
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      (await walletRows()).where((row) => row.name == 'Rekening Baru'),
      isEmpty,
    );
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test(
    'impor tanpa rekening sama sekali tetap bisa membuat rekening',
    () async {
      // Hapus rekening bawaan supaya daftar benar-benar kosong.
      for (final row in await walletRows()) {
        await wallets.softDelete(row.id);
      }
      expect(await wallets.watchBalances().first, isEmpty);

      final preview = sample();
      final result = await importer.import(
        preview: preview,
        newWallets: createAll(preview),
      );

      expect(result.newWalletCount, 3);
      expect((await wallets.watchBalances().first), hasLength(3));
    },
  );
}
