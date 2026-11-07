import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/captured_notification.dart';
import '../domain/notification_draft.dart';
import '../domain/notification_parser.dart';
import 'db/app_database.dart';
import 'transaction_repository.dart';

/// Gerbang tunggal untuk inbox notifikasi.
///
/// Notifikasi mentah tidak pernah menulis tabel transaksi. Ia hanya menjadi
/// draft sampai pengguna mengisi judul dan kategori di layar konfirmasi.
class NotificationRepository {
  NotificationRepository(
    this._db,
    this._transactions, {
    this.parser = const NotificationParserEngine(),
  });

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final NotificationParserEngine parser;

  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------- membaca

  /// Draft yang masih menunggu keputusan pengguna, terbaru lebih dulu.
  Stream<List<NotificationDraft>> watchPending() {
    return (_db.select(_db.notificationDrafts)
          ..where(
            (row) =>
                row.status.equals(
                  NotificationDraftStatus.pending.storageValue,
                ) &
                row.deletedAt.isNull(),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.occurredAt)]))
        .watch()
        .map((rows) => rows.map(_toDraft).toList(growable: false));
  }

  /// Jumlah draft pending, untuk badge lonceng.
  Stream<int> watchPendingCount() {
    return _db
        .customSelect(
          '''
          SELECT COUNT(*) AS jumlah
          FROM notification_drafts
          WHERE status = ?
            AND deleted_at IS NULL
          ''',
          variables: [
            Variable<String>(NotificationDraftStatus.pending.storageValue),
          ],
          readsFrom: {_db.notificationDrafts},
        )
        .watchSingle()
        .map((row) => row.read<int>('jumlah'));
  }

  /// Jumlah draft pending saat ini.
  ///
  /// Dipakai badge yang membaca ulang secara berkala: mesin Flutter latar
  /// menulis ke basis data yang sama, tetapi stream drift di mesin utama tidak
  /// otomatis mendapat notifikasi perubahan dari isolate lain.
  Future<int> countPending() async {
    final row = await _db
        .customSelect(
          '''
          SELECT COUNT(*) AS jumlah
          FROM notification_drafts
          WHERE status = ?
            AND deleted_at IS NULL
          ''',
          variables: [
            Variable<String>(NotificationDraftStatus.pending.storageValue),
          ],
          readsFrom: {_db.notificationDrafts},
        )
        .getSingle();
    return row.read<int>('jumlah');
  }

  /// Semua pemetaan aplikasi ke rekening yang masih aktif.
  Stream<List<AccountNotificationMapping>> watchMappings() {
    return _db
        .customSelect(
          '''
          SELECT m.id AS id,
                 m.package_name AS package_name,
                 m.wallet_id AS wallet_id,
                 w.name AS wallet_name
          FROM account_notification_mappings m
          JOIN wallets w ON w.id = m.wallet_id
          WHERE m.deleted_at IS NULL
          ORDER BY m.package_name ASC
          ''',
          readsFrom: {_db.accountNotificationMappings, _db.wallets},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => AccountNotificationMapping(
                  id: row.read<String>('id'),
                  packageName: row.read<String>('package_name'),
                  walletId: row.read<String>('wallet_id'),
                  walletName: row.read<String>('wallet_name'),
                ),
              )
              .toList(growable: false),
        );
  }

  /// Rekening yang dipetakan ke satu paket, atau null bila belum ada.
  Future<String?> walletForPackage(String packageName) async {
    final row = await activeMapping(packageName);
    return row?.walletId;
  }

  Future<AccountNotificationMappingRow?> activeMapping(
    String packageName,
  ) async {
    return (_db.select(_db.accountNotificationMappings)
          ..where(
            (row) =>
                row.packageName.equals(packageName) & row.deletedAt.isNull(),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------- menulis

  /// Mengubah satu event mentah menjadi draft, bila lolos parser.
  ///
  /// Mengembalikan `true` bila event sudah selesai diproses — baik karena
  /// disimpan, sudah pernah ada, maupun karena memang bukan transaksi. Nilai
  /// ini dipakai pemanggil untuk menghapus event dari antrean native. Galat
  /// basis data dibiarkan naik supaya event tidak hilang dan bisa dicoba lagi.
  Future<bool> ingest(CapturedNotification event) async {
    if (!event.isValid) return true;

    final parsed = parser.parse(
      packageName: event.packageName,
      title: event.title,
      message: event.message,
    );
    if (parsed == null) return true;

    final exists =
        await (_db.select(_db.notificationDrafts)
              ..where((row) => row.sourceKey.equals(event.sourceKey))
              ..limit(1))
            .getSingleOrNull();
    if (exists != null) return true;

    final occurred = DateTime.fromMillisecondsSinceEpoch(event.postedAt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final mappedWallet = await walletForPackage(event.packageName);

    await _db
        .into(_db.notificationDrafts)
        .insert(
          NotificationDraftsCompanion.insert(
            id: _uuid.v4(),
            packageName: event.packageName,
            appName: parsed.source.appName,
            rawTitle: event.title,
            rawMessage: event.message,
            amount: parsed.amount,
            type: parsed.type.storageValue,
            walletId: Value(mappedWallet),
            occurredAt: event.postedAt,
            date: _dateKey(occurred),
            time: Value(_timeKey(occurred)),
            status: const Value('pending'),
            sourceKey: event.sourceKey,
            createdAt: now,
            updatedAt: now,
          ),
          // Dua mesin (utama dan latar) dapat memproses event yang sama
          // bersamaan. Index unik source_key yang menjadi wasit terakhir.
          mode: InsertMode.insertOrIgnore,
        );

    return true;
  }

  /// Memproses banyak event dan mengembalikan ID yang aman dihapus dari
  /// antrean native.
  ///
  /// Event yang gagal disimpan sengaja tidak masuk hasil, sehingga tetap ada
  /// di antrean dan dicoba lagi pada kesempatan berikutnya.
  Future<Set<String>> ingestMany(Iterable<CapturedNotification> events) async {
    final acknowledged = <String>{};
    for (final event in events) {
      try {
        await ingest(event);
        acknowledged.add(event.id);
      } catch (_) {
        // Biarkan event di antrean. Jangan mencatat isi notifikasi ke log:
        // teks itu bisa memuat data keuangan pribadi.
      }
    }
    return acknowledged;
  }

  /// Menyetujui draft dan menulis transaksi resmi.
  ///
  /// Judul dan kategori wajib diisi pengguna. Rekening boleh berbeda dari
  /// hasil pemetaan bila pengguna memilih rekening lain di layar konfirmasi.
  Future<String> approve({
    required NotificationDraft draft,
    required String title,
    required String category,
    required String walletId,
  }) async {
    final cleanTitle = title.trim();
    final cleanCategory = category.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Judul harus diisi');
    }
    if (cleanCategory.isEmpty) {
      throw ArgumentError('Kategori harus diisi');
    }
    if (walletId.trim().isEmpty) {
      throw ArgumentError('Rekening harus dipilih');
    }

    return _db.transaction(() async {
      final row =
          await (_db.select(_db.notificationDrafts)..where(
                (row) =>
                    row.id.equals(draft.id) &
                    row.status.equals(
                      NotificationDraftStatus.pending.storageValue,
                    ) &
                    row.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (row == null) {
        throw StateError('Draft sudah diproses atau tidak ditemukan');
      }

      final type = NotificationDraftType.fromStorage(row.type);
      final transactionId = await _transactions.createSimple(
        kind: type.txKind,
        amount: row.amount,
        walletId: walletId,
        title: cleanTitle,
        category: cleanCategory,
        date: row.date,
        time: row.time,
        note: 'Dari notifikasi ${row.appName}',
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(
        _db.notificationDrafts,
      )..where((row) => row.id.equals(draft.id))).write(
        NotificationDraftsCompanion(
          status: const Value('approved'),
          walletId: Value(walletId),
          approvedTransactionId: Value(transactionId),
          updatedAt: Value(now),
        ),
      );

      return transactionId;
    });
  }

  /// Menolak draft. Baris tidak dihapus permanen; statusnya menjadi ignored dan
  /// `deleted_at` diisi, sesuai aturan hapus lunak proyek.
  Future<void> ignore(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.notificationDrafts,
    )..where((row) => row.id.equals(id))).write(
      NotificationDraftsCompanion(
        status: const Value('ignored'),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Menyimpan atau mengganti rekening untuk satu paket aplikasi.
  Future<void> setMapping({
    required String packageName,
    required String walletId,
  }) async {
    final cleanPackage = packageName.trim();
    if (cleanPackage.isEmpty || walletId.trim().isEmpty) {
      throw ArgumentError('Paket dan rekening harus diisi');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      final existing = await activeMapping(cleanPackage);
      if (existing == null) {
        await _db
            .into(_db.accountNotificationMappings)
            .insert(
              AccountNotificationMappingsCompanion.insert(
                id: _uuid.v4(),
                packageName: cleanPackage,
                walletId: walletId,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.accountNotificationMappings,
        )..where((row) => row.id.equals(existing.id))).write(
          AccountNotificationMappingsCompanion(
            walletId: Value(walletId),
            updatedAt: Value(now),
          ),
        );
      }

      // Draft yang sudah telanjur masuk sebelum pemetaan dibuat ikut terisi,
      // supaya pengguna tidak perlu memilih rekening yang sama berulang kali.
      await (_db.update(_db.notificationDrafts)..where(
            (row) =>
                row.packageName.equals(cleanPackage) &
                row.walletId.isNull() &
                row.status.equals(
                  NotificationDraftStatus.pending.storageValue,
                ) &
                row.deletedAt.isNull(),
          ))
          .write(
            NotificationDraftsCompanion(
              walletId: Value(walletId),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<void> clearMapping(String packageName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.accountNotificationMappings)..where(
          (row) => row.packageName.equals(packageName) & row.deletedAt.isNull(),
        ))
        .write(
          AccountNotificationMappingsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Mengubah waktu lokal menjadi kunci tanggal tanpa bergantung pada intl
  /// atau zona waktu perangkat.
  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _timeKey(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  NotificationDraft _toDraft(NotificationDraftRow row) {
    return NotificationDraft(
      id: row.id,
      packageName: row.packageName,
      appName: row.appName,
      rawTitle: row.rawTitle,
      rawMessage: row.rawMessage,
      amount: row.amount,
      type: NotificationDraftType.fromStorage(row.type),
      walletId: row.walletId,
      occurredAt: row.occurredAt,
      date: row.date,
      time: row.time,
      status: NotificationDraftStatus.fromStorage(row.status),
      sourceKey: row.sourceKey,
      approvedTransactionId: row.approvedTransactionId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
