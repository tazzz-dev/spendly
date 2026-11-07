import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../../data/transaction_repository.dart';
import '../../data/wallet_repository.dart';
import '../../domain/movement.dart';
import '../../domain/wallet_type.dart';
import 'sepran_json_import.dart';

/// Rekening baru yang akan dibuat saat impor JSON.
class SepranNewWallet {
  const SepranNewWallet({
    required this.name,
    required this.openingBalance,
    required this.type,
    required this.iconKey,
    required this.color,
  });

  final String name;

  /// Saldo awal hasil hitung: target dikurangi seluruh mutasi rekening.
  final int openingBalance;

  final WalletType type;
  final String iconKey;
  final int color;
}

/// Hasil satu kali impor JSON.
class SepranJsonImportResult {
  const SepranJsonImportResult({
    required this.transactionCount,
    required this.newWalletCount,
  });

  /// Jumlah baris berkas yang diimpor. Satu pindah saldo dihitung satu, meski
  /// di basis data ia menjadi dua baris.
  final int transactionCount;

  final int newWalletCount;
}

/// Menjalankan impor JSON: membuat rekening yang diminta, lalu menulis semua
/// transaksi.
///
/// Seluruh pekerjaan berada dalam **satu transaksi basis data**. Bila salah
/// satu baris gagal, rekening yang baru dibuat ikut dibatalkan, sehingga tidak
/// ada rekening kosong yang tertinggal.
///
/// Impor memakai [TransactionRepository.createMany] yang sudah ada, jadi
/// penghitung saran judul/kategori tetap tidak naik (SPEC X-11).
class SepranJsonImporter {
  SepranJsonImporter({
    required this.db,
    required this.wallets,
    required this.transactions,
  });

  final AppDatabase db;
  final WalletRepository wallets;
  final TransactionRepository transactions;

  static const Uuid _uuid = Uuid();

  /// [existingWalletIds] memetakan nama rekening di berkas ke id rekening lama.
  /// Nama yang tidak ada di sana harus ada di [newWallets].
  Future<SepranJsonImportResult> import({
    required SepranJsonPreview preview,
    Map<String, String> existingWalletIds = const {},
    List<SepranNewWallet> newWallets = const [],
  }) async {
    final mapping = <String, String>{...existingWalletIds};
    final newByName = <String, SepranNewWallet>{};

    for (final wallet in newWallets) {
      if (mapping.containsKey(wallet.name) ||
          newByName.containsKey(wallet.name)) {
        throw ArgumentError(
          'Rekening "${wallet.name}" diminta dibuat dua kali atau sudah '
          'dipetakan ke rekening lama.',
        );
      }
      newByName[wallet.name] = wallet;
    }

    for (final name in preview.walletNames) {
      if (!mapping.containsKey(name) && !newByName.containsKey(name)) {
        throw ArgumentError('Rekening "$name" belum dipilih tujuan impornya.');
      }
    }

    var created = 0;

    await db.transaction(() async {
      for (final wallet in newByName.values) {
        mapping[wallet.name] = await wallets.create(
          name: wallet.name,
          type: wallet.type,
          openingBalance: wallet.openingBalance,
          iconKey: wallet.iconKey,
          color: wallet.color,
        );
        created++;
      }

      final drafts = <TxDraft>[];

      for (final row in preview.rows) {
        final walletId = mapping[row.wallet];
        if (walletId == null) {
          throw StateError('Rekening "${row.wallet}" belum dipetakan.');
        }

        switch (row.kind) {
          case SepranJsonKind.income:
            drafts.add(
              Movement.income(
                amount: row.amount,
                walletId: walletId,
                title: row.title,
                category: row.category,
                date: row.date,
                time: row.time,
              ),
            );
            break;
          case SepranJsonKind.expense:
            drafts.add(
              Movement.expense(
                amount: row.amount,
                walletId: walletId,
                title: row.title,
                category: row.category,
                date: row.date,
                time: row.time,
              ),
            );
            break;
          case SepranJsonKind.transfer:
            final counterName = row.counterWallet;
            final counterId = counterName == null ? null : mapping[counterName];
            if (counterId == null) {
              throw StateError(
                'Rekening tujuan "$counterName" belum dipetakan.',
              );
            }

            final transfer = Movement.transfer(
              amount: row.amount,
              fromWalletId: walletId,
              toWalletId: counterId,
              // Satu grup unik per transfer, supaya kedua barisnya selalu
              // dihapus dan diubah bersama (SPEC S-7).
              groupId: _uuid.v4(),
              date: row.date,
              time: row.time,
            );
            // Kedua sisi wajib masuk. Tanpa baris masuk, uang tampak hilang
            // dari rekening tujuan.
            drafts.addAll(transfer.rows);
            break;
        }
      }

      await transactions.createMany(drafts);
    });

    return SepranJsonImportResult(
      transactionCount: preview.rows.length,
      newWalletCount: created,
    );
  }
}
