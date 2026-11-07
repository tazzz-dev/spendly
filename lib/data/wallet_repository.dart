import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/wallet_balance.dart';
import '../domain/wallet_rules.dart';
import '../domain/wallet_type.dart';
import 'db/app_database.dart';

/// Seluruh penulisan dan pembacaan rekening lewat sini.
///
/// Lapisan ini yang menjaga aturan tulis di `docs/DATA-MODEL.md`. Tidak ada
/// penulisan langsung dari UI.
class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  /// Rekening beserta saldonya, sudah urut menurut frekuensi pemakaian.
  /// Lihat SPEC R-2 dan R-3.
  Stream<List<WalletBalance>> watchBalances() => _db.watchWalletBalances();

  /// SPEC G-9: nama rekening harus unik, **tanpa memandang besar-kecil huruf**.
  ///
  /// "BCA" dan "bca" dianggap nama yang sama.
  ///
  /// Diperiksa lebih dulu supaya pengguna menerima pesan yang jelas, bukan
  /// galat basis data. Index unik parsial tetap menjadi jaring pengaman
  /// terakhir, karena pemeriksaan di sini bisa kalah balapan.
  ///
  /// [exceptId] dipakai saat menyunting, supaya rekening tidak dianggap
  /// bentrok dengan namanya sendiri.
  Future<bool> isNameTaken(String name, {String? exceptId}) async {
    // Pembandingnya dilakukan di Dart, bukan `lower()` di SQLite, supaya
    // aturannya sama persis dengan [WalletName.fold] yang diuji di lapisan
    // domain — termasuk untuk huruf beraksen, yang `lower()` SQLite biarkan.
    // Daftar rekening selalu kecil, jadi membaca seluruhnya tidak mahal.
    final folded = WalletName.fold(name);
    final rows = await (_db.select(
      _db.wallets,
    )..where((wallet) => wallet.deletedAt.isNull())).get();

    return rows.any(
      (wallet) =>
          wallet.id != exceptId && WalletName.fold(wallet.name) == folded,
    );
  }

  /// Membuat rekening baru dan mengembalikan id-nya.
  Future<String> create({
    required String name,
    required WalletType type,
    required int openingBalance,
    required String iconKey,
    required int color,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: id,
            name: WalletName.normalize(name),
            type: type.storageValue,
            icon: Value(iconKey),
            color: Value(color),
            openingBalance: Value(openingBalance),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  /// Menyunting rekening **termasuk saldo awal**.
  ///
  /// Nama wajib sudah lolos pemeriksaan [isNameTaken]. Layar Ubah Rekening
  /// memakai [updateDetails], bukan method ini, supaya riwayat tidak bergeser.
  Future<void> update({
    required String id,
    required String name,
    required WalletType type,
    required int openingBalance,
    required String iconKey,
    required int color,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(
      _db.wallets,
    )..where((wallet) => wallet.id.equals(id))).write(
      WalletsCompanion(
        name: Value(WalletName.normalize(name)),
        type: Value(type.storageValue),
        icon: Value(iconKey),
        color: Value(color),
        openingBalance: Value(openingBalance),
        updatedAt: Value(now),
      ),
    );
  }

  /// Menyunting nama, tipe, ikon, dan warna **tanpa mengubah saldo awal**.
  ///
  /// Dipakai layar Ubah Rekening. Saldo yang terlihat pengguna adalah saldo
  /// saat ini, bukan saldo awal; mengubahnya harus menjadi Koreksi Saldo,
  /// bukan menulis ulang titik mula seluruh riwayat. Lihat SPEC K-6.
  Future<void> updateDetails({
    required String id,
    required String name,
    required WalletType type,
    required String iconKey,
    required int color,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(
      _db.wallets,
    )..where((wallet) => wallet.id.equals(id))).write(
      WalletsCompanion(
        name: Value(WalletName.normalize(name)),
        type: Value(type.storageValue),
        icon: Value(iconKey),
        color: Value(color),
        updatedAt: Value(now),
      ),
    );
  }

  /// Memeriksa apakah rekening boleh dihapus, beserta sebabnya bila tidak.
  ///
  /// SPEC R-4, R-5, dan G-8.
  Future<WalletDeleteVerdict> checkDelete(String id) async {
    final wallet = await (_db.select(
      _db.wallets,
    )..where((row) => row.id.equals(id))).getSingleOrNull();

    if (wallet == null) {
      // Sudah tidak ada; anggap saja boleh, supaya layar tidak tersangkut.
      return const WalletDeleteVerdict.allowed();
    }
    if (wallet.isDefault) {
      return const WalletDeleteVerdict.blocked(WalletDeleteBlock.isDefault, 0);
    }

    final usage = await _usageCount(id);
    if (usage > 0) {
      return WalletDeleteVerdict.blocked(WalletDeleteBlock.inUse, usage);
    }
    return const WalletDeleteVerdict.allowed();
  }

  /// Hapus lunak. Barisnya tetap ada, hanya ditandai. Lihat SPEC T-8.
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.wallets)..where((wallet) => wallet.id.equals(id)))
        .write(WalletsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// Berapa pergerakan yang masih menunjuk rekening ini.
  ///
  /// Tiga tempat bisa menunjuk sebuah rekening: transaksi sebagai rekening asal,
  /// transaksi sebagai rekening pasangan pada pindah saldo, dan entri hutang.
  /// Ketiganya diperiksa — kalau satu saja terlewat, aturan R-4 bocor.
  Future<int> _usageCount(String id) async {
    final row = await _db
        .customSelect(
          '''
      SELECT
        (SELECT COUNT(*) FROM transactions
          WHERE deleted_at IS NULL
            AND (wallet_id = ? OR counter_wallet_id = ?))
      + (SELECT COUNT(*) FROM debt_entries
          WHERE deleted_at IS NULL
            AND wallet_id = ?) AS usage_count
      ''',
          variables: [
            Variable<String>(id),
            Variable<String>(id),
            Variable<String>(id),
          ],
          readsFrom: {_db.transactions, _db.debtEntries},
        )
        .getSingle();

    return row.read<int>('usage_count');
  }
}
