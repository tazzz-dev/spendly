import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/debt_repository.dart';
import '../../data/providers.dart';
import '../../domain/debt_entry.dart';
import '../../domain/debt_record.dart';

/// Provider modul Hutang.
///
/// Sengaja diletakkan di sini, bukan di `lib/data/providers.dart`, karena
/// berkas itu wilayah bersama yang dibekukan (RENCANA-BUILD §3).

/// Gerbang tunggal ke seluruh penulisan dan pembacaan catatan hutang.
final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DebtRepository(ref.watch(appDatabaseProvider)),
);

/// Seluruh catatan hutang beserta `net`-nya, terbaru lebih dulu.
final debtRecordsProvider = StreamProvider<List<DebtRecord>>(
  (ref) => ref.watch(debtRepositoryProvider).watchRecords(),
);

/// Satu catatan, untuk halaman detail.
final debtRecordProvider = StreamProvider.family<DebtRecord?, String>(
  (ref, id) => ref.watch(debtRepositoryProvider).watchRecord(id),
);

/// Entri satu catatan, untuk halaman detail.
final debtEntriesProvider = StreamProvider.family<List<DebtEntry>, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).watchEntries(debtId),
);

/// Nama yang pernah dipakai, untuk field Nama yang boleh dipilih dari yang
/// sudah ada (SPEC H-12).
final debtPartyNamesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(debtRepositoryProvider).partyNames(),
);
