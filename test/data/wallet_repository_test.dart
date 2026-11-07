// `isNotNull` disembunyikan dari drift: nama itu dipakai drift untuk ekspresi
// SQL, sementara di berkas ini yang dimaksud adalah pencocok dari flutter_test.
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/wallet_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = WalletRepository(db);
  });

  tearDown(() => db.close());

  Future<String> createWallet(String name) => repository.create(
    name: name,
    type: WalletType.bank,
    openingBalance: 0,
    iconKey: 'bank',
    color: 0xFF1E88E5,
  );

  test('pemasangan pertama membuat tepat satu rekening bawaan', () async {
    final wallets = await repository.watchBalances().first;

    expect(wallets.length, 1);
    expect(wallets.single.name, 'Uang Tunai');
    expect(wallets.single.isDefault, isTrue);
    expect(wallets.single.balance, 0);
  });

  test('saldo adalah saldo awal ditambah pergerakan bertanda', () async {
    final id = await createWallet('BCA');
    final now = DateTime.now().millisecondsSinceEpoch;

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'tx-1',
            kind: 'income',
            walletId: id,
            title: const Value('Gaji'),
            amount: 500000,
            date: '2026-10-19',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 'tx-2',
            kind: 'expense',
            walletId: id,
            title: const Value('Kopi'),
            amount: -18000,
            date: '2026-10-19',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final wallets = await repository.watchBalances().first;
    final bca = wallets.firstWhere((wallet) => wallet.id == id);
    expect(bca.balance, 482000);
  });

  group('SPEC G-9, nama unik', () {
    test('nama yang belum dipakai dianggap bebas', () async {
      expect(await repository.isNameTaken('BCA'), isFalse);
    });

    test('nama kembar terdeteksi', () async {
      await createWallet('BCA');
      expect(await repository.isNameTaken('BCA'), isTrue);
    });

    test('nama boleh sama dengan dirinya sendiri saat menyunting', () async {
      final id = await createWallet('BCA');
      expect(await repository.isNameTaken('BCA', exceptId: id), isFalse);
      expect(await repository.isNameTaken('BCA', exceptId: 'id-lain'), isTrue);
    });

    test('spasi di ujung tidak membuat nama lolos pemeriksaan', () async {
      await createWallet('BCA');
      expect(await repository.isNameTaken('  BCA  '), isTrue);
    });

    test(
      'nama sama walau beda besar-kecil huruf tetap dianggap terpakai',
      () async {
        // SPEC G-9: "BCA" dan "bca" adalah rekening yang sama di mata pengguna.
        await createWallet('BCA');
        expect(await repository.isNameTaken('bca'), isTrue);
        expect(await repository.isNameTaken('  bCa '), isTrue);
      },
    );

    test('menyunting rekening tidak bentrok dengan dirinya sendiri', () async {
      final id = await createWallet('BCA');
      expect(await repository.isNameTaken('bca', exceptId: id), isFalse);
      expect(await repository.isNameTaken('BCA', exceptId: id), isFalse);
      expect(await repository.isNameTaken('bca', exceptId: 'id-lain'), isTrue);
    });

    test('nama rekening yang sudah dihapus bebas dipakai lagi', () async {
      final id = await createWallet('BCA');
      await repository.softDelete(id);
      expect(await repository.isNameTaken('bca'), isFalse);
    });

    test('nama rekening yang sudah dihapus bisa dipakai lagi', () async {
      // Inilah cacat yang ditutup index unik parsial. Kalau keunikannya
      // ditegakkan index penuh, membuat ulang "BCA" di sini akan gagal,
      // karena baris lamanya masih ada walau sudah dihapus lunak.
      final pertama = await createWallet('BCA');
      await repository.softDelete(pertama);

      expect(await repository.isNameTaken('BCA'), isFalse);
      await expectLater(createWallet('BCA'), completes);
    });
  });

  group('SPEC R-4, R-5, G-8', () {
    test('rekening bawaan tidak boleh dihapus', () async {
      final wallets = await repository.watchBalances().first;
      final verdict = await repository.checkDelete(wallets.single.id);

      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.isDefault);
    });

    test('rekening yang masih dipakai tidak boleh dihapus', () async {
      final id = await createWallet('BCA');
      final now = DateTime.now().millisecondsSinceEpoch;

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              kind: 'expense',
              walletId: id,
              amount: -10000,
              date: '2026-10-19',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final verdict = await repository.checkDelete(id);
      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.inUse);
      expect(verdict.usageCount, 1);
    });

    test('rekening pasangan pindah saldo juga dihitung', () async {
      // Kalau pemeriksaan hanya melihat wallet_id, aturan R-4 bocor lewat
      // rekening tujuan pindah saldo.
      final id = await createWallet('BCA');
      // Rekening asal harus benar-benar ada: kunci asing ditegakkan.
      final tunai = (await repository.watchBalances().first).firstWhere(
        (wallet) => wallet.isDefault,
      );
      final now = DateTime.now().millisecondsSinceEpoch;

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              kind: 'transfer_in',
              walletId: tunai.id,
              counterWalletId: Value(id),
              amount: 25000,
              date: '2026-10-19',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final verdict = await repository.checkDelete(id);
      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.inUse);
    });

    test('transaksi yang sudah dihapus tidak menghalangi', () async {
      final id = await createWallet('BCA');
      final now = DateTime.now().millisecondsSinceEpoch;

      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-1',
              kind: 'expense',
              walletId: id,
              amount: -10000,
              date: '2026-10-19',
              createdAt: now,
              updatedAt: now,
              deletedAt: Value(now),
            ),
          );

      expect((await repository.checkDelete(id)).allowed, isTrue);
    });

    test('rekening bersih boleh dihapus', () async {
      final id = await createWallet('BCA');
      expect((await repository.checkDelete(id)).allowed, isTrue);
    });

    test('hapus lunak menyembunyikan rekening dari daftar', () async {
      final id = await createWallet('BCA');
      await repository.softDelete(id);

      final wallets = await repository.watchBalances().first;
      expect(wallets.any((wallet) => wallet.id == id), isFalse);
      // Barisnya masih ada di basis data, hanya ditandai.
      final row = await (db.select(
        db.wallets,
      )..where((wallet) => wallet.id.equals(id))).getSingle();
      expect(row.deletedAt, isNotNull);
    });
  });

  group('penjaga skema di basis data', () {
    // Ini yang diperiksa di HP lewat berkas basis data sungguhan. Test di sini
    // menjaga janji yang sama tetap berlaku setiap kali skema dibangun ulang.
    test(
      'index unik parsial idx_wallets_name_active benar-benar ada',
      () async {
        final row = await db
            .customSelect(
              "SELECT sql FROM sqlite_master "
              "WHERE type = 'index' AND name = 'idx_wallets_name_active'",
            )
            .getSingleOrNull();

        expect(row, isNotNull);
        final sql = row!.read<String>('sql');
        expect(sql.toUpperCase(), contains('UNIQUE'));
        // Parsial: hanya berlaku di antara baris yang belum dihapus.
        expect(sql, contains('WHERE deleted_at IS NULL'));

        final list = await db
            .customSelect("PRAGMA index_list('wallets')")
            .get();
        final ours = list.where(
          (r) => r.read<String>('name') == 'idx_wallets_name_active',
        );
        expect(ours, hasLength(1));
        expect(ours.single.read<int>('unique'), 1);
        expect(ours.single.read<int>('partial'), 1);
      },
    );

    test('index menolak rekening aktif kedua bernama persis sama', () async {
      await createWallet('BCA');
      final now = DateTime.now().millisecondsSinceEpoch;

      // Ditulis langsung ke tabel, melewati pemeriksaan repository: inilah
      // yang menguji jaring pengaman basis datanya, bukan kode Dart-nya.
      await expectLater(
        db
            .into(db.wallets)
            .insert(
              WalletsCompanion.insert(
                id: 'rekening-duplikat',
                name: 'BCA',
                type: 'bank',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('penegakan kunci asing menyala di koneksi aplikasi', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.read<int>('foreign_keys'), 1);
    });

    test('transaksi tanpa rekening yang ada benar-benar ditolak', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await expectLater(
        db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'tx-tanpa-rekening',
                kind: 'expense',
                walletId: 'rekening-tidak-ada',
                amount: -1000,
                date: '2026-10-19',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('entri hutang yang menunjuk rekening hantu juga ditolak', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              id: 'hutang-1',
              partyName: 'ZZ Test',
              date: '2026-10-19',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await expectLater(
        db
            .into(db.debtEntries)
            .insert(
              DebtEntriesCompanion.insert(
                id: 'entri-1',
                debtId: 'hutang-1',
                amount: 1000,
                date: '2026-10-19',
                walletId: const Value('rekening-tidak-ada'),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test('menyunting rekening mengubah nama, tipe, dan saldo awal', () async {
    final id = await createWallet('BCA');
    await repository.update(
      id: id,
      name: 'BCA Digital',
      type: WalletType.ewallet,
      openingBalance: 75000,
      iconKey: 'phone',
      color: 0xFF43A047,
    );

    final wallets = await repository.watchBalances().first;
    final wallet = wallets.firstWhere((row) => row.id == id);
    expect(wallet.name, 'BCA Digital');
    expect(wallet.type, WalletType.ewallet);
    expect(wallet.openingBalance, 75000);
    expect(wallet.balance, 75000);
    expect(wallet.iconKey, 'phone');
  });
}
