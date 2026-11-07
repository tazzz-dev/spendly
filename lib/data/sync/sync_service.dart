import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import 'sync_config.dart';
import 'sync_tables.dart';

/// Hasil satu putaran sinkronisasi.
class SyncOutcome {
  const SyncOutcome({
    required this.pulled,
    required this.pushed,
    required this.at,
  });

  /// Baris dari cloud yang benar-benar mengubah basis data lokal.
  final int pulled;

  /// Baris lokal yang dikirim ke cloud.
  final int pushed;

  final DateTime at;
}

/// Sinkronisasi dua arah dengan Supabase, memakai aturan **last write wins**
/// berdasarkan `updated_at`.
///
/// Alurnya per tabel, mengikuti urutan [syncTables]:
///
/// 1. Tarik baris cloud yang `updated_at`-nya lebih baru dari penanda terakhir.
/// 2. Tulis ke SQLite hanya bila versi cloud lebih baru.
/// 3. Kirim baris lokal yang berubah sejak penanda terakhir.
/// 4. Simpan penanda baru.
///
/// Penanda disimpan di `app_settings` pada perangkat ini. Bila pengguna masuk
/// dengan akun lain, [SyncAccountMismatch] dilempar supaya data dua akun tidak
/// tercampur tanpa sepengetahuan pengguna.
///
/// Konflik yang tidak bisa diselesaikan dengan waktu (mis. jam perangkat mundur)
/// diselesaikan dengan cara yang sama: versi dengan `updated_at` lebih besar
/// menang, dan baris yang kalah tetap tersimpan sebagai revisi lama di cloud
/// sampai ditimpa. Untuk aplikasi pencatatan pribadi ini disengaja: sederhana
/// dan dapat dijelaskan, bukan mesin CRDT.
class SyncService {
  SyncService(this._db, this._client);

  final AppDatabase _db;
  final SupabaseClient _client;

  /// Berapa baris per permintaan. PostgREST membatasi jumlah baris per respons
  /// (biasanya 1000), jadi penarikan dipecah menjadi halaman.
  static const int _pageSize = 500;

  /// Berapa baris per unggahan. Payload besar membuat permintaan lambat dan
  /// lebih mudah gagal di jaringan seluler.
  static const int _pushChunk = 200;

  /// Toleransi jam perangkat yang mundur sedikit. Tanpa ini, baris yang
  /// `updated_at`-nya sama dengan penanda bisa terlewat.
  static const int _overlapMs = 120000;

  static const String _accountKey = 'sync.account_id';
  static const String _lastSyncKey = 'sync.last_synced_at';

  /// Tabel drift untuk setiap nama, dipakai agar stream lokal ikut diperbarui
  /// setelah penulisan lewat SQL mentah.
  ResultSetImplementation _tableInfo(String name) => switch (name) {
    'wallets' => _db.wallets,
    'debts' => _db.debts,
    'budgets' => _db.budgets,
    'custom_reports' => _db.customReports,
    'transactions' => _db.transactions,
    'debt_entries' => _db.debtEntries,
    _ => throw ArgumentError('Tabel tidak dikenal: $name'),
  };

  // ------------------------------------------------------------------- publik

  /// Waktu sinkronisasi terakhir yang berhasil, atau `null`.
  Future<DateTime?> lastSyncedAt() async {
    final value = await _readSetting(_lastSyncKey);
    if (value == null) return null;
    final millis = int.tryParse(value);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Memakai akun yang sedang masuk untuk basis data ini.
  ///
  /// Semua penanda sinkronisasi dihapus supaya putaran berikutnya membaca dan
  /// mengirim ulang seluruh data. Data lokal **tidak** dihapus.
  Future<void> adoptCurrentAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const SyncException('Masuk dengan Google terlebih dahulu.');
    }

    await _db.customUpdate(
      "DELETE FROM app_settings WHERE key LIKE 'sync.%'",
      updates: {_db.appSettings},
    );
    await _writeSetting(_accountKey, user.id);
  }

  /// Satu putaran penuh. Melempar [SyncAccountMismatch] bila akun berbeda.
  Future<SyncOutcome> syncNow() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const SyncException('Masuk dengan Google terlebih dahulu.');
    }

    final storedAccount = await _readSetting(_accountKey);
    if (storedAccount != null && storedAccount != user.id) {
      throw SyncAccountMismatch(storedAccount);
    }
    if (storedAccount == null) {
      await _writeSetting(_accountKey, user.id);
    }

    var pulled = 0;
    var pushed = 0;

    try {
      for (final table in syncTables) {
        pulled += await _pullAndMerge(table);
        pushed += await _pushTable(table);
      }
    } on AuthException catch (error) {
      throw SyncException('Sesi login berakhir. Masuk lagi: ${error.message}');
    } on PostgrestException catch (error) {
      throw SyncException('Cloud menolak permintaan: ${error.message}');
    } catch (error) {
      throw SyncException('Sinkronisasi gagal: $error');
    }

    final at = DateTime.now();
    await _writeSetting(_lastSyncKey, '${at.millisecondsSinceEpoch}');

    return SyncOutcome(pulled: pulled, pushed: pushed, at: at);
  }

  // -------------------------------------------------------------------- tarik

  Future<int> _pullAndMerge(SyncTable table) async {
    final cursor = await _readCursor('sync.pull.${table.name}');
    final remoteRows = await _fetchRemote(table, cursor);
    if (remoteRows.isEmpty) return 0;

    final maxUpdatedAt = remoteRows.fold<int>(cursor, (max, row) {
      final value = row['updated_at'];
      final updated = value is int ? value : int.tryParse('$value') ?? 0;
      return updated > max ? updated : max;
    });

    var applied = 0;
    for (final row in remoteRows) {
      applied += await _db.customUpdate(
        syncUpsertSql(table),
        variables: [
          for (final column in table.columns) Variable<Object>(row[column]),
        ],
        updates: {_tableInfo(table.name)},
      );
    }

    await _writeCursor('sync.pull.${table.name}', maxUpdatedAt);
    return applied;
  }

  Future<List<Map<String, dynamic>>> _fetchRemote(
    SyncTable table,
    int cursor,
  ) async {
    final rows = <Map<String, dynamic>>[];

    for (var offset = 0; ; offset += _pageSize) {
      final page = await _client
          .from(table.name)
          .select(table.columns.join(', '))
          .gt('updated_at', cursor)
          .order('updated_at', ascending: true)
          .range(offset, offset + _pageSize - 1);

      rows.addAll(page);
      if (page.length < _pageSize) break;
    }

    return rows;
  }

  // -------------------------------------------------------------------- kirim

  Future<int> _pushTable(SyncTable table) async {
    final cursor = await _readCursor('sync.push.${table.name}');
    final since = cursor > 0 ? cursor - _overlapMs : 0;

    final rows = await _db
        .customSelect(
          'SELECT ${table.columns.join(', ')} FROM ${table.name} '
          'WHERE updated_at > ? ORDER BY updated_at ASC',
          variables: [Variable<int>(since)],
        )
        .get();

    if (rows.isEmpty) return 0;

    final payload = <Map<String, dynamic>>[
      for (final row in rows)
        {for (final column in table.columns) column: row.read<Object?>(column)},
    ];

    for (var start = 0; start < payload.length; start += _pushChunk) {
      final end = (start + _pushChunk).clamp(0, payload.length);
      await _client
          .from(table.name)
          .upsert(payload.sublist(start, end), onConflict: 'id');
    }

    await _writeCursor('sync.push.${table.name}', _maxUpdatedAt(rows, cursor));
    return payload.length;
  }

  int _maxUpdatedAt(List<QueryRow> rows, int fallback) {
    var max = fallback;
    for (final row in rows) {
      final value = row.read<int>('updated_at');
      if (value > max) max = value;
    }
    return max;
  }

  // ----------------------------------------------------------------- penanda

  Future<int> _readCursor(String key) async {
    final value = await _readSetting(key);
    return int.tryParse(value ?? '') ?? 0;
  }

  Future<void> _writeCursor(String key, int value) =>
      _writeSetting(key, '$value');

  Future<String?> _readSetting(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _writeSetting(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );
}
