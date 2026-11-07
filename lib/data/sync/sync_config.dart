import 'package:flutter/foundation.dart';

/// Konfigurasi sinkronisasi opsional.
///
/// Aplikasi tetap berjalan 100% lokal tanpa konfigurasi apa pun. Kredensial
/// Supabase **tidak** ditulis di dalam kode; keduanya diberikan saat membangun
/// aplikasi:
///
/// ```text
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// Kunci yang dipakai adalah kunci *anon/publishable*, bukan service role.
/// Akses data dibatasi Row Level Security di sisi Supabase.
class SyncConfig {
  const SyncConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Skema tautan balik OAuth di Android/iOS. Harus sama dengan yang terdaftar
  /// di Supabase Dashboard › Authentication › URL Configuration.
  static const String callbackScheme = 'io.supabase.spendly';
  static const String callbackHostPath = 'login-callback';

  /// `true` bila build ini membawa kredensial Supabase.
  ///
  /// Bila `false`, halaman Sinkronisasi tetap bisa dibuka, tetapi hanya
  /// menjelaskan bahwa fitur ini tidak aktif di build tersebut. Tidak ada
  /// percobaan jaringan dan tidak ada plugin yang dimuat.
  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Alamat kembali setelah login Google.
  ///
  /// Di web, alamatnya adalah asal halaman yang sedang dibuka. Asal itu harus
  /// didaftarkan sebagai Redirect URL di Supabase (boleh memakai wildcard untuk
  /// port pengembangan).
  static String get redirectUrl =>
      kIsWeb ? Uri.base.origin : '$callbackScheme://$callbackHostPath';

  /// Catatan singkat yang ditampilkan di layar bila build belum dikonfigurasi.
  static const String missingConfigHint =
      'Sinkronisasi belum diaktifkan pada build ini. Jalankan aplikasi dengan '
      'SUPABASE_URL dan SUPABASE_ANON_KEY, lalu lihat docs/SINKRONISASI.md.';
}

/// Kegagalan yang bisa dijelaskan kepada pengguna, bukan kesalahan pemrograman.
class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Akun yang sedang masuk berbeda dengan akun yang terakhir dipakai untuk
/// menyinkronkan basis data lokal ini.
///
/// Data lokal sengaja tidak dihapus diam-diam. Pengguna harus memilih: memakai
/// akun baru (data lokal ikut diunggah) atau keluar lagi.
class SyncAccountMismatch extends SyncException {
  const SyncAccountMismatch(this.previousUserId)
    : super(
        'Basis data ini terakhir disinkronkan dengan akun lain. Pilih '
        '"Pakai akun ini" untuk menggabungkan data lokal ke akun yang sekarang, '
        'atau keluar dan masuk dengan akun sebelumnya.',
      );

  final String previousUserId;
}
