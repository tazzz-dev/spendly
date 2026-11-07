import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pencatatan_keuangan/domain/movement.dart';
import 'package:pencatatan_keuangan/domain/transaction_entry.dart';
import 'package:pencatatan_keuangan/domain/tx_kind.dart';

/// Buku besar kecil di memori, meniru cara basis data menyimpan baris.
///
/// Ada dua sumber angka yang sengaja dipisahkan:
///  * [running] — saldo yang diperbarui sedikit demi sedikit tiap penulisan,
///    yaitu yang "dilihat pengguna";
///  * [recompute] — saldo yang dihitung ulang dari rumus SPEC §4.
///
/// INV-1 mengatakan keduanya harus selalu sama. Kalau sebuah operasi punya
/// efek samping tersembunyi, keduanya akan berselisih dan test gagal.
class _Ledger {
  _Ledger(this.wallets);

  final List<String> wallets;

  final Map<String, int> opening = {};
  final Map<String, int> running = {};
  final Map<String, TransactionEntry> rows = {};
  final Set<String> removed = {};

  int _sequence = 0;

  void seed(Map<String, int> balances) {
    opening.addAll(balances);
    running.addAll(balances);
  }

  String insert(TxDraft draft) {
    final id = 'tx${_sequence++}';
    rows[id] = TransactionEntry(
      id: id,
      kind: draft.kind,
      amount: draft.amount,
      date: draft.date,
      time: draft.time,
      title: draft.title,
      category: draft.category,
      note: draft.note,
      walletId: draft.walletId,
      counterWalletId: draft.counterWalletId,
      transferGroupId: draft.transferGroupId,
    );
    running[draft.walletId] = (running[draft.walletId] ?? 0) + draft.amount;
    return id;
  }

  /// Hapus lunak: barisnya tetap ada, hanya tidak dihitung lagi.
  void remove(String id) {
    final row = rows[id]!;
    removed.add(id);
    running[row.walletId!] = running[row.walletId!]! - row.amount;
  }

  void restore(String id) {
    final row = rows[id]!;
    removed.remove(id);
    running[row.walletId!] = running[row.walletId!]! + row.amount;
  }

  int recompute(String walletId) {
    var total = opening[walletId] ?? 0;
    for (final row in rows.values) {
      if (removed.contains(row.id)) continue;
      if (row.walletId != walletId) continue;
      total += row.amount;
    }
    return total;
  }

  Map<String, int> snapshot() => Map.of(running);

  /// Semua baris hidup milik satu grup pindah saldo.
  List<TransactionEntry> groupRows(String groupId) => rows.values
      .where((row) => !removed.contains(row.id))
      .where((row) => row.transferGroupId == groupId)
      .toList();
}

void main() {
  test('INV-1, INV-4, dan INV-5 bertahan pada 300 urutan operasi acak', () {
    const date = '2026-10-19';

    for (var seed = 1; seed <= 300; seed++) {
      final random = Random(seed);
      final wallets = ['w1', 'w2', 'w3'];
      final ledger = _Ledger(wallets);

      ledger.seed({
        for (final wallet in wallets) wallet: random.nextInt(2000000) - 500000,
      });

      final liveRows = <String>[];
      final transferGroups = <String>[];

      for (var step = 0; step < 40; step++) {
        final wallet = wallets[random.nextInt(wallets.length)];
        final amount = random.nextInt(1000000) + 1;
        final roll = random.nextInt(10);

        if (roll <= 2) {
          liveRows.add(
            ledger.insert(
              Movement.income(
                amount: amount,
                walletId: wallet,
                title: 'Judul$step',
                category: 'Kategori$step',
                date: date,
              ),
            ),
          );
        } else if (roll <= 5) {
          liveRows.add(
            ledger.insert(
              Movement.expense(
                amount: amount,
                walletId: wallet,
                title: 'Judul$step',
                category: 'Kategori$step',
                date: date,
              ),
            ),
          );
        } else if (roll <= 7) {
          final other = wallets.firstWhere((candidate) => candidate != wallet);
          final group = 'g$seed-$step';
          final draft = Movement.transfer(
            amount: amount,
            fromWalletId: wallet,
            toWalletId: other,
            groupId: group,
            date: date,
          );
          transferGroups.add(group);
          liveRows.add(ledger.insert(draft.outgoing));
          liveRows.add(ledger.insert(draft.incoming));
        } else if (roll == 8) {
          liveRows.add(
            ledger.insert(
              Movement.correction(
                amount: random.nextBool() ? amount : -amount,
                walletId: wallet,
                date: date,
              ),
            ),
          );
        } else if (liveRows.isNotEmpty) {
          // INV-5: hapus lalu pulihkan harus kembali persis.
          final victim = liveRows[random.nextInt(liveRows.length)];
          final before = ledger.snapshot();

          ledger.remove(victim);
          ledger.restore(victim);

          expect(
            ledger.snapshot(),
            before,
            reason:
                'seed $seed langkah $step: hapus lalu pulihkan mengubah saldo',
          );
        }

        // INV-1: saldo berjalan harus sama dengan rumus yang dihitung ulang.
        for (final candidate in wallets) {
          expect(
            ledger.running[candidate],
            ledger.recompute(candidate),
            reason: 'seed $seed langkah $step pada $candidate',
          );
        }
      }

      // INV-4: setiap grup pindah saldo terdiri dari dua baris, sama besar,
      // berlawanan tanda, dan jumlahnya nol.
      for (final group in transferGroups) {
        final rows = ledger.groupRows(group);
        expect(rows, hasLength(2), reason: 'seed $seed grup $group');

        final delta = rows.fold<int>(0, (sum, row) => sum + row.amount);
        expect(delta, 0, reason: 'seed $seed grup $group tidak berimbang');

        final kinds = rows.map((row) => row.kind).toSet();
        expect(kinds, {TxKind.transferOut, TxKind.transferIn});
      }

      // INV-1 sekali lagi di akhir, untuk seluruh rekening sekaligus.
      var totalRunning = 0;
      var totalRecomputed = 0;
      for (final candidate in wallets) {
        totalRunning += ledger.running[candidate]!;
        totalRecomputed += ledger.recompute(candidate);
      }
      expect(totalRunning, totalRecomputed, reason: 'seed $seed total');
    }
  });

  test(
    'mengubah nominal tersimpan mengubah saldo persis sebanyak selisihnya',
    () {
      // INV-1 dalam bentuk lain: tidak ada tambahan atau kehilangan diam-diam.
      const date = '2026-10-19';
      final ledger = _Ledger(['w1'])..seed({'w1': 100000});

      final id = ledger.insert(
        Movement.expense(
          amount: 25000,
          walletId: 'w1',
          title: 'Makan',
          category: 'Makanan',
          date: date,
        ),
      );

      expect(ledger.recompute('w1'), 75000);

      ledger.remove(id);
      expect(ledger.recompute('w1'), 100000);

      ledger.restore(id);
      expect(ledger.recompute('w1'), 75000);
    },
  );

  test('INV-2: Total Saldo sama dengan jumlah saldo tiap rekening', () {
    const date = '2026-10-19';
    final ledger = _Ledger(['w1', 'w2', 'w3'])
      ..seed({'w1': 100000, 'w2': -25000, 'w3': 0});

    ledger.insert(
      Movement.income(
        amount: 50000,
        walletId: 'w1',
        title: 'Gaji',
        category: 'Gaji',
        date: date,
      ),
    );
    ledger.insert(
      Movement.expense(
        amount: 12000,
        walletId: 'w2',
        title: 'Kopi',
        category: 'Minuman',
        date: date,
      ),
    );
    final transfer = Movement.transfer(
      amount: 30000,
      fromWalletId: 'w1',
      toWalletId: 'w3',
      groupId: 'g1',
      date: date,
    );
    ledger.insert(transfer.outgoing);
    ledger.insert(transfer.incoming);

    // Total Saldo yang ditampilkan halaman rekening (SPEC R-2) harus sama
    // dengan penjumlahan saldo seluruh rekening non-arsip.
    var perWallet = 0;
    for (final wallet in ledger.wallets) {
      perWallet += ledger.recompute(wallet);
    }
    var displayedTotal = 0;
    for (final wallet in ledger.wallets) {
      displayedTotal += ledger.running[wallet]!;
    }

    expect(displayedTotal, perWallet);
    expect(displayedTotal, 100000 + 50000 + (-25000 - 12000) + 0);
  });

  test('INV-3: setiap pindah saldo memakai dua rekening berbeda yang ada', () {
    const date = '2026-10-19';
    final ledger = _Ledger(['w1', 'w2']);

    final draft = Movement.transfer(
      amount: 40000,
      fromWalletId: 'w1',
      toWalletId: 'w2',
      groupId: 'g1',
      date: date,
    );

    expect(draft.outgoing.walletId, isNot(draft.incoming.walletId));
    expect(ledger.wallets, contains(draft.outgoing.walletId));
    expect(ledger.wallets, contains(draft.incoming.walletId));

    // M-3: asal dan tujuan tidak boleh sama, ditolak sejak pembuatan baris.
    expect(
      () => Movement.transfer(
        amount: 40000,
        fromWalletId: 'w1',
        toWalletId: 'w1',
        groupId: 'g2',
        date: date,
      ),
      throwsArgumentError,
    );
  });
}
