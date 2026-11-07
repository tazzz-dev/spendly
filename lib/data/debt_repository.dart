import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/debt_entry.dart';
import '../domain/debt_record.dart';
import '../domain/debt_rules.dart';
import '../domain/debt_target_direction.dart';
import '../domain/tx_kind.dart';
// Nama kelas domain kita `DebtEntry` sama dengan nama kelas baris drift untuk
// tabel `debt_entries`. Yang dipakai di berkas ini hanya companion dan nama
// kolomnya, jadi kelas baris bawaan drift disembunyikan supaya tidak bentrok.
import 'db/app_database.dart' hide DebtEntry;

/// Gerbang tunggal ke seluruh penulisan catatan hutang dan entrinya.
///
/// Aturan tulis yang ditegakkan di lapisan ini:
/// - Tanda dan nilai `amount` entri ditentukan [DebtDirection], bukan UI
///   (SPEC H-3, RW-5).
/// - Setiap entri yang punya rekening menulis **satu baris** `transactions`
///   yang terhubung lewat `transactions.debt_entry_id`. Bila rekeningnya
///   kosong, entri tidak memengaruhi saldo mana pun (SPEC M-4).
/// - Menghapus catatan menghapus seluruh entrinya, beserta baris transaksi
///   turunannya (SPEC H-7).
/// - Semua pembacaan menyaring `deleted_at IS NULL` (RW-9).
class DebtRepository {
  DebtRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  /// Kategori baris `transactions` yang lahir dari entri hutang.
  ///
  /// Dipakai supaya pembayaran hutang tetap bisa dipisahkan dari pengeluaran
  /// biasa; VERIFIKASI.md butir 7 menemukan Sepran memang menampilkan baris
  /// "Hutang Piutang" tersendiri di rekap.
  static const String mirroredCategory = 'Hutang Piutang';

  // ---------------------------------------------------------------- membaca

  /// Seluruh catatan beserta `net`-nya, terbaru lebih dulu.
  ///
  /// Rumusnya persis query `debts` di docs/DATA-MODEL.md: jumlah seluruh entri
  /// bertanda, dihitung di SQL, bukan disimpan.
  Stream<List<DebtRecord>> watchRecords() {
    return _db
        .customSelect(
          '''
      SELECT d.id AS id,
             d.party_name AS party_name,
             d.phone AS phone,
             d.date AS date,
             d.note AS note,
             d.is_settled AS is_settled,
             d.target_amount AS target_amount,
             d.target_direction AS target_direction,
             d.paid_opening AS paid_opening,
             COALESCE(SUM(e.amount), 0) AS net,
             COALESCE(SUM(
               CASE
                 WHEN d.target_direction = 'owe' AND e.amount < 0 THEN -e.amount
                 WHEN d.target_direction = 'owed' AND e.amount > 0 THEN e.amount
                 ELSE 0
               END
             ), 0) AS paid_entries
      FROM debts d
      LEFT JOIN debt_entries e
             ON e.debt_id = d.id AND e.deleted_at IS NULL
      WHERE d.deleted_at IS NULL
      GROUP BY d.id
      ORDER BY d.date DESC, d.created_at DESC
      ''',
          readsFrom: {_db.debts, _db.debtEntries},
        )
        .watch()
        .map((rows) => rows.map(_toRecord).toList(growable: false));
  }

  /// Satu catatan, atau null bila tidak ada atau sudah dihapus.
  Stream<DebtRecord?> watchRecord(String id) {
    return _db
        .customSelect(
          '''
      SELECT d.id AS id,
             d.party_name AS party_name,
             d.phone AS phone,
             d.date AS date,
             d.note AS note,
             d.is_settled AS is_settled,
             d.target_amount AS target_amount,
             d.target_direction AS target_direction,
             d.paid_opening AS paid_opening,
             COALESCE(SUM(e.amount), 0) AS net,
             COALESCE(SUM(
               CASE
                 WHEN d.target_direction = 'owe' AND e.amount < 0 THEN -e.amount
                 WHEN d.target_direction = 'owed' AND e.amount > 0 THEN e.amount
                 ELSE 0
               END
             ), 0) AS paid_entries
      FROM debts d
      LEFT JOIN debt_entries e
             ON e.debt_id = d.id AND e.deleted_at IS NULL
      WHERE d.deleted_at IS NULL AND d.id = ?
      GROUP BY d.id
      ''',
          variables: [Variable<String>(id)],
          readsFrom: {_db.debts, _db.debtEntries},
        )
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toRecord(row));
  }

  /// Seluruh entri satu catatan, terbaru lebih dulu.
  Stream<List<DebtEntry>> watchEntries(String debtId) {
    return _db
        .customSelect(
          '''
      SELECT e.id AS id,
             e.debt_id AS debt_id,
             e.amount AS amount,
             e.date AS date,
             e.time AS time,
             e.wallet_id AS wallet_id,
             w.name AS wallet_name,
             e.note AS note
      FROM debt_entries e
      LEFT JOIN wallets w ON w.id = e.wallet_id
      WHERE e.debt_id = ? AND e.deleted_at IS NULL
      ORDER BY e.date DESC, (e.time IS NULL) ASC, e.time DESC, e.created_at DESC
      ''',
          variables: [Variable<String>(debtId)],
          readsFrom: {_db.debtEntries, _db.wallets},
        )
        .watch()
        .map((rows) => rows.map(_toEntry).toList(growable: false));
  }

  /// Nama yang pernah dipakai, untuk field Nama yang boleh dipilih dari yang
  /// sudah ada. SPEC H-12.
  Future<List<String>> partyNames() async {
    final rows = await _db
        .customSelect(
          '''
      SELECT DISTINCT party_name AS party_name
      FROM debts
      WHERE deleted_at IS NULL
      ORDER BY party_name ASC
      ''',
          readsFrom: {_db.debts},
        )
        .get();

    return rows
        .map((row) => row.read<String>('party_name'))
        .toList(growable: false);
  }

  // ---------------------------------------------------------------- menulis

  /// Membuat catatan baru tanpa entri. Mengembalikan id-nya.
  Future<String> createDebt({
    required String partyName,
    required String date,
    String? phone,
    String? note,
  }) async {
    final id = _uuid.v4();

    await _insertDebt(
      id: id,
      partyName: partyName,
      date: date,
      phone: phone,
      note: note,
    );

    return id;
  }

  /// Membuat catatan **beserta entri pertamanya** dalam satu transaksi basis
  /// data, karena entri pertama itu mengubah saldo rekening. RW-1.
  Future<String> createDebtWithEntry({
    required String partyName,
    required String date,
    required int amount,
    String? phone,
    String? note,
    String? time,
    String? walletId,
  }) async {
    if (amount == 0) {
      throw ArgumentError('Nominal entri tidak boleh nol');
    }

    return _db.transaction(() async {
      final debtId = _uuid.v4();
      await _insertDebt(
        id: debtId,
        partyName: partyName,
        date: date,
        phone: phone,
        note: note,
      );

      final entryId = _uuid.v4();
      await _insertEntry(
        id: entryId,
        debtId: debtId,
        amount: amount,
        date: date,
        time: time,
        walletId: walletId,
        note: note,
      );
      await _writeMirror(
        entryId: entryId,
        debtId: debtId,
        amount: amount,
        date: date,
        time: time,
        walletId: walletId,
        note: note,
      );

      return debtId;
    });
  }

  /// Membuat catatan **bertarget** dalam satu baris `debts`.
  ///
  /// Tidak menulis `debt_entries` maupun `transactions`: target adalah metadata
  /// pokok, bukan pergerakan uang (H-18 dan §11 butir 1). [paidOpening] hanya
  /// titik awal progress dan juga tidak menyentuh uang (H-27).
  Future<String> createTarget({
    required String partyName,
    required String date,
    required int targetAmount,
    required DebtTargetDirection direction,
    int paidOpening = 0,
    String? phone,
    String? note,
  }) async {
    _requireValidTarget(targetAmount: targetAmount, paidOpening: paidOpening);

    final id = _uuid.v4();

    await _insertDebt(
      id: id,
      partyName: partyName,
      date: date,
      phone: phone,
      note: note,
      targetAmount: targetAmount,
      targetDirection: direction,
      paidOpening: paidOpening,
    );

    return id;
  }

  /// Mengubah metadata target: nama, tanggal, catatan, target, arah, dan
  /// `paid_opening`. **Tidak menyentuh entri** (H-25).
  Future<void> updateTarget({
    required String id,
    required String partyName,
    required String date,
    required int targetAmount,
    required DebtTargetDirection direction,
    int paidOpening = 0,
    String? phone,
    String? note,
  }) async {
    _requireValidTarget(targetAmount: targetAmount, paidOpening: paidOpening);

    final now = DateTime.now().millisecondsSinceEpoch;
    final name = DebtRules.normalize(partyName);

    await _db.transaction(() async {
      await (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
        DebtsCompanion(
          partyName: Value(name),
          date: Value(date),
          phone: Value(DebtRules.blankToNull(phone)),
          note: Value(DebtRules.blankToNull(note)),
          targetAmount: Value(targetAmount),
          targetDirection: Value(direction.storageValue),
          paidOpening: Value(paidOpening),
          updatedAt: Value(now),
        ),
      );

      await _syncMirrorTitles(id, name, now);
    });
  }

  /// Mengosongkan target. Catatan tetap ada beserta seluruh entrinya dan
  /// kembali muncul sebagai catatan Normal biasa.
  Future<void> clearTarget(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
      DebtsCompanion(
        targetAmount: Value<int?>(null),
        targetDirection: Value<String?>(null),
        paidOpening: const Value(0),
        updatedAt: Value(now),
      ),
    );
  }

  void _requireValidTarget({
    required int targetAmount,
    required int paidOpening,
  }) {
    if (targetAmount <= 0) {
      throw ArgumentError('Target harus lebih besar dari nol');
    }
    if (paidOpening < 0) {
      throw ArgumentError('Sudah dibayar tidak boleh negatif');
    }
  }

  /// Menyunting catatan. Judul baris transaksi turunan ikut disesuaikan supaya
  /// namanya tidak basi.
  Future<void> updateDebt({
    required String id,
    required String partyName,
    required String date,
    String? phone,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final name = DebtRules.normalize(partyName);

    await _db.transaction(() async {
      await (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
        DebtsCompanion(
          partyName: Value(name),
          date: Value(date),
          phone: Value(DebtRules.blankToNull(phone)),
          note: Value(DebtRules.blankToNull(note)),
          updatedAt: Value(now),
        ),
      );

      await _syncMirrorTitles(id, name, now);
    });
  }

  /// Menandai catatan lunas atau membatalkannya. SPEC H-9.
  Future<void> setSettled(String id, bool settled) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
      DebtsCompanion(isSettled: Value(settled), updatedAt: Value(now)),
    );
  }

  /// Menambahkan entri ke catatan yang sudah ada. Mengembalikan id entrinya.
  ///
  /// [amount] sudah bertanda, disusun lewat [DebtDirection.apply].
  Future<String> addEntry({
    required String debtId,
    required int amount,
    required String date,
    String? time,
    String? walletId,
    String? note,
  }) async {
    if (amount == 0) {
      throw ArgumentError('Nominal entri tidak boleh nol');
    }

    final entryId = _uuid.v4();

    await _db.transaction(() async {
      await _insertEntry(
        id: entryId,
        debtId: debtId,
        amount: amount,
        date: date,
        time: time,
        walletId: walletId,
        note: note,
      );
      await _writeMirror(
        entryId: entryId,
        debtId: debtId,
        amount: amount,
        date: date,
        time: time,
        walletId: walletId,
        note: note,
      );
    });

    return entryId;
  }

  /// Mencatat **pembayaran** sebuah target.
  ///
  /// Pembungkus [addEntry] yang:
  /// - menentukan tanda dari arah target (`owe` → Memberi, `owed` → Menerima),
  /// - **mewajibkan rekening** supaya saldo benar-benar berkurang (H-21),
  /// - menulis cermin `transactions` seperti entri biasa.
  ///
  /// [magnitude] selalu besar positif; pengguna tidak mengetik tanda.
  Future<String> addPayment({
    required String debtId,
    required int magnitude,
    required String date,
    required String? walletId,
    String? time,
    String? note,
  }) async {
    if (walletId == null || walletId.trim().isEmpty) {
      throw const DebtPaymentException(DebtRules.walletRequiredForPayment);
    }

    final debt = await (_db.select(
      _db.debts,
    )..where((row) => row.id.equals(debtId))).getSingleOrNull();
    final direction = DebtTargetDirection.fromStorage(debt?.targetDirection);

    if (debt == null || direction == null) {
      throw const DebtPaymentException(DebtRules.targetMissing);
    }

    return addEntry(
      debtId: debtId,
      amount: direction.paymentDirection.apply(magnitude),
      date: date,
      time: time,
      walletId: walletId,
      note: note,
    );
  }

  /// Menyunting satu entri, beserta baris transaksi turunannya.
  Future<void> updateEntry({
    required String id,
    required int amount,
    required String date,
    String? time,
    String? walletId,
    String? note,
  }) async {
    if (amount == 0) {
      throw ArgumentError('Nominal entri tidak boleh nol');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final entry = await (_db.select(
        _db.debtEntries,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (entry == null) return;

      await (_db.update(
        _db.debtEntries,
      )..where((row) => row.id.equals(id))).write(
        DebtEntriesCompanion(
          amount: Value(amount),
          date: Value(date),
          time: Value(time),
          walletId: Value(walletId),
          note: Value(DebtRules.blankToNull(note)),
          updatedAt: Value(now),
        ),
      );

      await _writeMirror(
        entryId: id,
        debtId: entry.debtId,
        amount: amount,
        date: date,
        time: time,
        walletId: walletId,
        note: note,
      );
    });
  }

  /// Hapus lunak satu entri, beserta baris transaksinya.
  Future<void> deleteEntry(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await (_db.update(
        _db.debtEntries,
      )..where((row) => row.id.equals(id))).write(
        DebtEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await _softDeleteTransactionsOf({id}, now);
    });
  }

  /// Hapus lunak catatan **beserta seluruh entrinya**, seperti `on delete
  /// cascade` pada SPEC H-7, termasuk baris transaksi turunannya.
  Future<void> deleteDebt(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      final entries = await (_db.select(
        _db.debtEntries,
      )..where((row) => row.debtId.equals(id) & row.deletedAt.isNull())).get();
      final entryIds = entries.map((entry) => entry.id).toSet();

      if (entryIds.isNotEmpty) {
        await _softDeleteTransactionsOf(entryIds, now);
      }

      await (_db.update(
        _db.debtEntries,
      )..where((row) => row.debtId.equals(id))).write(
        DebtEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      await (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
        DebtsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    });
  }

  // ---------------------------------------------------------------- bantuan

  Future<void> _insertDebt({
    required String id,
    required String partyName,
    required String date,
    String? phone,
    String? note,
    int? targetAmount,
    DebtTargetDirection? targetDirection,
    int paidOpening = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.debts)
        .insert(
          DebtsCompanion.insert(
            id: id,
            partyName: DebtRules.normalize(partyName),
            date: date,
            createdAt: now,
            updatedAt: now,
            phone: Value(DebtRules.blankToNull(phone)),
            note: Value(DebtRules.blankToNull(note)),
            targetAmount: Value(targetAmount),
            targetDirection: Value(targetDirection?.storageValue),
            paidOpening: Value(paidOpening),
          ),
        );
  }

  Future<void> _insertEntry({
    required String id,
    required String debtId,
    required int amount,
    required String date,
    String? time,
    String? walletId,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.debtEntries)
        .insert(
          DebtEntriesCompanion.insert(
            id: id,
            debtId: debtId,
            amount: amount,
            date: date,
            createdAt: now,
            updatedAt: now,
            time: Value(time),
            walletId: Value(walletId),
            note: Value(DebtRules.blankToNull(note)),
          ),
        );
  }

  /// Menyelaraskan judul seluruh baris transaksi cermin dengan nama catatan.
  Future<void> _syncMirrorTitles(String debtId, String name, int now) {
    return _db.customUpdate(
      'UPDATE transactions SET title = ?, updated_at = ? '
      'WHERE deleted_at IS NULL AND debt_entry_id IN '
      '  (SELECT id FROM debt_entries WHERE debt_id = ?)',
      variables: [
        Variable<String>(name),
        Variable<int>(now),
        Variable<String>(debtId),
      ],
      updates: {_db.transactions, _db.debtEntries},
    );
  }

  /// Menjaga baris `transactions` tetap sejalan dengan sebuah entri.
  ///
  /// Satu entri hanya boleh punya **satu** baris transaksi aktif:
  /// - rekening kosong → tidak ada baris transaksi (SPEC M-4),
  /// - rekening terisi → baris dibuat, diperbarui, atau dihidupkan kembali.
  Future<void> _writeMirror({
    required String entryId,
    required String debtId,
    required int amount,
    required String date,
    String? time,
    String? walletId,
    String? note,
  }) async {
    final rows = await (_db.select(
      _db.transactions,
    )..where((row) => row.debtEntryId.equals(entryId))).get();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (walletId == null) {
      for (final row in rows) {
        if (row.deletedAt == null) {
          await _softDeleteTransaction(row.id, now);
        }
      }
      return;
    }

    final debt = await (_db.select(
      _db.debts,
    )..where((row) => row.id.equals(debtId))).getSingleOrNull();
    final title = debt?.partyName ?? '';
    final kind = (amount > 0 ? TxKind.income : TxKind.expense).storageValue;

    final active = _firstWhereOrNull(rows, (row) => row.deletedAt == null);
    final target = active ?? _firstWhereOrNull(rows, (row) => true);

    if (target == null) {
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: _uuid.v4(),
              kind: kind,
              walletId: walletId,
              amount: amount,
              date: date,
              createdAt: now,
              updatedAt: now,
              title: Value(title),
              category: const Value(mirroredCategory),
              note: Value(DebtRules.blankToNull(note)),
              time: Value(time),
              debtEntryId: Value(entryId),
            ),
          );
      return;
    }

    await (_db.update(
      _db.transactions,
    )..where((row) => row.id.equals(target.id))).write(
      TransactionsCompanion(
        kind: Value(kind),
        walletId: Value(walletId),
        amount: Value(amount),
        date: Value(date),
        title: Value(title),
        category: const Value(mirroredCategory),
        note: Value(DebtRules.blankToNull(note)),
        time: Value(time),
        // Sekaligus menghidupkan kembali baris yang tadi ikut terhapus saat
        // rekeningnya dikosongkan.
        deletedAt: const Value<int?>(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _softDeleteTransactionsOf(Set<String> entryIds, int now) async {
    if (entryIds.isEmpty) return;

    await (_db.update(_db.transactions)..where(
          (row) => row.debtEntryId.isIn(entryIds) & row.deletedAt.isNull(),
        ))
        .write(
          TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
  }

  Future<void> _softDeleteTransaction(String id, int now) async {
    await (_db.update(
      _db.transactions,
    )..where((row) => row.id.equals(id))).write(
      TransactionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  DebtRecord _toRecord(QueryRow row) => DebtRecord(
    id: row.read<String>('id'),
    partyName: row.read<String>('party_name'),
    phone: row.read<String?>('phone'),
    date: row.read<String>('date'),
    note: row.read<String?>('note'),
    // Dibaca sebagai bilangan bulat, bukan bool: nilainya tersimpan sebagai
    // 0/1 di SQLite dan query ini mentah.
    isSettled: row.read<int>('is_settled') != 0,
    targetAmount: row.read<int?>('target_amount'),
    targetDirection: DebtTargetDirection.fromStorage(
      row.read<String?>('target_direction'),
    ),
    paidOpening: row.read<int>('paid_opening'),
    paidEntries: row.read<int>('paid_entries'),
    net: row.read<int>('net'),
  );

  DebtEntry _toEntry(QueryRow row) => DebtEntry(
    id: row.read<String>('id'),
    debtId: row.read<String>('debt_id'),
    amount: row.read<int>('amount'),
    date: row.read<String>('date'),
    time: row.read<String?>('time'),
    walletId: row.read<String?>('wallet_id'),
    walletName: row.read<String?>('wallet_name'),
    note: row.read<String?>('note'),
  );
}

/// `firstWhereOrNull` tanpa menarik paket `collection`.
T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
