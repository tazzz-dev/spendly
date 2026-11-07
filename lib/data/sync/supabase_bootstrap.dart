import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_config.dart';

/// Menyalakan Supabase hanya ketika fitur sinkronisasi benar-benar dipakai.
///
/// `main()` tidak memanggil ini. Halaman Sinkronisasi (atau tautan balik OAuth
/// di web) yang memicunya. Dengan begitu, pengguna yang tidak pernah login
/// tidak membayar biaya memuat plugin autentikasi saat cold start.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static SupabaseClient? _client;
  static Future<SupabaseClient>? _pending;

  /// `true` setelah [ensureInitialized] selesai.
  static bool get isReady => _client != null;

  /// Mengembalikan klien Supabase, atau melempar [SyncException] bila build ini
  /// tidak membawa kredensial.
  static Future<SupabaseClient> ensureInitialized() {
    if (!SyncConfig.isConfigured) {
      throw const SyncException(SyncConfig.missingConfigHint);
    }

    final ready = _client;
    if (ready != null) return Future.value(ready);

    return _pending ??= _initialize();
  }

  static Future<SupabaseClient> _initialize() async {
    try {
      final instance = await Supabase.initialize(
        url: SyncConfig.supabaseUrl,
        publishableKey: SyncConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          // PKCE: kode OAuth ditukar di perangkat, tanpa menyimpan token di
          // URL yang bisa terbaca riwayat peramban.
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = instance.client;
      return _client!;
    } on SyncException {
      rethrow;
    } catch (error) {
      _pending = null;
      throw SyncException('Gagal menyiapkan sinkronisasi: $error');
    }
  }
}
