import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/movement.dart';
import '../domain/transaction_entry.dart';
import '../domain/tx_kind.dart';
import '../domain/tx_rules.dart';
import '../domain/tx_suggestion.dart';
import 'db/app_database.dart';

/// Seluruh penulisan dan pembacaan transaksi lewat sini.
///
/// Lapisan ini yang menegakkan aturan tulis di `docs/DATA-MODEL.md`. Tidak ada
/// antarmuka yang menulis tabel `transactions` langsung, supaya tanda nominal
/// tidak mungkin ditentukan di dua tempat (RW-5).
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  /// Berapa rekening "naik pangkat" setiap kali dipakai.
  ///
  /// Bukan angka karangan: Sepran menambah **11**, bukan 1, pada penghitung
  /// frekuensinya (SPEC R-3). Kita menirunya supaya urutan daftar rekening
  /// terasa sama.
  static const int _walletUseWeight = 11;

  // ---------------------------------------------------------------- membaca

  /// Potongan `SELECT` yang dipakai seluruh pembacaan daftar.
  ///
  /// Ditulis sekali supaya kolom yang dibaca halaman daftar, riwayat, dan
  /// ekspor tidak pernah berbeda diam-diam.
  static const String _entrySelect = '''
      SELECT t.id AS id,
             t.kind AS kind,
             t.amount AS amount,
             t.date AS date,
             t.time AS time,
             t.title AS title,
             t.category AS category,
             t.note AS note,
             t.wallet_id AS wallet_id,
             w.name AS wallet_name,
             t.counter_wallet_id AS counter_wallet_id,
             cw.name AS counter_wallet_name,
             t.transfer_group_id AS transfer_group_id,
             t.debt_entry_id AS debt_entry_id
      FROM transactions t
      JOIN wallets w ON w.id = t.wallet_id
      LEFT JOIN wallets cw ON cw.id = t.counter_wallet_id
  ''';

  static const String _entryOrder = '''
      ORDER BY t.date DESC,
               (NULLIF(t.time, '') IS NULL) ASC,
               NULLIF(t.time, '') ASC,
               t.created_at ASC,
               t.id ASC
  ''';

  /// Seluruh baris satu hari, urut menurut jam. SPEC T-9, T-10, T-12.
  ///
  /// Baris tanpa jam diletakkan di akhir. Jam kosong (`''`) diperlakukan sama
  /// seperti NULL lewat `NULLIF`, karena form lama bisa menulis teks kosong
  /// alih-alih NULL.
  Stream<List<TransactionEntry>> watchDay(String date) {
    return _db
        .customSelect(
          '''
      $_entrySelect
      WHERE t.deleted_at IS NULL
        AND t.date = ?
      ORDER BY (NULLIF(t.time, '') IS NULL) ASC,
               NULLIF(t.time, '') ASC,
               t.created_at ASC,
               t.id ASC
      ''',
          variables: [Variable<String>(date)],
          readsFrom: {_db.transactions, _db.wallets},
        )
        .watch()
        .map((rows) => rows.map(_toEntry).toList(growable: false));
  }

  /// Seluruh baris, terbaru lebih dulu. Dipakai halaman **Riwayat** (SPEC F-1).
  ///
  /// Sejak audit performa, pembacaan dibatasi [limit] baris dan pencarian
  /// dilakukan di SQL, bukan setelah seluruh riwayat dimuat ke memori. Halaman
  /// Riwayat menaikkan [limit] ketika pengguna menekan "Muat lebih banyak".
  Stream<List<TransactionEntry>> watchAll({
    int limit = 200,
    int offset = 0,
    String search = '',
  }) {
    final trimmed = search.trim();
    final pattern = '%$trimmed%';
    final variables = <Variable<Object>>[
      Variable<String>(trimmed),
      for (var index = 0; index < 5; index++) Variable<String>(pattern),
      Variable<int>(limit),
      Variable<int>(offset),
    ];

    return _db
        .customSelect(
          '''
      $_entrySelect
      WHERE t.deleted_at IS NULL
        AND (
          ? = ''
          OR t.title LIKE ?
          OR t.category LIKE ?
          OR t.note LIKE ?
          OR w.name LIKE ?
          OR cw.name LIKE ?
        )
      $_entryOrder
      LIMIT ? OFFSET ?
      ''',
          variables: variables,
          readsFrom: {_db.transactions, _db.wallets},
        )
        .watch()
        .map((rows) => rows.map(_toEntry).toList(growable: false));
  }

  /// Baris dalam satu rentang tanggal, terbaru lebih dulu. Dipakai **Ekspor**
  /// (SPEC X-2).
  Future<List<TransactionEntry>> readRange({
    required String from,
    required String until,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      $_entrySelect
      WHERE t.deleted_at IS NULL
        AND t.date >= ?
        AND t.date <= ?
      $_entryOrder
      ''',
          variables: [Variable<String>(from), Variable<String>(until)],
          readsFrom: {_db.transactions, _db.wallets},
        )
        .get();

    return rows.map(_toEntry).toList(growable: false);
  }

  /// Kategori yang terakhir dipakai untuk sebuah judul. SPEC C-7.
  ///
  /// Saat pengguna memilih saran judul, layar boleh ikut mengisi kategorinya
  /// tanpa mengetik ulang. Pencarian dibatasi pada jenis yang sama, sesuai C-3,
  /// dan mengabaikan kategori kosong. Mengembalikan null bila belum pernah ada.
  Future<String?> categoryForTitle({
    required String title,
    required TxKind kind,
  }) async {
    final name = title.trim();
    if (name.isEmpty) return null;

    final row = await _db
        .customSelect(
          '''
      SELECT category
      FROM transactions
      WHERE deleted_at IS NULL
        AND kind = ?
        AND title = ?
        AND category IS NOT NULL
        AND TRIM(category) <> ''
      ORDER BY date DESC,
               (NULLIF(time, '') IS NULL) ASC,
               NULLIF(time, '') DESC,
               created_at DESC
      LIMIT 1
      ''',
          variables: [
            Variable<String>(kind.storageValue),
            Variable<String>(name),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingleOrNull();

    if (row == null) return null;
    final category = row.read<String?>('category')?.trim() ?? '';
    return category.isEmpty ? null : category;
  }

  /// Saran judul atau kategori, yang paling sering dipakai lebih dulu.
  Stream<List<TxSuggestion>> watchSuggestions({
    required String type,
    required TxKind kind,
  }) {
    return (_db.select(_db.suggestions)
          ..where(
            (row) => row.type.equals(type) & row.kind.equals(kind.storageValue),
          )
          ..orderBy([
            (row) => OrderingTerm.desc(row.useCount),
            (row) => OrderingTerm.desc(row.lastUsedAt),
          ])
          ..limit(SuggestionRules.visibleCount))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => TxSuggestion(
                  id: row.id,
                  type: row.type,
                  name: row.name,
                  kind: TxKind.fromStorage(row.kind),
                  useCount: row.useCount,
                  lastUsedAt: row.lastUsedAt,
                ),
              )
              .toList(growable: false),
        );
  }

  // ---------------------------------------------------------------- menulis

  /// Menyimpan pemasukan atau pengeluaran.
  ///
  /// [amount] dikirim sebagai nilai positif; tandanya ditentukan oleh
  /// [Movement], bukan oleh pemanggil. SPEC T-4.
  Future<String> createSimple({
    required TxKind kind,
    required int amount,
    required String walletId,
    required String title,
    required String category,
    required String date,
    String? note,
    String? time,
  }) async {
    if (kind != TxKind.income && kind != TxKind.expense) {
      throw ArgumentError('createSimple hanya untuk pemasukan dan pengeluaran');
    }

    final draft = kind == TxKind.income
        ? Movement.income(
            amount: amount,
            walletId: walletId,
            title: title,
            category: category,
            date: date,
            note: note,
            time: time,
          )
        : Movement.expense(
            amount: amount,
            walletId: walletId,
            title: title,
            category: category,
            date: date,
            note: note,
            time: time,
          );

    // RW-1: satu transaksi basis data untuk baris transaksi, saran, dan
    // penghitung frekuensi rekening. Bila salah satu gagal, tidak ada yang
    // tersimpan setengah jalan.
    return _db.transaction(() async {
      final id = await _insertDraft(draft);
      await _recordSuggestions(title: title, category: category, kind: kind);
      await _bumpWalletUse(walletId);
      return id;
    });
  }

  /// Menyimpan Pindah Saldo sebagai dua baris terhubung. SPEC S-7, RW-2.
  ///
  /// Mengembalikan `transfer_group_id`, yang dipakai untuk menghapus kedua
  /// barisnya sekaligus nanti.
  Future<String> createTransfer({
    required int amount,
    required String fromWalletId,
    required String toWalletId,
    required String date,
    String? note,
    String? time,
    int adminFee = 0,
  }) async {
    final groupId = _uuid.v4();
    final draft = Movement.transfer(
      amount: amount,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      groupId: groupId,
      date: date,
      note: note,
      time: time,
    );

    await _db.transaction(() async {
      await _insertDraft(draft.outgoing);
      await _insertDraft(draft.incoming);
      if (adminFee > 0) {
        await _insertDraft(
          Movement.adminFee(
            amount: adminFee,
            walletId: fromWalletId,
            groupId: groupId,
            date: date,
            time: time,
          ),
        );
      }
      await _bumpWalletUse(fromWalletId);
      await _bumpWalletUse(toWalletId);
    });

    return groupId;
  }

  /// Biaya admin yang tersimpan pada sebuah Pindah Saldo. Nol bila tidak ada.
  Future<int> adminFeeForGroup(String groupId) async {
    final row = await _db
        .customSelect(
          '''
          SELECT COALESCE(SUM(-amount), 0) AS fee
          FROM transactions
          WHERE deleted_at IS NULL
            AND transfer_group_id = ?
            AND kind = ?
          ''',
          variables: [
            Variable<String>(groupId),
            Variable<String>(TxKind.expense.storageValue),
          ],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return row.read<int>('fee');
  }

  /// Menyimpan Koreksi Saldo. Nominal boleh negatif. SPEC K-5.
  Future<String> createCorrection({
    required int amount,
    required String walletId,
    required String date,
    String? note,
    String? time,
  }) async {
    final draft = Movement.correction(
      amount: amount,
      walletId: walletId,
      date: date,
      note: note,
      time: time,
    );

    return _db.transaction(() async {
      final id = await _insertDraft(draft);
      await _bumpWalletUse(walletId);
      return id;
    });
  }

  /// Hapus lunak. Bila baris yang dihapus bagian dari Pindah Saldo, **pasangan
  /// barisnya ikut dihapus** — kalau tidak, uang akan tampak hilang dari satu
  /// rekening saja. SPEC T-8 dan RW-4.
  /// Menyimpan banyak baris sekaligus, satu transaksi basis data.
  ///
  /// Dipakai **Impor** dari berkas Sepran. Tanda nominal tetap ditentukan
  /// [Movement] saat draft dibuat, jadi jalur ini tidak bisa menyelundupkan
  /// angka bertanda yang salah (RW-5).
  ///
  /// Penghitung saran sengaja **tidak** dinaikkan: impor seratus baris lama
  /// bukan bukti bahwa judul itu sering dipakai sekarang. Frekuensi rekening
  /// tetap dinaikkan sekali per rekening, karena itu menentukan urutan pemilih.
  Future<int> createMany(List<TxDraft> drafts) async {
    if (drafts.isEmpty) return 0;

    await _db.transaction(() async {
      for (final draft in drafts) {
        await _insertDraft(draft);
      }
      for (final walletId in drafts.map((draft) => draft.walletId).toSet()) {
        await _bumpWalletUse(walletId);
      }
    });

    return drafts.length;
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final row = await (_db.select(
        _db.transactions,
      )..where((tx) => tx.id.equals(id))).getSingleOrNull();
      if (row == null) return;

      final group = row.transferGroupId;
      final isAdminFeeRow = row.kind == TxKind.expense.storageValue;
      if (group != null && group.isNotEmpty && !isAdminFeeRow) {
        await (_db.update(_db.transactions)..where(
              (tx) => tx.transferGroupId.equals(group) & tx.deletedAt.isNull(),
            ))
            .write(
              TransactionsCompanion(
                deletedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      } else {
        await (_db.update(
          _db.transactions,
        )..where((tx) => tx.id.equals(id))).write(
          TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
      }

      // SG-2 dan SPEC C-6: penghitung saran turun, dengan batas bawah nol.
      // Baris biaya admin bukan saran pengguna, jadi tidak perlu disentuh.
      if (!isAdminFeeRow) {
        final kind = TxKind.fromStorage(row.kind);
        await _decaySuggestion(SuggestionRules.titleType, row.title, kind);
        await _decaySuggestion(
          SuggestionRules.categoryType,
          row.category,
          kind,
        );
      }
    });
  }

  // ---------------------------------------------------------------- mengubah

  /// Mengubah satu baris pemasukan atau pengeluaran.
  ///
  /// [amount] dikirim **positif**; tandanya tetap ditentukan [Movement], bukan
  /// oleh pemanggil — sama seperti saat membuat. DATA-MODEL RW-5.
  Future<void> updateSimple({
    required String id,
    required TxKind kind,
    required int amount,
    required String walletId,
    required String title,
    required String category,
    required String date,
    String? note,
    String? time,
  }) async {
    if (kind != TxKind.income && kind != TxKind.expense) {
      throw ArgumentError('updateSimple hanya untuk pemasukan dan pengeluaran');
    }

    final draft = kind == TxKind.income
        ? Movement.income(
            amount: amount,
            walletId: walletId,
            title: title,
            category: category,
            date: date,
            note: note,
            time: time,
          )
        : Movement.expense(
            amount: amount,
            walletId: walletId,
            title: title,
            category: category,
            date: date,
            note: note,
            time: time,
          );

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((tx) => tx.id.equals(id))).write(
        TransactionsCompanion(
          walletId: Value(draft.walletId),
          amount: Value(draft.amount),
          date: Value(draft.date),
          time: Value(draft.time),
          title: Value(draft.title),
          category: Value(draft.category),
          note: Value(draft.note),
          updatedAt: Value(now),
        ),
      );
      await _recordSuggestions(title: title, category: category, kind: kind);
      await _bumpWalletUse(walletId);
    });
  }

  /// Mengubah satu baris Koreksi Saldo. Nominal boleh negatif. SPEC K-5.
  Future<void> updateCorrection({
    required String id,
    required int amount,
    required String walletId,
    required String date,
    String? note,
    String? time,
  }) async {
    final draft = Movement.correction(
      amount: amount,
      walletId: walletId,
      date: date,
      note: note,
      time: time,
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((tx) => tx.id.equals(id))).write(
        TransactionsCompanion(
          walletId: Value(draft.walletId),
          amount: Value(draft.amount),
          date: Value(draft.date),
          time: Value(draft.time),
          note: Value(draft.note),
          updatedAt: Value(now),
        ),
      );
      await _bumpWalletUse(walletId);
    });
  }

  /// Mengubah **kedua** baris sebuah Pindah Saldo sekaligus.
  ///
  /// Kalau hanya satu sisi yang diubah, uang akan tampak hilang dari satu
  /// rekening: saldo asal dan tujuan tidak lagi seimbang. SPEC S-7, RW-2, RW-4.
  Future<void> updateTransfer({
    required String groupId,
    required int amount,
    required String fromWalletId,
    required String toWalletId,
    required String date,
    String? note,
    String? time,
    int? adminFee,
  }) async {
    final draft = Movement.transfer(
      amount: amount,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      groupId: groupId,
      date: date,
      note: note,
      time: time,
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    Future<void> write(TxDraft row) async {
      await (_db.update(_db.transactions)..where(
            (tx) =>
                tx.transferGroupId.equals(groupId) &
                tx.kind.equals(row.kind.storageValue),
          ))
          .write(
            TransactionsCompanion(
              walletId: Value(row.walletId),
              counterWalletId: Value(row.counterWalletId),
              amount: Value(row.amount),
              date: Value(row.date),
              time: Value(row.time),
              note: Value(row.note),
              updatedAt: Value(now),
            ),
          );
    }

    await _db.transaction(() async {
      await write(draft.outgoing);
      await write(draft.incoming);

      // `null` berarti pemanggil tidak mengubah biaya admin — misalnya saat
      // layar belum sempat memuat nilainya. Jangan hapus data yang sudah ada.
      if (adminFee != null) {
        final feeRows =
            await (_db.select(_db.transactions)..where(
                  (tx) =>
                      tx.transferGroupId.equals(groupId) &
                      tx.kind.equals(TxKind.expense.storageValue),
                ))
                .get();

        if (adminFee > 0) {
          final feeDraft = Movement.adminFee(
            amount: adminFee,
            walletId: fromWalletId,
            groupId: groupId,
            date: date,
            time: time,
          );
          if (feeRows.isEmpty) {
            await _insertDraft(feeDraft);
          } else {
            await (_db.update(
              _db.transactions,
            )..where((tx) => tx.id.equals(feeRows.first.id))).write(
              TransactionsCompanion(
                walletId: Value(feeDraft.walletId),
                amount: Value(feeDraft.amount),
                date: Value(feeDraft.date),
                time: Value(feeDraft.time),
                title: Value(feeDraft.title),
                category: Value(feeDraft.category),
                note: Value(feeDraft.note),
                deletedAt: const Value(null),
                updatedAt: Value(now),
              ),
            );
          }
        } else {
          for (final row in feeRows) {
            await (_db.update(
              _db.transactions,
            )..where((tx) => tx.id.equals(row.id))).write(
              TransactionsCompanion(
                deletedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
          }
        }
      }

      await _bumpWalletUse(fromWalletId);
      await _bumpWalletUse(toWalletId);
    });
  }

  /// Membaca satu baris untuk halaman detail.
  Future<TransactionEntry?> findById(String id) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT t.id AS id,
             t.kind AS kind,
             t.amount AS amount,
             t.date AS date,
             t.time AS time,
             t.title AS title,
             t.category AS category,
             t.note AS note,
             t.wallet_id AS wallet_id,
             w.name AS wallet_name,
             t.counter_wallet_id AS counter_wallet_id,
             cw.name AS counter_wallet_name,
             t.transfer_group_id AS transfer_group_id,
             t.debt_entry_id AS debt_entry_id
      FROM transactions t
      JOIN wallets w ON w.id = t.wallet_id
      LEFT JOIN wallets cw ON cw.id = t.counter_wallet_id
      WHERE t.deleted_at IS NULL
        AND t.id = ?
      ''',
          variables: [Variable<String>(id)],
          readsFrom: {_db.transactions, _db.wallets},
        )
        .get();

    if (rows.isEmpty) return null;
    return _toEntry(rows.first);
  }

  /// Mengembalikan baris yang baru dihapus — tombol **Urungkan**.
  ///
  /// Tanpa ini, satu salah tekan menghapus catatan tanpa jalan pulang. Bila
  /// baris itu bagian dari Pindah Saldo, kedua sisinya ikut kembali. SPEC T-8.
  Future<void> restore(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final row = await (_db.select(
        _db.transactions,
      )..where((tx) => tx.id.equals(id))).getSingleOrNull();
      if (row == null) return;

      final group = row.transferGroupId;
      final isAdminFeeRow = row.kind == TxKind.expense.storageValue;
      if (group != null && group.isNotEmpty && !isAdminFeeRow) {
        await (_db.update(
          _db.transactions,
        )..where((tx) => tx.transferGroupId.equals(group))).write(
          TransactionsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
      } else {
        await (_db.update(
          _db.transactions,
        )..where((tx) => tx.id.equals(id))).write(
          TransactionsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }

      // Penghitung saran dan frekuensi rekening dinaikkan lagi, karena
      // softDelete menurunkannya. Biaya admin bukan saran pengguna.
      if (!isAdminFeeRow) {
        final kind = TxKind.fromStorage(row.kind);
        await _recordSuggestions(
          title: row.title ?? '',
          category: row.category ?? '',
          kind: kind,
        );
      }
      await _bumpWalletUse(row.walletId);
      final counter = row.counterWalletId;
      if (counter != null && counter.isNotEmpty) {
        await _bumpWalletUse(counter);
      }
    });
  }

  // ---------------------------------------------------------------- bantuan

  Future<String> _insertDraft(TxDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();

    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            kind: draft.kind.storageValue,
            walletId: draft.walletId,
            amount: draft.amount,
            date: draft.date,
            createdAt: now,
            updatedAt: now,
            counterWalletId: Value(draft.counterWalletId),
            transferGroupId: Value(draft.transferGroupId),
            title: Value(draft.title),
            category: Value(draft.category),
            note: Value(draft.note),
            time: Value(draft.time),
          ),
        );

    return id;
  }

  /// Menaikkan penghitung saran judul dan kategori. SG-1 dan RW-11.
  ///
  /// Hanya untuk pemasukan dan pengeluaran. Pindah saldo tidak punya judul
  /// maupun kategori, dan koreksi saldo tidak punya saran di Sepran.
  Future<void> _recordSuggestions({
    required String title,
    required String category,
    required TxKind kind,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _bumpSuggestion(SuggestionRules.titleType, title, kind, now);
    await _bumpSuggestion(SuggestionRules.categoryType, category, kind, now);
  }

  Future<void> _bumpSuggestion(
    String type,
    String rawName,
    TxKind kind,
    int now,
  ) async {
    final name = rawName.trim();
    if (name.isEmpty) return;

    final existing =
        await (_db.select(_db.suggestions)..where(
              (row) =>
                  row.type.equals(type) &
                  row.name.equals(name) &
                  row.kind.equals(kind.storageValue),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.suggestions)
          .insert(
            SuggestionsCompanion.insert(
              id: _uuid.v4(),
              type: type,
              name: name,
              kind: kind.storageValue,
              createdAt: now,
              updatedAt: now,
              useCount: const Value(1),
              lastUsedAt: Value(now),
            ),
          );
      return;
    }

    await (_db.update(
      _db.suggestions,
    )..where((row) => row.id.equals(existing.id))).write(
      SuggestionsCompanion(
        useCount: Value(existing.useCount + 1),
        lastUsedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _decaySuggestion(
    String type,
    String? rawName,
    TxKind kind,
  ) async {
    final name = rawName?.trim() ?? '';
    if (name.isEmpty) return;
    if (!kind.countsInReport) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // MAX(x, 0) di SQLite dengan dua argumen adalah pembanding biasa, bukan
    // agregat. Inilah batas bawah nol yang diminta SPEC C-6.
    await _db.customUpdate(
      'UPDATE suggestions '
      'SET use_count = MAX(use_count - 1, 0), updated_at = ? '
      'WHERE type = ? AND name = ? AND kind = ?',
      variables: [
        Variable<int>(now),
        Variable<String>(type),
        Variable<String>(name),
        Variable<String>(kind.storageValue),
      ],
      updates: {_db.suggestions},
    );
  }

  /// SPEC R-3: rekening yang baru dipakai melompat ke atas daftar.
  Future<void> _bumpWalletUse(String walletId) async {
    await _db.customUpdate(
      'UPDATE wallets SET use_count = use_count + ? WHERE id = ?',
      variables: [
        const Variable<int>(_walletUseWeight),
        Variable<String>(walletId),
      ],
      updates: {_db.wallets},
    );
  }

  TransactionEntry _toEntry(QueryRow row) {
    return TransactionEntry(
      id: row.read<String>('id'),
      kind: TxKind.fromStorage(row.read<String>('kind')),
      amount: row.read<int>('amount'),
      date: row.read<String>('date'),
      time: row.read<String?>('time'),
      title: row.read<String?>('title'),
      category: row.read<String?>('category'),
      note: row.read<String?>('note'),
      walletId: row.read<String?>('wallet_id'),
      walletName: row.read<String?>('wallet_name'),
      counterWalletId: row.read<String?>('counter_wallet_id'),
      counterWalletName: row.read<String?>('counter_wallet_name'),
      transferGroupId: row.read<String?>('transfer_group_id'),
      debtEntryId: row.read<String?>('debt_entry_id'),
    );
  }
}
