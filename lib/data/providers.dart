import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/money.dart';
import '../domain/app_preferences.dart';
import '../domain/daily_totals.dart';
import '../domain/notification_draft.dart';
import '../domain/report_breakdown.dart';
import '../domain/report_range.dart';
import '../domain/report_rules.dart';
import '../domain/saved_report.dart';
import '../domain/transaction_entry.dart';
import '../domain/tx_kind.dart';
import '../domain/tx_suggestion.dart';
import '../domain/wallet_balance.dart';
import '../domain/theme_choice.dart';
import 'db/app_database.dart';
import 'notification_access.dart';
import 'notification_capture_channel.dart';
import 'notification_repository.dart';
import 'report_repository.dart';
import 'report_settings_repository.dart';
import 'settings_repository.dart';
import 'transaction_repository.dart';
import 'wallet_repository.dart';

/// Diisi dari `main()` lewat `overrideWithValue`, supaya basis data yang sudah
/// dibuka dipakai bersama dan tidak dibuka berkali-kali.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'appDatabaseProvider harus di-override di main()',
  ),
);

/// Gerbang tunggal ke seluruh penulisan rekening.
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(appDatabaseProvider)),
);

/// Gerbang tunggal ke seluruh penulisan transaksi.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(appDatabaseProvider)),
);

/// Gerbang tunggal ke inbox notifikasi dan pemetaan rekening.
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

/// Draft notifikasi yang menunggu keputusan pengguna.
///
/// Provider ini bergantung pada jumlah pending. Ketika mesin latar menulis
/// draft baru, angka badge berubah dan query daftar dibuat ulang. `autoDispose`
/// juga memastikan Inbox selalu membaca ulang saat dibuka.
final pendingNotificationDraftsProvider =
    StreamProvider.autoDispose<List<NotificationDraft>>((ref) {
      ref.watch(
        pendingNotificationCountProvider.select((value) => value.value),
      );
      return ref.watch(notificationRepositoryProvider).watchPending();
    });

/// Jumlah draft pending, untuk badge lonceng.
///
/// Drift tidak memberi tahu stream di mesin utama ketika isolate latar menulis
/// ke basis data yang sama. Karena itu badge membaca ulang jumlahnya secara
/// berkala. Intervalnya 15 detik, bukan 3 detik: query ini berjalan selama
/// aplikasi terbuka, dan inbox tetap bisa disegarkan sendiri lewat tarik-bawah
/// atau tombol muat ulang. Saat aplikasi dilanjutkan, `AppShell` juga memaksa
/// pembacaan ulang.
final pendingNotificationCountProvider = StreamProvider<int>((ref) async* {
  final repository = ref.watch(notificationRepositoryProvider);
  var last = 0;
  while (true) {
    try {
      last = await repository.countPending();
    } catch (_) {
      // Biarkan angka terakhir tampil; percobaan berikutnya akan menyusul.
    }
    yield last;
    await Future<void>.delayed(const Duration(seconds: 15));
  }
});

/// Pemetaan paket aplikasi ke rekening.
final notificationMappingsProvider =
    StreamProvider<List<AccountNotificationMapping>>(
      (ref) => ref.watch(notificationRepositoryProvider).watchMappings(),
    );

/// Status izin akses notifikasi Android.
final notificationAccessProvider = FutureProvider<NotificationAccessStatus>(
  (ref) => const NotificationAccess().status(),
);

/// Penyedot antrean notifikasi native untuk aplikasi utama.
final notificationInboxSyncProvider = Provider<NotificationInboxSync>(
  (ref) => NotificationInboxSync(ref.watch(notificationRepositoryProvider)),
);

/// Rekening beserta saldonya. Ikut berubah begitu ada transaksi disimpan, karena
/// drift memancarkan ulang hasil query yang membacanya.
final walletBalancesProvider = StreamProvider<List<WalletBalance>>(
  (ref) => ref.watch(walletRepositoryProvider).watchBalances(),
);

/// Baris transaksi satu hari, urut menurut jam.
///
/// Kuncinya tanggal `YYYY-MM-DD`, bukan `DateTime`: teks itulah yang dipakai
/// sebagai kunci penyimpanan, sehingga tidak ada pergeseran zona waktu yang
/// bisa membuat hari yang sama terbaca sebagai dua hari berbeda.
final dayTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, String>(
      (ref, date) => ref.watch(transactionRepositoryProvider).watchDay(date),
    );

/// Kunci halaman **Riwayat**: kata pencarian dan berapa baris yang diminta.
///
/// Dibatasi supaya membuka riwayat tidak memuat seluruh transaksi sejak tahun
/// pertama ke memori. Pencarian tetap dijalankan di SQL.
class HistoryQuery {
  const HistoryQuery({this.search = '', this.limit = 200});

  final String search;
  final int limit;

  HistoryQuery withLimit(int value) =>
      HistoryQuery(search: search, limit: value);

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery && other.search == search && other.limit == limit;

  @override
  int get hashCode => Object.hash(search, limit);
}

/// Halaman pertama Riwayat, terbaru lebih dulu.
final historyTransactionsProvider =
    StreamProvider.family<List<TransactionEntry>, HistoryQuery>(
      (ref, query) => ref
          .watch(transactionRepositoryProvider)
          .watchAll(limit: query.limit, search: query.search),
    );

/// Kunci daftar saran: jenis data (`title`/`category`) dan jenis transaksi.
class SuggestionQuery {
  const SuggestionQuery({required this.type, required this.kind});

  final String type;
  final TxKind kind;

  @override
  bool operator ==(Object other) =>
      other is SuggestionQuery && other.type == type && other.kind == kind;

  @override
  int get hashCode => Object.hash(type, kind);
}

/// Saran judul atau kategori untuk satu jenis transaksi. SPEC C-3.
final suggestionsProvider =
    StreamProvider.family<List<TxSuggestion>, SuggestionQuery>(
      (ref, query) => ref
          .watch(transactionRepositoryProvider)
          .watchSuggestions(type: query.type, kind: query.kind),
    );

// ------------------------------------------------------------------ Rekap

/// Gerbang tunggal ke seluruh pembacaan rekap. SPEC §5.8.
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(appDatabaseProvider)),
);

/// Pembacaan dan penyimpanan Konfigurasi Rekap. SPEC L-7.
final reportSettingsRepositoryProvider = Provider<ReportSettingsRepository>(
  (ref) => ReportSettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Setelan rekap aktif. Seluruh layar rekap ikut berubah begitu disimpan.
final reportConfigProvider = StreamProvider<ReportConfig>(
  (ref) => ref.watch(reportSettingsRepositoryProvider).watch(),
);

/// Total mutasi per hari. Sumber tunggal seluruh angka rekap.
final dailyTotalsProvider = StreamProvider<List<DailyTotals>>(
  (ref) => ref.watch(reportRepositoryProvider).watchDailyTotals(),
);

/// Rekap kustom tersimpan. SPEC L-8.
final customReportsProvider = StreamProvider<List<SavedReport>>(
  (ref) => ref.watch(reportRepositoryProvider).watchCustomReports(),
);

/// Baris pemasukan dan pengeluaran satu rentang, untuk rincian per kategori
/// dan per judul. SPEC L-3.
final reportLinesProvider =
    StreamProvider.family<List<ReportLine>, ReportRange>(
      (ref, range) => ref.watch(reportRepositoryProvider).watchLines(range),
    );

// ------------------------------------------------------------------ Setelan

/// Gerbang tunggal ke setelan aplikasi. SPEC §5.12.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Setelan aplikasi: dibaca sekali saat mulai, lalu setiap perubahan ditulis
/// kembali ke tabel `app_settings` oleh [SettingsController].
///
/// Memakai `AsyncNotifier`, bukan `StateNotifier`: Riverpod 3 menghapus
/// `StateNotifier`, dan muat awal memang tak sinkron.
class SettingsController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() =>
      ref.watch(settingsRepositoryProvider).load();

  /// Mengubah setelan dan menyimpan bagian yang benar-benar berubah.
  ///
  /// Nilai di memori diperbarui lebih dulu supaya layar seketika menyala;
  /// penulisan ke basis data menyusul di belakangnya.
  ///
  /// Dibuat sebagai setter per setelan alih-alih satu metode ubah-umum: kelas
  /// dasar `AsyncNotifier` sudah memakai nama `update`.
  Future<void> _write(AppPreferences next) async {
    final current = state.value ?? const AppPreferences();
    if (next == current) return; // tak ada yang berubah, tidak usah ditulis.

    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next.diff(current));
  }

  /// SPEC ST-4: memilih warna tema.
  Future<void> setTheme(AppTheme theme) =>
      _write((state.value ?? const AppPreferences()).copyWith(theme: theme));

  /// SPEC ST-3: sakelar "Tampilkan Angka Desimal".
  Future<void> setShowDecimals(bool value) => _write(
    (state.value ?? const AppPreferences()).copyWith(showDecimals: value),
  );

  /// SPEC ST-5: memilih bahasa.
  Future<void> setLanguage(AppLanguage language) => _write(
    (state.value ?? const AppPreferences()).copyWith(language: language),
  );

  /// SPEC ST-6: menyalakan atau mematikan pengingat.
  Future<void> setReminderEnabled(bool value) => _write(
    (state.value ?? const AppPreferences()).copyWith(reminderEnabled: value),
  );

  /// SPEC ST-6: jam pengingat "Kapan", format `HH:MM`.
  Future<void> setReminderTime(String time) => _write(
    (state.value ?? const AppPreferences()).copyWith(reminderTime: time),
  );
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppPreferences>(
      SettingsController.new,
    );

/// Format uang yang mengikuti setelan "Tampilkan Angka Desimal". SPEC ST-3.
///
/// Saat setelan belum selesai dimuat, memakai bawaan: desimal menyala.
final moneyFormatProvider = Provider<MoneyFormat>((ref) {
  final prefs = ref.watch(settingsProvider).value;
  return MoneyFormat(showDecimals: prefs?.showDecimals ?? true);
});
