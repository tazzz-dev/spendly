import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers.dart';
import 'supabase_bootstrap.dart';
import 'sync_config.dart';
import 'sync_service.dart';

/// Pengguna Google yang sedang masuk, atau `null` bila belum/tidak tersedia.
///
/// Provider ini **tidak** dipakai di layar lain. Membacanya berarti memulai
/// Supabase, jadi hanya layar Sinkronisasi yang boleh memantaunya. Aplikasi
/// yang dipakai tanpa login tidak pernah menyentuh jalur ini.
final authSessionProvider = StreamProvider<User?>((ref) async* {
  if (!SyncConfig.isConfigured) {
    yield null;
    return;
  }

  final client = await SupabaseBootstrap.ensureInitialized();
  yield client.auth.currentUser;
  yield* client.auth.onAuthStateChange.map((state) => state.session?.user);
});

/// Layanan sinkronisasi, dibuat setelah Supabase siap.
final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final client = await SupabaseBootstrap.ensureInitialized();
  return SyncService(ref.watch(appDatabaseProvider), client);
});

/// Waktu sinkronisasi terakhir yang berhasil.
final lastSyncProvider = FutureProvider<DateTime?>((ref) async {
  final service = await ref.watch(syncServiceProvider.future);
  return service.lastSyncedAt();
});

/// Tindakan akun dan sinkronisasi yang dipanggil dari layar.
///
/// Sengaja bukan `Notifier`: tidak ada state yang perlu hidup lebih lama dari
/// layar, dan status sibuk/pesan ditangani layar itu sendiri.
class SyncActions {
  SyncActions(this._ref);

  final Ref _ref;

  /// Membuka halaman login Google. Sesi muncul lewat [authSessionProvider].
  Future<void> signInWithGoogle() async {
    final client = await SupabaseBootstrap.ensureInitialized();
    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SyncConfig.redirectUrl,
      // Di Android/iOS, Google menolak login di dalam WebView; buka peramban
      // sungguhan lalu kembali lewat tautan `io.supabase.spendly://`.
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const SyncException('Tidak dapat membuka halaman login Google.');
    }
  }

  Future<void> signOut() async {
    final client = await SupabaseBootstrap.ensureInitialized();
    await client.auth.signOut();
  }

  /// Menarik dan mengirim perubahan. Data lokal tetap utuh.
  Future<SyncOutcome> syncNow() async {
    final service = await _ref.read(syncServiceProvider.future);
    final outcome = await service.syncNow();
    _ref.invalidate(lastSyncProvider);
    return outcome;
  }

  /// Menggabungkan data lokal ke akun yang sekarang, lalu menyinkronkan.
  ///
  /// Hanya dipanggil setelah pengguna menyetujui [SyncAccountMismatch].
  Future<SyncOutcome> adoptAccountAndSync() async {
    final service = await _ref.read(syncServiceProvider.future);
    await service.adoptCurrentAccount();
    final outcome = await service.syncNow();
    _ref.invalidate(lastSyncProvider);
    return outcome;
  }
}

final syncActionsProvider = Provider<SyncActions>(SyncActions.new);
