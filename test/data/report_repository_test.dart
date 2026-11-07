// `isNotNull` dan `isNull` disembunyikan dari drift: nama itu dipakai drift
// untuk ekspresi SQL, sementara di berkas ini yang dimaksud pencocok test.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/report_repository.dart';
import 'package:pencatatan_keuangan/data/report_settings_repository.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/report_range.dart';
import 'package:pencatatan_keuangan/domain/report_rules.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

void main() {
  late AppDatabase db;
  late ReportRepository reports;
  late ReportSettingsRepository settings;
  late TransactionRepository transactions;
  late WalletRepository wallets;
  late String cashId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    reports = ReportRepository(db);
    settings = ReportSettingsRepository(db);
    transactions = TransactionRepository(db);
    wallets = WalletRepository(db);
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

  Future<void> addExpense({
    required int amount,
    required String date,
    String? category,
    String? title,
  }) => transactions.createSimple(
    kind: TxKind.expense,
    amount: amount,
    walletId: cashId,
    title: title ?? 'Belanja',
    category: category ?? 'Belanja',
    date: date,
  );

  Future<void> addIncome({required int amount, required String date}) =>
      transactions.createSimple(
        kind: TxKind.income,
        amount: amount,
        walletId: cashId,
        title: 'Gaji',
        category: 'Gaji',
        date: date,
      );

  group('watchDailyTotals', () {
    test('menjumlahkan pemasukan, pengeluaran, dan koreksi per hari', () async {
      await addIncome(amount: 500000, date: '2026-10-05');
      await addExpense(amount: 20000, date: '2026-10-05');
      await addExpense(amount: 30000, date: '2026-10-06');
      await transactions.createCorrection(
        amount: -5000,
        walletId: cashId,
        date: '2026-10-06',
      );

      final days = await reports.watchDailyTotals().first;

      final fifth = days.firstWhere((day) => day.date == '2026-10-05');
      expect(fifth.income, 500000);
      expect(fifth.expense, 20000);
      expect(fifth.correction, 0);

      final sixth = days.firstWhere((day) => day.date == '2026-10-06');
      expect(sixth.income, 0);
      expect(sixth.expense, 30000);
      expect(sixth.correction, -5000);
    });

    test(
      'pindah saldo tidak dihitung sebagai pemasukan atau pengeluaran',
      () async {
        final bca = await createWallet('BCA');
        await transactions.createTransfer(
          amount: 250000,
          fromWalletId: cashId,
          toWalletId: bca,
          date: '2026-10-07',
        );

        final days = await reports.watchDailyTotals().first;
        final day = days.firstWhere((row) => row.date == '2026-10-07');

        expect(day.income, 0);
        expect(day.expense, 0);
        expect(day.movement, 0);
      },
    );

    test('entri hutang muncul di kolom hutang', () async {
      await db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              id: 'debt-1',
              partyName: 'Fajar',
              date: '2026-10-08',
              createdAt: 0,
              updatedAt: 0,
            ),
          );
      await db
          .into(db.debtEntries)
          .insert(
            DebtEntriesCompanion.insert(
              id: 'entry-1',
              debtId: 'debt-1',
              amount: -100000,
              date: '2026-10-08',
              createdAt: 0,
              updatedAt: 0,
            ),
          );

      final days = await reports.watchDailyTotals().first;
      final day = days.firstWhere((row) => row.date == '2026-10-08');

      expect(day.debt, -100000);
      expect(day.movement, -100000);
    });

    test('baris transaksi dari entri hutang tidak dihitung dua kali', () async {
      await db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              id: 'debt-2',
              partyName: 'Fajar',
              date: '2026-10-09',
              createdAt: 0,
              updatedAt: 0,
            ),
          );
      await db
          .into(db.debtEntries)
          .insert(
            DebtEntriesCompanion.insert(
              id: 'entry-2',
              debtId: 'debt-2',
              amount: -100000,
              date: '2026-10-09',
              walletId: Value(cashId),
              createdAt: 0,
              updatedAt: 0,
            ),
          );
      // Baris transaksi yang lahir dari entri hutang itu. Tanpa penyaringan
      // `debt_entry_id IS NULL`, nominal ini akan terhitung sebagai pemasukan.
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-debt',
              kind: 'income',
              walletId: cashId,
              amount: 100000,
              date: '2026-10-09',
              debtEntryId: const Value('entry-2'),
              createdAt: 0,
              updatedAt: 0,
            ),
          );

      final days = await reports.watchDailyTotals().first;
      final day = days.firstWhere((row) => row.date == '2026-10-09');

      expect(day.income, 0);
      expect(day.debt, -100000);
    });

    test('baris terhapus tidak ikut dihitung (RW-9)', () async {
      await addIncome(amount: 500000, date: '2026-10-05');
      final id = await transactions.createSimple(
        kind: TxKind.income,
        amount: 999,
        walletId: cashId,
        title: 'Dibuang',
        category: 'X',
        date: '2026-10-05',
      );
      await transactions.softDelete(id);

      final days = await reports.watchDailyTotals().first;
      final day = days.firstWhere((row) => row.date == '2026-10-05');
      expect(day.income, 500000);
    });
  });

  group('watchLines', () {
    const range = ReportRange(start: '2026-10-01', end: '2026-10-31');

    test('hanya pemasukan dan pengeluaran dalam rentang', () async {
      final bca = await createWallet('BCA');
      await addExpense(amount: 20000, date: '2026-10-05', category: 'Makanan');
      await addIncome(amount: 500000, date: '2026-10-06');
      await transactions.createTransfer(
        amount: 100000,
        fromWalletId: cashId,
        toWalletId: bca,
        date: '2026-10-07',
      );
      await transactions.createCorrection(
        amount: 5000,
        walletId: cashId,
        date: '2026-10-08',
      );
      await addExpense(amount: 7000, date: '2026-09-30');

      final lines = await reports.watchLines(range).first;

      expect(lines, hasLength(2));
      expect(lines.map((line) => line.kind).toSet(), {
        TxKind.income,
        TxKind.expense,
      });
    });

    test('baris dari entri hutang tidak ikut (INV-6)', () async {
      await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: 'tx-debt',
              kind: 'expense',
              walletId: cashId,
              amount: -50000,
              date: '2026-10-10',
              debtEntryId: const Value('entry-x'),
              createdAt: 0,
              updatedAt: 0,
            ),
          );

      final lines = await reports.watchLines(range).first;
      expect(lines, isEmpty);
    });
  });

  group('rekap kustom (SPEC L-8)', () {
    test('simpan, ubah, dan hapus lunak', () async {
      final id = await reports.createCustomReport(
        name: 'Liburan',
        startDate: '2026-10-01',
        endDate: '2026-10-10',
      );

      var list = await reports.watchCustomReports().first;
      expect(list.single.name, 'Liburan');
      expect(list.single.range.start, '2026-10-01');

      await reports.updateCustomReport(
        id: id,
        name: 'Liburan Akhir Tahun',
        startDate: '2026-10-01',
        endDate: '2026-10-20',
      );

      list = await reports.watchCustomReports().first;
      expect(list.single.name, 'Liburan Akhir Tahun');
      expect(list.single.endDate, '2026-10-20');

      await reports.softDeleteCustomReport(id);
      expect(await reports.watchCustomReports().first, isEmpty);

      // Hapus lunak: barisnya masih ada, hanya ditandai. INV-5.
      final rows = await db.select(db.customReports).get();
      expect(rows.single.deletedAt, isNotNull);
    });
  });

  group('setelan rekap (SPEC L-7)', () {
    test('bawaan: mulai tanggal 1, akumulasi mati', () async {
      final config = await settings.read();

      expect(config.startDay, ReportRules.defaultStartDay);
      expect(config.accumulateBalance, ReportRules.defaultAccumulate);
    });

    test('menyimpan dan memancarkan ulang', () async {
      await settings.save(
        const ReportConfig(startDay: 25, accumulateBalance: true),
      );

      final config = await settings.watch().first;
      expect(config.startDay, 25);
      expect(config.accumulateBalance, isTrue);
    });

    test('hari mulai di luar batas dibatasi 1 sampai 28', () async {
      await settings.save(
        const ReportConfig(startDay: 99, accumulateBalance: false),
      );

      expect((await settings.read()).startDay, 28);
    });
  });
}
