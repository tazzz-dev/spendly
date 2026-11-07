// `isNull` dan `isNotNull` disembunyikan dari drift: kedua nama itu dipakai
// drift untuk ekspresi SQL, sementara di berkas ini yang dimaksud adalah
// pencocok dari flutter_test.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/debt_repository.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/report_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/debt_direction.dart';
import 'package:pencatatan_keuangan/domain/debt_rules.dart';
import 'package:pencatatan_keuangan/domain/debt_target_direction.dart';
import 'package:pencatatan_keuangan/domain/debt_totals.dart';
import 'package:pencatatan_keuangan/domain/wallet_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  late AppDatabase db;
  late DebtRepository repository;
  late WalletRepository wallets;
  late String cashId;

  const date = '2026-10-19';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DebtRepository(db);
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

  Future<List<TxRow>> allTransactions() => db.select(db.transactions).get();

  Future<List<DebtEntry>> allEntryRows() => db.select(db.debtEntries).get();

  Future<TxRow?> transactionOfEntry(String entryId) async {
    final rows = await (db.select(
      db.transactions,
    )..where((row) => row.debtEntryId.equals(entryId))).get();
    return rows.isEmpty ? null : rows.single;
  }

  Future<int> balanceOf(String walletId) async {
    final balances = await wallets.watchBalances().first;
    return balances.firstWhere((wallet) => wallet.id == walletId).balance;
  }

  Future<String> entryIdOf(String debtId) async =>
      (await repository.watchEntries(debtId).first).single.id;

  group('membuat catatan beserta entri pertama (SPEC H-12)', () {
    test('tersimpan sebagai satu catatan dengan net dari entrinya', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: DebtDirection.receive.apply(250000),
        note: 'pinjam untuk makan',
        time: '08:30',
      );

      final records = await repository.watchRecords().first;
      expect(records, hasLength(1));

      final record = records.single;
      expect(record.id, debtId);
      expect(record.partyName, 'Fajar');
      expect(record.net, 250000);
      expect(record.isReceiving, isTrue);
      expect(record.noteLabel, 'pinjam untuk makan');
      expect(record.isSettled, isFalse);
      expect(record.statusLabel, 'Belum lunas');
    });

    test('tanpa rekening tidak menulis baris transaksi (SPEC M-4)', () async {
      await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: DebtDirection.give.apply(100000),
      );

      expect(await allTransactions(), isEmpty);
      expect(await balanceOf(cashId), 0);
    });

    test('Memberi bertanda negatif dan menulis pengeluaran', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: DebtDirection.give.apply(200000),
        walletId: cashId,
        time: '08:30',
      );
      final entryId = await entryIdOf(debtId);

      final entry = (await repository.watchEntries(debtId).first).single;
      expect(entry.amount, -200000);
      expect(entry.direction, DebtDirection.give);

      final tx = await transactionOfEntry(entryId);
      expect(tx, isNotNull);
      expect(tx!.kind, 'expense');
      expect(tx.amount, -200000);
      expect(tx.walletId, cashId);
      expect(tx.title, 'Fajar');
      expect(tx.category, 'Hutang Piutang');
      expect(tx.date, date);
      expect(tx.time, '08:30');
    });

    test('Menerima bertanda positif dan menulis pemasukan', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Reimburse Blok M',
        date: date,
        amount: DebtDirection.receive.apply(75000),
        walletId: cashId,
      );
      final entryId = await entryIdOf(debtId);

      final tx = await transactionOfEntry(entryId);
      expect(tx!.kind, 'income');
      expect(tx.amount, 75000);
      expect(tx.debtEntryId, entryId);
    });

    test(
      'baris transaksi yang lahir dari entri mengubah saldo rekening',
      () async {
        await repository.createDebtWithEntry(
          partyName: 'Fajar',
          date: date,
          amount: DebtDirection.give.apply(150000),
          walletId: cashId,
        );

        expect(await balanceOf(cashId), -150000);
      },
    );

    test('nominal nol ditolak sebelum menyentuh basis data', () async {
      await expectLater(
        repository.createDebtWithEntry(
          partyName: 'Fajar',
          date: date,
          amount: 0,
        ),
        throwsArgumentError,
      );

      expect(await repository.watchRecords().first, isEmpty);
      expect(await allEntryRows(), isEmpty);
    });
  });

  group('menambah entri (SPEC H-11, RW-8)', () {
    test('net adalah jumlah seluruh entri bertanda', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: DebtDirection.give.apply(200000),
      );

      await repository.addEntry(
        debtId: debtId,
        amount: DebtDirection.receive.apply(50000),
        date: date,
      );

      final record = (await repository.watchRecords().first).single;
      expect(record.net, -150000);
      expect(record.magnitude, 150000);
    });

    test('entri boleh melebihi arah mana pun, tidak ada batas pokok', () async {
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );

      await repository.addEntry(debtId: debtId, amount: 5000000, date: date);

      final record = (await repository.watchRecords().first).single;
      expect(record.net, 5000000);
    });

    test('nominal nol ditolak dan tidak menulis baris apa pun', () async {
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );

      await expectLater(
        repository.addEntry(debtId: debtId, amount: 0, date: date),
        throwsArgumentError,
      );
      expect(await allEntryRows(), isEmpty);
    });

    test('entri dengan rekening menulis baris transaksi yang baru', () async {
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );

      final entryId = await repository.addEntry(
        debtId: debtId,
        amount: -30000,
        date: date,
        walletId: cashId,
        note: 'cicilan',
        time: '09:00',
      );

      final tx = await transactionOfEntry(entryId);
      expect(tx!.amount, -30000);
      expect(tx.note, 'cicilan');
      expect(tx.time, '09:00');
    });

    test(
      'daftar entri membawa nama rekening dan keterangan siap tampil',
      () async {
        final bca = await createWallet('BCA');
        final debtId = await repository.createDebtWithEntry(
          partyName: 'Fajar',
          date: date,
          amount: -40000,
          walletId: bca,
        );

        final entry = (await repository.watchEntries(debtId).first).single;
        expect(entry.walletName, 'BCA');
        expect(entry.noteLabel, 'Tanpa keterangan');
      },
    );
  });

  group('menyunting entri', () {
    test('nominal dan baris transaksinya ikut berubah', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: cashId,
      );
      final entryId = await entryIdOf(debtId);

      await repository.updateEntry(
        id: entryId,
        amount: -175000,
        date: '2026-10-20',
        time: '10:00',
        walletId: cashId,
        note: 'diperbarui',
      );

      final entry = (await repository.watchEntries(debtId).first).single;
      expect(entry.amount, -175000);
      expect(entry.date, '2026-10-20');
      expect(entry.noteLabel, 'diperbarui');
      expect(await balanceOf(cashId), -175000);

      final tx = await transactionOfEntry(entryId);
      expect(tx!.amount, -175000);
      expect(tx.date, '2026-10-20');
      expect(tx.note, 'diperbarui');
    });

    test('mengubah arah entri mengganti jenis baris transaksi', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: cashId,
      );
      final entryId = await entryIdOf(debtId);

      await repository.updateEntry(
        id: entryId,
        amount: 100000,
        date: date,
        walletId: cashId,
      );

      final tx = await transactionOfEntry(entryId);
      expect(tx!.kind, 'income');
      expect(tx.amount, 100000);
      expect(await balanceOf(cashId), 100000);
    });

    test(
      'mengosongkan rekening menghapus baris transaksi dan saldo kembali',
      () async {
        final debtId = await repository.createDebtWithEntry(
          partyName: 'Fajar',
          date: date,
          amount: -100000,
          walletId: cashId,
        );
        final entryId = await entryIdOf(debtId);

        await repository.updateEntry(id: entryId, amount: -100000, date: date);

        expect(await balanceOf(cashId), 0);
        // Hapus lunak: barisnya masih ada, tapi tidak lagi dianggap aktif.
        final tx = await transactionOfEntry(entryId);
        expect(tx!.deletedAt, isNotNull);
      },
    );

    test(
      'mengisi rekening kembali menghidupkan baris transaksi yang sama',
      () async {
        final debtId = await repository.createDebtWithEntry(
          partyName: 'Fajar',
          date: date,
          amount: -100000,
          walletId: cashId,
        );
        final entryId = await entryIdOf(debtId);

        await repository.updateEntry(id: entryId, amount: -100000, date: date);
        await repository.updateEntry(
          id: entryId,
          amount: -100000,
          date: date,
          walletId: cashId,
        );

        final rows = await (db.select(
          db.transactions,
        )..where((row) => row.debtEntryId.equals(entryId))).get();
        expect(rows, hasLength(1));
        expect(rows.single.deletedAt, isNull);
        expect(await balanceOf(cashId), -100000);
      },
    );

    test('id yang tidak ada hanya diam, tidak melempar', () async {
      await expectLater(
        repository.updateEntry(id: 'tidak-ada', amount: 5000, date: date),
        completes,
      );
    });
  });

  group('menghapus entri', () {
    test('hapus lunak menyembunyikan entri dan baris transaksinya', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: cashId,
      );
      final entryId = await entryIdOf(debtId);

      await repository.deleteEntry(entryId);

      expect(await repository.watchEntries(debtId).first, isEmpty);
      expect((await repository.watchRecords().first).single.net, 0);
      expect(await balanceOf(cashId), 0);

      final tx = await transactionOfEntry(entryId);
      expect(tx!.deletedAt, isNotNull);
      // Hapus lunak, bukan hapus permanen.
      expect(await allEntryRows(), hasLength(1));
    });
  });

  group('menghapus catatan (SPEC H-7)', () {
    test('seluruh entri dan baris transaksinya ikut terhapus', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: cashId,
      );
      await repository.addEntry(
        debtId: debtId,
        amount: 50000,
        date: date,
        walletId: cashId,
      );

      await repository.deleteDebt(debtId);

      expect(await repository.watchRecords().first, isEmpty);
      expect(await repository.watchEntries(debtId).first, isEmpty);
      expect(await balanceOf(cashId), 0);

      // Barisnya tetap ada di basis data, hanya ditandai terhapus.
      expect(await allEntryRows(), hasLength(2));
      for (final row in await allEntryRows()) {
        expect(row.deletedAt, isNotNull);
      }
      for (final row in await allTransactions()) {
        expect(row.deletedAt, isNotNull);
      }
    });

    test(
      'catatan yang sudah terhapus tidak muncul lagi walau entri dibaca',
      () async {
        final debtId = await repository.createDebt(
          partyName: 'Fajar',
          date: date,
        );
        await repository.deleteDebt(debtId);

        expect(await repository.watchRecord(debtId).first, isNull);
      },
    );
  });

  group('status lunas (SPEC H-9)', () {
    test('menandai lunas dan membatalkannya', () async {
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );

      await repository.setSettled(debtId, true);
      expect(
        (await repository.watchRecord(debtId).first)!.statusLabel,
        'Lunas',
      );

      await repository.setSettled(debtId, false);
      expect(
        (await repository.watchRecord(debtId).first)!.statusLabel,
        'Belum lunas',
      );
    });
  });

  group('daftar catatan', () {
    test('urut dari tanggal terbaru', () async {
      await repository.createDebt(partyName: 'Lama', date: '2026-10-01');
      await repository.createDebt(partyName: 'Baru', date: '2026-10-20');
      await repository.createDebt(partyName: 'Tengah', date: '2026-10-10');

      final records = await repository.watchRecords().first;
      expect(records.map((record) => record.partyName), [
        'Baru',
        'Tengah',
        'Lama',
      ]);
    });

    test('keterangan kosong tersimpan sebagai null, bukan spasi', () async {
      await repository.createDebt(
        partyName: 'Fajar',
        date: date,
        note: '   ',
        phone: '',
      );

      final row = (await db.select(db.debts).get()).single;
      expect(row.note, isNull);
      expect(row.phone, isNull);
    });

    test(
      'dua total terpisah dihitung dari seluruh catatan (SPEC H-1)',
      () async {
        final a = await repository.createDebt(partyName: 'Fajar', date: date);
        await repository.addEntry(debtId: a, amount: 250000, date: date);

        final b = await repository.createDebt(partyName: 'Bayu', date: date);
        await repository.addEntry(debtId: b, amount: -200000, date: date);

        final totals = DebtTotals.of(await repository.watchRecords().first);
        expect(totals.receiving, 250000);
        expect(totals.giving, 200000);
      },
    );

    test('nama yang pernah dipakai disebut sekali saja', () async {
      await repository.createDebt(partyName: 'Fajar', date: date);
      await repository.createDebt(partyName: 'Fajar', date: date);
      await repository.createDebt(partyName: 'Bayu', date: date);

      expect(await repository.partyNames(), ['Bayu', 'Fajar']);
    });
  });

  group('menyunting catatan', () {
    test('judul baris transaksi turunan ikut menyesuaikan nama baru', () async {
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: cashId,
      );
      final entryId = await entryIdOf(debtId);

      await repository.updateDebt(
        id: debtId,
        partyName: 'Fajar Wijaya',
        date: '2026-10-21',
        note: 'pinjaman',
      );

      final record = await repository.watchRecord(debtId).first;
      expect(record!.partyName, 'Fajar Wijaya');
      expect(record.date, '2026-10-21');
      expect(record.noteLabel, 'pinjaman');

      final tx = await transactionOfEntry(entryId);
      expect(tx!.title, 'Fajar Wijaya');
    });
  });

  group('RW-14 rekening yang dipakai entri hutang', () {
    test('menghalangi penghapusan rekening', () async {
      final bca = await createWallet('BCA');
      final debtId = await repository.createDebtWithEntry(
        partyName: 'Fajar',
        date: date,
        amount: -100000,
        walletId: bca,
      );

      final verdict = await wallets.checkDelete(bca);
      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.inUse);
      // Dua rujukan terhitung: baris transaksi turunan dan entri hutangnya
      // sendiri (`_usageCount` menjumlahkan keduanya). Keduanya memang
      // menunjuk rekening yang sama.
      expect(verdict.usageCount, 2);

      // Setelah catatannya dihapus, rekeningnya bebas lagi.
      await repository.deleteDebt(debtId);
      expect((await wallets.checkDelete(bca)).allowed, isTrue);
    });

    test('pembayaran target tanpa rekening juga menghalangi', () async {
      final bca = await createWallet('BCA');
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
      );
      await repository.addPayment(
        debtId: debtId,
        magnitude: 200000,
        date: date,
        walletId: bca,
      );

      final verdict = await wallets.checkDelete(bca);
      expect(verdict.allowed, isFalse);
      expect(verdict.block, WalletDeleteBlock.inUse);
    });

    test('entri tanpa baris transaksi pun tetap menghalanginya', () async {
      final bca = await createWallet('BCA');
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );
      final now = DateTime.now().millisecondsSinceEpoch;

      // Sengaja langsung ke tabel: meniru entri yang rekeningnya terisi tetapi
      // baris transaksinya tidak ada. Inilah sisi RW-14 yang tidak tertangkap
      // kalau hanya transactions.wallet_id diperiksa.
      await db
          .into(db.debtEntries)
          .insert(
            DebtEntriesCompanion.insert(
              id: 'entri-yatim',
              debtId: debtId,
              amount: 50000,
              date: date,
              createdAt: now,
              updatedAt: now,
              walletId: Value(bca),
            ),
          );

      final verdict = await wallets.checkDelete(bca);
      expect(verdict.block, WalletDeleteBlock.inUse);
      expect(verdict.usageCount, 1);
    });
  });

  group('membuat target (H-17, H-18, H-27)', () {
    test('menulis ketiga kolom tanpa entri maupun transaksi', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
        paidOpening: 250000,
        note: 'pinjaman renovasi',
      );

      expect(await allEntryRows(), isEmpty);
      expect(await allTransactions(), isEmpty);
      expect(await balanceOf(cashId), 0);

      final row = (await db.select(db.debts).get()).single;
      expect(row.targetAmount, 5000000);
      expect(row.targetDirection, 'owe');
      expect(row.paidOpening, 250000);

      final record = await repository.watchRecord(debtId).first;
      expect(record!.hasTarget, isTrue);
      expect(record.targetDirection, DebtTargetDirection.owe);
      expect(record.progress!.remaining, 4750000);
    });

    test('paid_opening tidak masuk Rekap dan tidak menggeser saldo', () async {
      await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owed,
        paidOpening: 1000000,
      );

      final totals = await ReportRepository(db).watchDailyTotals().first;
      expect(totals, isEmpty);
      expect(await balanceOf(cashId), 0);
    });

    test(
      'target nol atau negatif ditolak sebelum menyentuh basis data',
      () async {
        await expectLater(
          repository.createTarget(
            partyName: 'Kakak',
            date: date,
            targetAmount: 0,
            direction: DebtTargetDirection.owe,
          ),
          throwsArgumentError,
        );
        await expectLater(
          repository.createTarget(
            partyName: 'Kakak',
            date: date,
            targetAmount: -1,
            direction: DebtTargetDirection.owe,
          ),
          throwsArgumentError,
        );
        await expectLater(
          repository.createTarget(
            partyName: 'Kakak',
            date: date,
            targetAmount: 1000,
            direction: DebtTargetDirection.owe,
            paidOpening: -1,
          ),
          throwsArgumentError,
        );

        expect(await repository.watchRecords().first, isEmpty);
      },
    );
  });

  group('pembayaran target (H-21, H-22)', () {
    test(
      'owe menulis entri negatif, satu cermin, dan menggeser Rekap',
      () async {
        final debtId = await repository.createTarget(
          partyName: 'Kakak',
          date: date,
          targetAmount: 5000000,
          direction: DebtTargetDirection.owe,
        );

        final entryId = await repository.addPayment(
          debtId: debtId,
          magnitude: 200000,
          date: date,
          walletId: cashId,
          time: '09:00',
          note: 'cicilan pertama',
        );

        final entry = (await repository.watchEntries(debtId).first).single;
        expect(entry.amount, -200000);
        expect(entry.direction, DebtDirection.give);

        final tx = await transactionOfEntry(entryId);
        expect(tx!.kind, 'expense');
        expect(tx.amount, -200000);
        expect(tx.category, 'Hutang Piutang');

        expect(await balanceOf(cashId), -200000);

        final totals = await ReportRepository(db).watchDailyTotals().first;
        expect(totals.single.debt, -200000);
        expect(totals.single.movement, -200000);

        final record = await repository.watchRecord(debtId).first;
        expect(record!.progress!.paid, 200000);
        expect(record.progress!.remaining, 4800000);
      },
    );

    test('owed menulis entri positif dan pemasukan', () async {
      final debtId = await repository.createTarget(
        partyName: 'Bayu',
        date: date,
        targetAmount: 2000000,
        direction: DebtTargetDirection.owed,
      );

      final entryId = await repository.addPayment(
        debtId: debtId,
        magnitude: 500000,
        date: date,
        walletId: cashId,
      );

      final entry = (await repository.watchEntries(debtId).first).single;
      expect(entry.amount, 500000);

      final tx = await transactionOfEntry(entryId);
      expect(tx!.kind, 'income');
      expect(tx.amount, 500000);
      expect(await balanceOf(cashId), 500000);

      final record = await repository.watchRecord(debtId).first;
      expect(record!.progress!.remaining, 1500000);
    });

    test('tanpa rekening ditolak dengan pesan yang bisa ditampilkan', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
      );

      await expectLater(
        repository.addPayment(
          debtId: debtId,
          magnitude: 200000,
          date: date,
          walletId: null,
        ),
        throwsA(
          isA<DebtPaymentException>().having(
            (error) => error.message,
            'message',
            DebtRules.walletRequiredForPayment,
          ),
        ),
      );

      expect(await allEntryRows(), isEmpty);
      expect(await balanceOf(cashId), 0);
    });

    test('catatan tanpa target tidak bisa dibayar lewat addPayment', () async {
      final debtId = await repository.createDebt(
        partyName: 'Fajar',
        date: date,
      );

      await expectLater(
        repository.addPayment(
          debtId: debtId,
          magnitude: 100000,
          date: date,
          walletId: cashId,
        ),
        throwsA(
          isA<DebtPaymentException>().having(
            (error) => error.message,
            'message',
            DebtRules.targetMissing,
          ),
        ),
      );
    });

    test('entri arah berlawanan tidak menambah progress', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
      );
      await repository.addPayment(
        debtId: debtId,
        magnitude: 200000,
        date: date,
        walletId: cashId,
      );
      // Pinjam tambahan: uang masuk, bukan pembayaran. H-25 menyarankan
      // menaikkan target, bukan menghitungnya sebagai progress.
      await repository.addEntry(debtId: debtId, amount: 50000, date: date);

      final record = await repository.watchRecord(debtId).first;
      expect(record!.progress!.paid, 200000);
      expect(record.progress!.remaining, 4800000);
      expect(record.net, -150000);
    });

    test(
      'kelebihan bayar diizinkan dan tetap mengurangi saldo penuh',
      () async {
        final debtId = await repository.createTarget(
          partyName: 'Kakak',
          date: date,
          targetAmount: 5000000,
          direction: DebtTargetDirection.owe,
        );
        await repository.addPayment(
          debtId: debtId,
          magnitude: 5200000,
          date: date,
          walletId: cashId,
        );

        final record = await repository.watchRecord(debtId).first;
        expect(record!.progress!.overpaid, 200000);
        expect(record.progress!.remaining, 0);
        expect(record.progress!.isSettled, isTrue);
        expect(await balanceOf(cashId), -5200000);
      },
    );

    test('menyunting dan menghapus entri menghitung ulang progress', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
      );
      final entryId = await repository.addPayment(
        debtId: debtId,
        magnitude: 200000,
        date: date,
        walletId: cashId,
      );

      await repository.updateEntry(
        id: entryId,
        amount: -300000,
        date: date,
        walletId: cashId,
      );
      var record = await repository.watchRecord(debtId).first;
      expect(record!.progress!.paid, 300000);

      await repository.deleteEntry(entryId);
      record = await repository.watchRecord(debtId).first;
      expect(record!.progress!.paid, 0);
      expect(record.progress!.remaining, 5000000);
      expect(await balanceOf(cashId), 0);
    });
  });

  group('menyunting dan mengosongkan target (H-25)', () {
    test('updateTarget tidak menyentuh entri maupun transaksi', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
      );
      final entryId = await repository.addPayment(
        debtId: debtId,
        magnitude: 200000,
        date: date,
        walletId: cashId,
      );

      await repository.updateTarget(
        id: debtId,
        partyName: 'Kakak Besar',
        date: '2026-10-21',
        targetAmount: 4000000,
        direction: DebtTargetDirection.owe,
        paidOpening: 100000,
        note: 'target diperbarui',
      );

      final entry = (await repository.watchEntries(debtId).first).single;
      expect(entry.id, entryId);
      expect(entry.amount, -200000);
      expect(await allEntryRows(), hasLength(1));

      final tx = await transactionOfEntry(entryId);
      expect(tx!.title, 'Kakak Besar');

      final record = await repository.watchRecord(debtId).first;
      expect(record!.progress!.paid, 300000);
      expect(record.progress!.remaining, 3700000);
    });

    test(
      'clearTarget mengembalikan catatan ke Normal tanpa menghapus entri',
      () async {
        final debtId = await repository.createTarget(
          partyName: 'Kakak',
          date: date,
          targetAmount: 5000000,
          direction: DebtTargetDirection.owe,
          paidOpening: 500000,
        );
        await repository.addPayment(
          debtId: debtId,
          magnitude: 200000,
          date: date,
          walletId: cashId,
        );

        await repository.clearTarget(debtId);

        final record = await repository.watchRecord(debtId).first;
        expect(record!.hasTarget, isFalse);
        expect(record.targetAmount, isNull);
        expect(record.targetDirection, isNull);
        expect(record.paidOpening, 0);
        expect(record.progress, isNull);

        // Entri dan transaksi cermin tetap ada; saldo tidak kembali.
        expect(await repository.watchEntries(debtId).first, hasLength(1));
        expect(await balanceOf(cashId), -200000);
      },
    );
  });

  group('status lunas manual (H-24)', () {
    test('utang dihapuskan tidak menulis entri atau transaksi', () async {
      final debtId = await repository.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 5000000,
        direction: DebtTargetDirection.owe,
        paidOpening: 200000,
      );
      final balanceBefore = await balanceOf(cashId);

      await repository.setSettled(debtId, true);

      final record = await repository.watchRecord(debtId).first;
      expect(record!.statusLabel, 'Lunas');
      expect(record.progress!.isForgiven, isTrue);
      expect(record.progress!.remaining, 4800000);

      expect(await allEntryRows(), isEmpty);
      expect(await allTransactions(), isEmpty);
      expect(await balanceOf(cashId), balanceBefore);
      expect(await repository.watchRecords().first, hasLength(1));
    });
  });

  group('migrasi v1 → v2', () {
    test('mempertahankan catatan lama dan menambah kolom target', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final legacy = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE debts (
                id TEXT NOT NULL PRIMARY KEY,
                party_name TEXT NOT NULL,
                phone TEXT NULL,
                date TEXT NOT NULL,
                note TEXT NULL,
                is_settled INTEGER NOT NULL DEFAULT 0,
                deleted_at INTEGER NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
            raw.execute('''
              CREATE TABLE debt_entries (
                id TEXT NOT NULL PRIMARY KEY,
                debt_id TEXT NOT NULL REFERENCES debts(id),
                amount INTEGER NOT NULL,
                date TEXT NOT NULL,
                time TEXT NULL,
                wallet_id TEXT NULL,
                note TEXT NULL,
                deleted_at INTEGER NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
            raw.execute('''
              CREATE TABLE schema_migrations (
                version INTEGER NOT NULL,
                applied_at INTEGER NOT NULL,
                UNIQUE(version)
              )
            ''');
            raw.execute(
              "INSERT INTO debts VALUES ('d-lama', 'Fajar', NULL, "
              "'2026-10-01', 'pinjaman', 0, NULL, $now, $now)",
            );
            raw.execute(
              "INSERT INTO debt_entries VALUES ('e-lama', 'd-lama', -200000, "
              "'2026-10-01', NULL, NULL, 'cicilan', NULL, $now, $now)",
            );
            raw.execute('INSERT INTO schema_migrations VALUES (1, $now)');
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );

      addTearDown(legacy.close);

      final migrated = DebtRepository(legacy);

      final record = await migrated.watchRecord('d-lama').first;
      expect(record, isNotNull);
      expect(record!.partyName, 'Fajar');
      expect(record.net, -200000);
      expect(record.hasTarget, isFalse);
      expect(record.targetAmount, isNull);
      expect(record.targetDirection, isNull);
      expect(record.paidOpening, 0);

      final versions = await legacy.select(legacy.schemaMigrations).get();
      expect(versions.map((row) => row.version), containsAll([1, 2]));

      // Kolom baru benar-benar bisa dipakai setelah migrasi.
      final targetId = await migrated.createTarget(
        partyName: 'Kakak',
        date: date,
        targetAmount: 1000000,
        direction: DebtTargetDirection.owe,
      );
      expect(
        (await migrated.watchRecord(targetId).first)!.progress!.remaining,
        1000000,
      );
    });
  });

  group('target pokok (SPEC H-17 sampai H-27)', () {
    Future<String> createTarget({
      DebtTargetDirection direction = DebtTargetDirection.owe,
      int target = 5000000,
      int paidOpening = 0,
    }) => repository.createTarget(
      partyName: 'Kakak',
      date: date,
      targetAmount: target,
      direction: direction,
      paidOpening: paidOpening,
    );

    Future<Debt> debtRow(String id) =>
        (db.select(db.debts)..where((row) => row.id.equals(id))).getSingle();

    test(
      'createTarget hanya menulis metadata, tanpa entri atau transaksi',
      () async {
        final id = await createTarget(paidOpening: 1000000);

        final row = await debtRow(id);
        expect(row.targetAmount, 5000000);
        expect(row.targetDirection, 'owe');
        expect(row.paidOpening, 1000000);
        expect(await allEntryRows(), isEmpty);
        expect(await allTransactions(), isEmpty);

        final record = (await repository.watchRecords().first).single;
        expect(record.progress!.paid, 1000000);
        expect(record.progress!.remaining, 4000000);
      },
    );

    test('addPayment menolak tanpa rekening (H-21)', () async {
      final id = await createTarget();

      await expectLater(
        repository.addPayment(
          debtId: id,
          magnitude: 500000,
          date: date,
          walletId: null,
        ),
        throwsA(isA<DebtPaymentException>()),
      );
      expect(await allEntryRows(), isEmpty);
      expect(await allTransactions(), isEmpty);
    });

    test(
      'addPayment owe menulis entri negatif, cermin, dan mengubah saldo',
      () async {
        final bca = await createWallet('BCA');
        final id = await createTarget();

        await repository.addPayment(
          debtId: id,
          magnitude: 500000,
          date: date,
          walletId: bca,
        );

        final entry = (await allEntryRows()).single;
        expect(entry.amount, -500000);
        final mirror = await transactionOfEntry(entry.id);
        expect(mirror, isNotNull);
        expect(mirror!.amount, -500000);
        expect(mirror.walletId, bca);
        expect(await balanceOf(bca), -500000);

        final record = (await repository.watchRecords().first).single;
        expect(record.progress!.paid, 500000);
        expect(record.progress!.remaining, 4500000);
      },
    );

    test('addPayment owed menulis entri positif', () async {
      final bca = await createWallet('BCA');
      final id = await createTarget(direction: DebtTargetDirection.owed);

      await repository.addPayment(
        debtId: id,
        magnitude: 200000,
        date: date,
        walletId: bca,
      );

      expect((await allEntryRows()).single.amount, 200000);
      final record = (await repository.watchRecords().first).single;
      expect(record.progress!.paid, 200000);
      expect(record.progress!.remaining, 4800000);
    });

    test('updateTarget tidak menyentuh entri yang sudah ada', () async {
      final bca = await createWallet('BCA');
      final id = await createTarget();
      await repository.addPayment(
        debtId: id,
        magnitude: 100000,
        date: date,
        walletId: bca,
      );

      await repository.updateTarget(
        id: id,
        partyName: 'Kakak',
        date: date,
        targetAmount: 2000000,
        direction: DebtTargetDirection.owe,
        paidOpening: 50000,
      );

      final entries = await allEntryRows();
      expect(entries, hasLength(1));
      expect(entries.single.amount, -100000);

      final row = await debtRow(id);
      expect(row.targetAmount, 2000000);
      expect(row.paidOpening, 50000);
    });

    test(
      'clearTarget mengembalikan catatan ke Normal tanpa menghapus entri',
      () async {
        final bca = await createWallet('BCA');
        final id = await createTarget(paidOpening: 250000);
        await repository.addPayment(
          debtId: id,
          magnitude: 100000,
          date: date,
          walletId: bca,
        );

        await repository.clearTarget(id);

        final row = await debtRow(id);
        expect(row.targetAmount, isNull);
        expect(row.targetDirection, isNull);
        expect(row.paidOpening, 0);
        expect(await allEntryRows(), hasLength(1));

        final record = (await repository.watchRecords().first).single;
        expect(record.progress, isNull);
      },
    );
  });
}
