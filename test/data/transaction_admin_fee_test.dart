import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/data/db/app_database.dart';
import 'package:pencatatan_keuangan/data/transaction_repository.dart';
import 'package:pencatatan_keuangan/data/wallet_repository.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';
import 'package:pencatatan_keuangan/domain/tx_rules.dart';
import 'package:pencatatan_keuangan/domain/wallet_type.dart';

/// Biaya admin Pindah Saldo disimpan sebagai baris pengeluaran tersendiri di
/// rekening asal. Berkas uji ini menjaga tiga hal yang mudah rusak: saldo asal
/// ikut terpotong, biaya bisa diubah/dihapus, dan menghapus transfer tidak
/// meninggalkan biaya yatim.
void main() {
  late AppDatabase db;
  late TransactionRepository repository;
  late WalletRepository wallets;
  late String sourceId;
  late String destinationId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepository(db);
    wallets = WalletRepository(db);
    sourceId = (await wallets.watchBalances().first)
        .firstWhere((wallet) => wallet.isDefault)
        .id;
    destinationId = await wallets.create(
      name: 'GoPay',
      type: WalletType.ewallet,
      openingBalance: 0,
      iconKey: 'wallet',
      color: 0xFF00AA13,
    );
  });

  tearDown(() => db.close());

  Future<int> balanceOf(String walletId) async =>
      (await wallets.watchBalances().first)
          .firstWhere((wallet) => wallet.id == walletId)
          .balance;

  Future<List<TxRow>> rows() => db.select(db.transactions).get();

  test('biaya admin memotong rekening asal, bukan rekening tujuan', () async {
    final groupId = await repository.createTransfer(
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      time: '09:00',
      adminFee: 5000,
    );

    final all = await rows();
    expect(all, hasLength(3));
    expect(await balanceOf(sourceId), -105000);
    expect(await balanceOf(destinationId), 100000);
    expect(await repository.adminFeeForGroup(groupId), 5000);

    final fee = all.singleWhere(
      (row) => row.kind == TxKind.expense.storageValue,
    );
    expect(fee.amount, -5000);
    expect(fee.transferGroupId, groupId);
    expect(fee.walletId, sourceId);
  });

  test('tanpa biaya admin hanya dua baris transfer yang ditulis', () async {
    final groupId = await repository.createTransfer(
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
    );

    expect(await rows(), hasLength(2));
    expect(await repository.adminFeeForGroup(groupId), 0);
    expect(await balanceOf(sourceId), -100000);
    expect(await balanceOf(destinationId), 100000);
  });

  test('mengubah biaya admin memperbarui baris yang sudah ada', () async {
    final groupId = await repository.createTransfer(
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      adminFee: 5000,
    );

    await repository.updateTransfer(
      groupId: groupId,
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      adminFee: 7500,
    );

    expect(await rows(), hasLength(3));
    expect(await repository.adminFeeForGroup(groupId), 7500);
    expect(await balanceOf(sourceId), -107500);
  });

  test('mengosongkan biaya admin menghapus potongannya', () async {
    final groupId = await repository.createTransfer(
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      adminFee: 5000,
    );

    await repository.updateTransfer(
      groupId: groupId,
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      adminFee: 0,
    );

    expect(await repository.adminFeeForGroup(groupId), 0);
    expect(await balanceOf(sourceId), -100000);
    // Baris biaya tidak dihapus permanen; hanya ditandai terhapus.
    expect(await rows(), hasLength(3));
  });

  test('adminFee null tidak mengubah biaya yang sudah tersimpan', () async {
    final groupId = await repository.createTransfer(
      amount: 100000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
      adminFee: 5000,
    );

    await repository.updateTransfer(
      groupId: groupId,
      amount: 120000,
      fromWalletId: sourceId,
      toWalletId: destinationId,
      date: '2026-11-06',
    );

    expect(await repository.adminFeeForGroup(groupId), 5000);
    expect(await balanceOf(sourceId), -125000);
  });

  test(
    'menghapus transfer ikut menghapus biaya admin, urungkan memulihkan',
    () async {
      final groupId = await repository.createTransfer(
        amount: 100000,
        fromWalletId: sourceId,
        toWalletId: destinationId,
        date: '2026-11-06',
        adminFee: 5000,
      );
      final outgoing = (await rows()).firstWhere(
        (row) => row.kind == TxKind.transferOut.storageValue,
      );

      await repository.softDelete(outgoing.id);
      expect(await balanceOf(sourceId), 0);
      expect(await balanceOf(destinationId), 0);
      expect(await repository.adminFeeForGroup(groupId), 0);

      await repository.restore(outgoing.id);
      expect(await balanceOf(sourceId), -105000);
      expect(await balanceOf(destinationId), 100000);
      expect(await repository.adminFeeForGroup(groupId), 5000);
    },
  );

  test('biaya admin tidak boleh melebihi jumlah transfer', () {
    expect(
      TransactionRules.validateAdminFee(adminFee: 100001, amount: 100000),
      TransactionRules.adminFeeTooLarge,
    );
    expect(
      TransactionRules.validateAdminFee(adminFee: 100000, amount: 100000),
      isNull,
    );
    expect(
      TransactionRules.validateAdminFee(adminFee: 0, amount: 100000),
      isNull,
    );
  });
}
