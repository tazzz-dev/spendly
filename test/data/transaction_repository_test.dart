// `isNotNull` dan `isNull` disembunyikan dari drift: kedua nama itu dipakai
// drift untuk ekspresi SQL, sementara di berkas ini yang dimaksud adalah
// pencocok dari flutter_test.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/tx_suggestion.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repository;
  late WalletRepository wallets;
  late String cashId;

  const date = '2026-10-19';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
    wallets = WalletRepository(db);
    // Rekening bawaan dari pemasangan pertama (SPEC G-8) sudah ada.
    cashId = (await wallets.watchBalances().first)
        .firstWhere((wallet) => wallet.isDefault)
        .id;
  });

  tearDown(() => db.close());

  Future<String> createWallet(String name) => wallets.create(
    name: name,
    type: WalletType.bank,
    openingBalance: 0,
    iconKey: 'bank',
    color: 0xFF1E88E5,
  );

  Future<List<TxRow>> allRows() => db.select(db.transactions).get();

  Future<TxRow> rowById(String id) => (db.select(
    db.transactions,
  )..where((row) => row.id.equals(id))).getSingle();

  Future<String> addIncome({
    int amount = 50000,
    String walletId = '',
    String title = 'Gaji',
    String category = 'Gaji',
    String? time,
  }) => repository.createSimple(
    kind: TxKind.income,
    amount: amount,
    walletId: walletId.isEmpty ? cashId : walletId,
    title: title,
    category: category,
    date: date,
    time: time,
  );

  group('menyimpan pemasukan dan pengeluaran (RW-5)', () {
    test(
      'pemasukan tersimpan bertanda positif apa pun kiriman pemanggil',
      () async {
        final id = await addIncome(amount: -50000);

        final row = await rowById(id);
        expect(row.kind, 'income');
        expect(row.amount, 50000);
        expect(row.date, date);
        expect(row.title, 'Gaji');
        expect(row.category, 'Gaji');
        // RW-12: hanya pindah saldo yang tanpa judul dan kategori.
        expect(row.transferGroupId, isNull);
        expect(row.counterWalletId, isNull);
      },
    );

    test('pengeluaran tersimpan bertanda negatif', () async {
      final id = await repository.createSimple(
        kind: TxKind.expense,
        amount: 25000,
        walletId: cashId,
        title: 'Nasi goreng',
        category: 'Makanan',
        date: date,
        note: 'Makan siang',
      );

      final row = await rowById(id);
      expect(row.kind, 'expense');
      expect(row.amount, -25000);
      expect(row.note, 'Makan siang');
    });

    test('nominal nol ditolak sebelum menyentuh basis data', () async {
      await expectLater(
        repository.createSimple(
          kind: TxKind.income,
          amount: 0,
          walletId: cashId,
          title: 'x',
          category: 'y',
          date: date,
        ),
        throwsArgumentError,
      );

      expect(await allRows(), isEmpty);
    });

    test('createSimple menolak jenis pindah saldo dan koreksi', () async {
      for (final kind in [
        TxKind.transferOut,
        TxKind.transferIn,
        TxKind.correction,
      ]) {
        await expectLater(
          repository.createSimple(
            kind: kind,
            amount: 10000,
            walletId: cashId,
            title: 'x',
            category: 'y',
            date: date,
          ),
          throwsArgumentError,
        );
      }
      expect(await allRows(), isEmpty);
    });
  });

  group('pindah saldo (RW-2, RW-4, RW-12)', () {
    test('menulis dua baris terhubung, berimbang, dan tanpa judul', () async {
      final bca = await createWallet('BCA');

      final group = await repository.createTransfer(
        amount: 250000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
        note: 'Tarik tunai',
      );

      final rows = await allRows();
      expect(rows, hasLength(2));
      expect(rows.every((row) => row.transferGroupId == group), isTrue);

      final out = rows.firstWhere((row) => row.kind == 'transfer_out');
      final incoming = rows.firstWhere((row) => row.kind == 'transfer_in');

      expect(out.walletId, cashId);
      expect(out.counterWalletId, bca);
      expect(out.amount, -250000);

      expect(incoming.walletId, bca);
      expect(incoming.counterWalletId, cashId);
      expect(incoming.amount, 250000);

      // INV-4.
      expect(out.amount + incoming.amount, 0);

      for (final row in rows) {
        expect(row.title, isNull);
        expect(row.category, isNull);
      }
    });

    test(
      'rekening asal sama dengan tujuan ditolak, tidak ada yang tertulis',
      () async {
        await expectLater(
          repository.createTransfer(
            amount: 10000,
            fromWalletId: cashId,
            toWalletId: cashId,
            date: date,
          ),
          throwsArgumentError,
        );

        expect(await allRows(), isEmpty);
      },
    );

    test('INV-3: rekening tujuan yang tidak ada ditolak, tidak ada baris', () async {
      await expectLater(
        repository.createTransfer(
          amount: 10000,
          fromWalletId: cashId,
          toWalletId: 'tidak-ada',
          date: date,
        ),
        throwsA(anything),
      );

      // Kunci asing menolak, dan transaksi basis datanya dibatalkan seluruhnya.
      expect(await allRows(), isEmpty);
    });

    test('menghapus satu baris menghapus pasangannya juga', () async {
      final bca = await createWallet('BCA');
      await repository.createTransfer(
        amount: 250000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      final rows = await allRows();
      // Yang dihapus sengaja baris tujuan, untuk memastikan pencarian pasangan
      // tidak hanya bekerja dari sisi "keluar".
      final incoming = rows.firstWhere((row) => row.kind == 'transfer_in');

      await repository.softDelete(incoming.id);

      final after = await allRows();
      expect(after.every((row) => row.deletedAt != null), isTrue);
      expect(await repository.watchDay(date).first, isEmpty);
    });
  });

  group('koreksi saldo (K-5)', () {
    test('nominal negatif tersimpan apa adanya', () async {
      final id = await repository.createCorrection(
        amount: -15000,
        walletId: cashId,
        date: date,
        note: 'Selisih catatan',
      );

      final row = await rowById(id);
      expect(row.kind, 'correction');
      expect(row.amount, -15000);
      expect(row.title, 'Koreksi Saldo');
      expect(row.category, isNull);
    });

    test('nominal nol ditolak', () async {
      await expectLater(
        repository.createCorrection(amount: 0, walletId: cashId, date: date),
        throwsArgumentError,
      );

      expect(await allRows(), isEmpty);
    });
  });

  group('daftar harian', () {
    test('urut menurut jam, baris tanpa jam di akhir', () async {
      await addIncome(title: 'Tanpa jam');
      await addIncome(title: 'Malam', time: '21:15');
      await addIncome(title: 'Pagi', time: '07:30');

      final entries = await repository.watchDay(date).first;
      expect(entries.map((entry) => entry.title), [
        'Pagi',
        'Malam',
        'Tanpa jam',
      ]);
    });

    test(
      'hanya hari yang diminta, dan yang terhapus disembunyikan (RW-9)',
      () async {
        await addIncome(title: 'Hari ini');
        final gone = await addIncome(title: 'Dibuang');
        await repository.createSimple(
          kind: TxKind.income,
          amount: 10000,
          walletId: cashId,
          title: 'Besok',
          category: 'Lain',
          date: '2026-10-20',
        );

        await repository.softDelete(gone);

        final entries = await repository.watchDay(date).first;
        expect(entries.map((entry) => entry.title), ['Hari ini']);
      },
    );

    test('rekening dan rekening pasangan sudah berupa nama', () async {
      final bca = await createWallet('BCA');
      await repository.createTransfer(
        amount: 250000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      final entries = await repository.watchDay(date).first;
      expect(entries, hasLength(2));

      final out = entries.firstWhere(
        (entry) => entry.kind == TxKind.transferOut,
      );
      expect(out.walletName, 'Uang Tunai');
      expect(out.counterWalletName, 'BCA');
      expect(out.primaryLabel, 'Pindah Saldo');
    });

    test('jam sama diurutkan menurut created_at', () async {
      final first = await addIncome(title: 'Lebih dulu', time: '10:00');
      final second = await addIncome(title: 'Kemudian', time: '10:00');

      // Dua baris bisa lahir pada milidetik yang sama, jadi urutannya
      // ditetapkan lebih dulu supaya test menguji created_at, bukan nasib.
      await (db.update(db.transactions)..where((row) => row.id.equals(first)))
          .write(const TransactionsCompanion(createdAt: Value(1000)));
      await (db.update(db.transactions)..where((row) => row.id.equals(second)))
          .write(const TransactionsCompanion(createdAt: Value(2000)));

      final entries = await repository.watchDay(date).first;
      expect(entries.map((entry) => entry.title).toList(), [
        'Lebih dulu',
        'Kemudian',
      ]);
    });

    test('jam kosong diperlakukan sama seperti tanpa jam', () async {
      await addIncome(title: 'Kosong', time: '');
      await addIncome(title: 'Terisi', time: '06:00');

      final entries = await repository.watchDay(date).first;
      expect(entries.map((entry) => entry.title).toList(), [
        'Terisi',
        'Kosong',
      ]);
    });
  });

  group('saran judul dan kategori (SG-1, C-3)', () {
    Future<List<TxSuggestion>> suggestionsOf({
      required String type,
      required TxKind kind,
    }) => repository.watchSuggestions(type: type, kind: kind).first;

    test('judul dan kategori dicatat sekali saat transaksi disimpan', () async {
      await addIncome();

      final titles = await suggestionsOf(
        type: SuggestionRules.titleType,
        kind: TxKind.income,
      );
      final categories = await suggestionsOf(
        type: SuggestionRules.categoryType,
        kind: TxKind.income,
      );

      expect(titles.single.name, 'Gaji');
      expect(titles.single.useCount, 1);
      expect(categories.single.name, 'Gaji');
      expect(categories.single.useCount, 1);
    });

    test(
      'pemakaian berulang menaikkan penghitung, bukan menambah baris',
      () async {
        await addIncome();
        await addIncome();

        final titles = await suggestionsOf(
          type: SuggestionRules.titleType,
          kind: TxKind.income,
        );
        expect(titles, hasLength(1));
        expect(titles.single.useCount, 2);
      },
    );

    test(
      'C-3: nama sama pada jenis berbeda adalah dua entri terpisah',
      () async {
        await addIncome(title: 'Jajan', category: 'Jajan');
        await repository.createSimple(
          kind: TxKind.expense,
          amount: 10000,
          walletId: cashId,
          title: 'Jajan',
          category: 'Jajan',
          date: date,
        );

        final income = await suggestionsOf(
          type: SuggestionRules.titleType,
          kind: TxKind.income,
        );
        final expense = await suggestionsOf(
          type: SuggestionRules.titleType,
          kind: TxKind.expense,
        );

        expect(income.single.kind, TxKind.income);
        expect(expense.single.kind, TxKind.expense);
      },
    );

    test('pindah saldo tidak menambah saran apa pun', () async {
      final bca = await createWallet('BCA');
      await repository.createTransfer(
        amount: 10000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      expect(
        await suggestionsOf(
          type: SuggestionRules.titleType,
          kind: TxKind.income,
        ),
        isEmpty,
      );
    });

    test('teks kosong atau hanya spasi tidak menghasilkan saran', () async {
      await addIncome(title: '   ', category: 'Makanan');

      final titles = await suggestionsOf(
        type: SuggestionRules.titleType,
        kind: TxKind.income,
      );
      expect(titles, isEmpty);
    });

    test('urutan: paling sering dipakai lebih dulu', () async {
      await addIncome(title: 'Sering', category: 'Makanan');
      await addIncome(title: 'Sering');
      await addIncome(title: 'Sering');
      await addIncome(title: 'Jarang');

      final titles = await suggestionsOf(
        type: SuggestionRules.titleType,
        kind: TxKind.income,
      );
      expect(titles.map((row) => row.name).toList(), ['Sering', 'Jarang']);
    });

    test('hanya sejumlah tetap saran yang dikembalikan', () async {
      await addIncome(title: 'Sering');
      await addIncome(title: 'Sering');
      for (var index = 0; index < SuggestionRules.visibleCount + 3; index++) {
        await addIncome(title: 'Judul$index');
      }

      final titles = await suggestionsOf(
        type: SuggestionRules.titleType,
        kind: TxKind.income,
      );
      expect(titles, hasLength(SuggestionRules.visibleCount));
      expect(titles.first.name, 'Sering');
    });
  });

  group('menghapus transaksi (T-8, C-6)', () {
    test('hapus lunak menyembunyikan baris, tapi barisnya masih ada', () async {
      final id = await addIncome();

      await repository.softDelete(id);

      expect(await repository.watchDay(date).first, isEmpty);
      expect((await rowById(id)).deletedAt, isNotNull);
    });

    test(
      'menghapus menurunkan penghitung saran, dengan batas bawah nol',
      () async {
        final id = await addIncome();

        await repository.softDelete(id);
        var titles = await repository
            .watchSuggestions(
              type: SuggestionRules.titleType,
              kind: TxKind.income,
            )
            .first;
        expect(titles.single.useCount, 0);

        // SPEC C-6: penghitung tidak boleh menjadi negatif walau dihapus lagi.
        await repository.softDelete(id);
        titles = await repository
            .watchSuggestions(
              type: SuggestionRules.titleType,
              kind: TxKind.income,
            )
            .first;
        expect(titles.single.useCount, 0);
      },
    );

    test('penghitung jenis lain tidak ikut turun', () async {
      await addIncome(title: 'Jajan', category: 'Jajan');
      final id = await repository.createSimple(
        kind: TxKind.expense,
        amount: 10000,
        walletId: cashId,
        title: 'Jajan',
        category: 'Jajan',
        date: date,
      );

      await repository.softDelete(id);

      final income = await repository
          .watchSuggestions(
            type: SuggestionRules.titleType,
            kind: TxKind.income,
          )
          .first;
      expect(income.single.useCount, 1);
    });

    test('id yang tidak ada hanya diam, tidak melempar', () async {
      await expectLater(repository.softDelete('tidak-ada'), completes);
    });
  });

  group('frekuensi pemakaian rekening (SPEC R-3)', () {
    test('setiap pemakaian menambah 11, bukan 1', () async {
      await addIncome();
      await addIncome();

      final row = await (db.select(
        db.wallets,
      )..where((wallet) => wallet.id.equals(cashId))).getSingle();
      expect(row.useCount, 22);
    });

    test('pindah saldo menaikkan kedua rekening yang dipakai', () async {
      final bca = await createWallet('BCA');
      await repository.createTransfer(
        amount: 10000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      final rows = await db.select(db.wallets).get();
      final source = rows.firstWhere((wallet) => wallet.id == cashId);
      final destination = rows.firstWhere((wallet) => wallet.id == bca);

      expect(source.useCount, 11);
      expect(destination.useCount, 11);
    });
  });

  group('INV-1 terhadap basis data sungguhan', () {
    test('saldo rekening sama dengan jumlah baris bertanda', () async {
      final bca = await createWallet('BCA');

      await addIncome(amount: 500000, walletId: bca);
      await repository.createSimple(
        kind: TxKind.expense,
        amount: 18000,
        walletId: bca,
        title: 'Kopi',
        category: 'Minuman',
        date: date,
      );
      await repository.createTransfer(
        amount: 100000,
        fromWalletId: bca,
        toWalletId: cashId,
        date: date,
      );
      await repository.createCorrection(
        amount: -2000,
        walletId: bca,
        date: date,
      );

      final rows = await allRows();
      final expected = rows
          .where((row) => row.walletId == bca)
          .fold<int>(0, (sum, row) => sum + row.amount);

      final balances = await wallets.watchBalances().first;
      final wallet = balances.firstWhere((row) => row.id == bca);
      expect(wallet.balance, expected);
      expect(wallet.balance, 500000 - 18000 - 100000 - 2000);
    });
  });

  group('mengubah catatan (T-5)', () {
    test(
      'nominal dan judul berubah, tanda tetap ditentukan Movement',
      () async {
        final id = await addIncome(amount: 50000);

        await repository.updateSimple(
          id: id,
          kind: TxKind.income,
          // Pemanggil mengirim positif; Movement yang menentukan tandanya.
          amount: 75000,
          walletId: cashId,
          title: 'Gaji Baru',
          category: 'Gaji',
          date: date,
          time: '08:00',
        );

        final row = await rowById(id);
        expect(row.amount, 75000);
        expect(row.title, 'Gaji Baru');
        expect(row.time, '08:00');
      },
    );

    test('pengeluaran yang diubah tetap bertanda negatif', () async {
      final id = await repository.createSimple(
        kind: TxKind.expense,
        amount: 25000,
        walletId: cashId,
        title: 'Makan',
        category: 'Makan',
        date: date,
      );

      await repository.updateSimple(
        id: id,
        kind: TxKind.expense,
        amount: 30000,
        walletId: cashId,
        title: 'Makan',
        category: 'Makan',
        date: date,
      );

      expect((await rowById(id)).amount, -30000);
    });
  });

  group('pindah saldo diubah sebagai sepasang (S-7)', () {
    test('kedua sisi ikut berubah nominal dan rekeningnya', () async {
      final bca = await createWallet('BCA');
      final groupId = await repository.createTransfer(
        amount: 100000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      await repository.updateTransfer(
        groupId: groupId,
        amount: 125000,
        fromWalletId: bca,
        toWalletId: cashId,
        date: date,
        time: '09:30',
      );

      final rows = await allRows();
      expect(rows, hasLength(2));

      final out = rows.firstWhere((row) => row.kind == 'transfer_out');
      final into = rows.firstWhere((row) => row.kind == 'transfer_in');

      expect(out.amount, -125000);
      expect(out.walletId, bca);
      expect(out.counterWalletId, cashId);
      expect(out.time, '09:30');

      expect(into.amount, 125000);
      expect(into.walletId, cashId);
      expect(into.counterWalletId, bca);

      // Uang berpindah, tidak hilang: jumlah seluruh saldo tetap nol.
      final balances = await wallets.watchBalances().first;
      final total = balances.fold<int>(
        0,
        (sum, wallet) => sum + wallet.balance,
      );
      expect(total, 0);
    });
  });

  group('hapus lalu urungkan (T-7, T-8)', () {
    test('baris kembali utuh setelah diurungkan', () async {
      final id = await addIncome(amount: 40000);

      await repository.softDelete(id);
      expect((await rowById(id)).deletedAt, isNotNull);

      await repository.restore(id);
      final row = await rowById(id);
      expect(row.deletedAt, isNull);
      expect(row.amount, 40000);
      expect(row.kind, 'income');
    });

    test('urungkan memulihkan kedua sisi pindah saldo', () async {
      final bca = await createWallet('BCA');
      await repository.createTransfer(
        amount: 50000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: date,
      );

      final rows = await allRows();
      final one = rows.firstWhere((row) => row.kind == 'transfer_out');

      await repository.softDelete(one.id);
      expect(
        (await allRows()).where((row) => row.deletedAt != null),
        hasLength(2),
      );

      await repository.restore(one.id);
      expect((await allRows()).where((row) => row.deletedAt != null), isEmpty);

      final balances = await wallets.watchBalances().first;
      final total = balances.fold<int>(
        0,
        (sum, wallet) => sum + wallet.balance,
      );
      expect(total, 0);
    });
  });

  group('cermin hutang (H-3)', () {
    test(
      'baris dari entri hutang ditandai supaya tidak disunting di sini',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: 'cermin-1',
                kind: 'income',
                walletId: cashId,
                amount: 75000,
                date: date,
                createdAt: now,
                updatedAt: now,
                title: const Value('Ayam'),
                category: const Value('Hutang Piutang'),
                debtEntryId: const Value('entri-1'),
              ),
            );

        final entry = await repository.findById('cermin-1');

        expect(entry, isNotNull);
        expect(entry!.debtEntryId, 'entri-1');
        expect(entry.isDebtMirror, isTrue);
        // Tanpa penanda ini, halaman detail akan membiarkan pengguna menyunting
        // cerminnya dan catatan hutangnya jadi bercerita lain.
        expect(entry.category, 'Hutang Piutang');
      },
    );

    test('baris biasa tidak dianggap cermin', () async {
      final id = await addIncome(amount: 10000);
      final entry = await repository.findById(id);

      expect(entry, isNotNull);
      expect(entry!.debtEntryId, isNull);
      expect(entry.isDebtMirror, isFalse);
    });
  });

  group('INV-2 terhadap basis data sungguhan', () {
    test(
      'Total Saldo sama dengan saldo awal ditambah seluruh baris bertanda',
      () async {
        final bca = await createWallet('BCA');
        await addIncome(amount: 500000, walletId: bca);
        await repository.createSimple(
          kind: TxKind.expense,
          amount: 18000,
          walletId: cashId,
          title: 'Kopi',
          category: 'Minuman',
          date: date,
        );
        await repository.createCorrection(
          amount: -2000,
          walletId: bca,
          date: date,
        );

        final balances = await wallets.watchBalances().first;
        final displayedTotal = balances.fold<int>(
          0,
          (sum, w) => sum + w.balance,
        );
        final openings = balances.fold<int>(
          0,
          (sum, w) => sum + w.openingBalance,
        );
        final fromRows = (await allRows())
            .where((row) => row.deletedAt == null)
            .fold<int>(0, (sum, row) => sum + row.amount);

        expect(displayedTotal, openings + fromRows);
      },
    );
  });

  group('saran kategori dari judul (SPEC C-7)', () {
    test(
      'mengembalikan kategori yang terakhir dipakai untuk judul itu',
      () async {
        await addIncome(title: 'Gaji', category: 'Gaji Bulanan');
        await repository.createSimple(
          kind: TxKind.income,
          amount: 10000,
          walletId: cashId,
          title: 'Gaji',
          category: 'Gaji Bonus',
          date: '2026-10-20',
          time: '09:00',
        );

        expect(
          await repository.categoryForTitle(title: 'Gaji', kind: TxKind.income),
          'Gaji Bonus',
        );
      },
    );

    test('judul tak dikenal atau kosong tidak menghasilkan kategori', () async {
      await addIncome(title: 'Gaji', category: 'Gaji');

      expect(
        await repository.categoryForTitle(title: 'Jajan', kind: TxKind.income),
        isNull,
      );
      expect(
        await repository.categoryForTitle(title: '   ', kind: TxKind.income),
        isNull,
      );
    });

    test('C-3: kategori dicari hanya pada jenis yang sama', () async {
      await repository.createSimple(
        kind: TxKind.expense,
        amount: 10000,
        walletId: cashId,
        title: 'Jajan',
        category: 'Makanan',
        date: date,
      );

      expect(
        await repository.categoryForTitle(title: 'Jajan', kind: TxKind.income),
        isNull,
      );
      expect(
        await repository.categoryForTitle(title: 'Jajan', kind: TxKind.expense),
        'Makanan',
      );
    });

    test('transaksi yang sudah dihapus tidak dipakai lagi', () async {
      final id = await addIncome(title: 'Gaji', category: 'Gaji');

      await repository.softDelete(id);

      expect(
        await repository.categoryForTitle(title: 'Gaji', kind: TxKind.income),
        isNull,
      );
    });
  });
}
