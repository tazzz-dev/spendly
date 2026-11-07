import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/daily_totals.dart';
import '../domain/report_breakdown.dart';
import '../domain/report_range.dart';
import '../domain/saved_report.dart';
import '../domain/tx_kind.dart';
import 'db/app_database.dart';

/// Seluruh pembacaan rekap lewat sini.
///
/// Rekap **tidak menulis** transaksi apa pun; ia hanya membaca. Karena itu
/// lapisan ini tipis: mengerutkan data di SQL sebisa mungkin, lalu menyerahkan
/// seluruh perhitungan ke `domain/`. Lihat RENCANA-BUILD §2.
class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  /// Total mutasi per hari, sudah menggabungkan transaksi dan entri hutang.
  ///
  /// Satu baris per hari. Inilah sumber tunggal seluruh rekap, sehingga tab
  /// Realtime, Bulanan, kustom, dan Tren Aset memakai angka yang sama persis.
  ///
  /// Baris transaksi yang lahir dari entri hutang (`debt_entry_id` terisi)
  /// **tidak** dihitung sebagai pemasukan atau pengeluaran; mutasinya sudah
  /// terwakili oleh entri hutangnya sendiri. Tanpa penyaringan ini, satu
  /// pembayaran hutang akan terhitung dua kali. SPEC INV-6.
  Stream<List<DailyTotals>> watchDailyTotals() {
    return _db
        .customSelect(
          '''
      SELECT d.date AS date,
             COALESCE(t.income, 0) AS income,
             COALESCE(t.expense, 0) AS expense,
             COALESCE(t.correction, 0) AS correction,
             COALESCE(e.debt, 0) AS debt
      FROM (
        SELECT date FROM transactions WHERE deleted_at IS NULL
        UNION
        SELECT date FROM debt_entries WHERE deleted_at IS NULL
      ) d
      LEFT JOIN (
        SELECT date,
               SUM(CASE WHEN kind = 'income' AND debt_entry_id IS NULL
                        THEN amount ELSE 0 END) AS income,
               SUM(CASE WHEN kind = 'expense' AND debt_entry_id IS NULL
                        THEN -amount ELSE 0 END) AS expense,
               SUM(CASE WHEN kind = 'correction' THEN amount ELSE 0 END)
                        AS correction
        FROM transactions
        WHERE deleted_at IS NULL
        GROUP BY date
      ) t ON t.date = d.date
      LEFT JOIN (
        SELECT date, SUM(amount) AS debt
        FROM debt_entries
        WHERE deleted_at IS NULL
        GROUP BY date
      ) e ON e.date = d.date
      ORDER BY d.date ASC
      ''',
          readsFrom: {_db.transactions, _db.debtEntries},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => DailyTotals(
                  date: row.read<String>('date'),
                  income: row.read<int>('income'),
                  expense: row.read<int>('expense'),
                  correction: row.read<int>('correction'),
                  debt: row.read<int>('debt'),
                ),
              )
              .toList(growable: false),
        );
  }

  /// Baris pemasukan dan pengeluaran dalam satu rentang, untuk rincian.
  ///
  /// Pindah saldo tidak punya judul maupun kategori, dan koreksi saldo bukan
  /// pemasukan/pengeluaran, jadi keduanya tidak ikut. SPEC L-3 dan INV-6.
  Stream<List<ReportLine>> watchLines(ReportRange range) {
    return _db
        .customSelect(
          '''
      SELECT t.kind AS kind,
             t.title AS title,
             t.category AS category,
             t.amount AS amount
      FROM transactions t
      WHERE t.deleted_at IS NULL
        AND t.date BETWEEN ? AND ?
        AND t.kind IN ('income', 'expense')
        AND t.debt_entry_id IS NULL
      ORDER BY t.amount DESC
      ''',
          variables: [
            Variable<String>(range.start),
            Variable<String>(range.end),
          ],
          readsFrom: {_db.transactions},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ReportLine(
                  kind: TxKind.fromStorage(row.read<String>('kind')),
                  title: row.read<String?>('title'),
                  category: row.read<String?>('category'),
                  amount: row.read<int>('amount'),
                ),
              )
              .toList(growable: false),
        );
  }

  // ------------------------------------------------------- rekap kustom

  /// Rekap kustom tersimpan, terbaru lebih dulu. SPEC L-8.
  Stream<List<SavedReport>> watchCustomReports() {
    return (_db.select(_db.customReports)
          ..where((row) => row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => SavedReport(
                  id: row.id,
                  name: row.name,
                  startDate: row.startDate,
                  endDate: row.endDate,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<String> createCustomReport({
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();

    await _db
        .into(_db.customReports)
        .insert(
          CustomReportsCompanion.insert(
            id: id,
            name: name.trim(),
            startDate: startDate,
            endDate: endDate,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<void> updateCustomReport({
    required String id,
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(
      _db.customReports,
    )..where((row) => row.id.equals(id))).write(
      CustomReportsCompanion(
        name: Value(name.trim()),
        startDate: Value(startDate),
        endDate: Value(endDate),
        updatedAt: Value(now),
      ),
    );
  }

  /// Hapus lunak, konsisten dengan tabel lain. SPEC T-8.
  Future<void> softDeleteCustomReport(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(
      _db.customReports,
    )..where((row) => row.id.equals(id))).write(
      CustomReportsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}
