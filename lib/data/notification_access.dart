import 'package:flutter/services.dart';

/// Status izin pembacaan notifikasi di Android.
class NotificationAccessStatus {
  const NotificationAccessStatus({
    required this.granted,
    required this.connected,
  });

  /// Pengguna sudah mengaktifkan Spendly di pengaturan akses notifikasi.
  final bool granted;

  /// Listener sedang terhubung ke sistem, bukan hanya diizinkan.
  final bool connected;

  static const unknown = NotificationAccessStatus(
    granted: false,
    connected: false,
  );

  bool get ready => granted && connected;
}

/// Membuka dan memeriksa pengaturan akses notifikasi Android.
///
/// Pemeriksaan dilakukan lewat MethodChannel karena izin ini bukan izin runtime
/// biasa: pengguna harus menyalakannya sendiri di layar Setting Android.
class NotificationAccess {
  const NotificationAccess();

  static const MethodChannel _channel = MethodChannel(
    'spendly/notification_access',
  );

  Future<NotificationAccessStatus> status() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('status');
      return NotificationAccessStatus(
        granted: result?['granted'] == true,
        connected: result?['connected'] == true,
      );
    } on MissingPluginException {
      return NotificationAccessStatus.unknown;
    } on PlatformException {
      return NotificationAccessStatus.unknown;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // Bukan Android.
    } on PlatformException {
      // Layar pengaturan tidak tersedia di perangkat ini.
    }
  }

  /// Membuka daftar aplikasi yang dikecualikan dari optimasi baterai.
  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } on MissingPluginException {
      // Bukan Android.
    } on PlatformException {
      // Layar pengaturan tidak tersedia di perangkat ini.
    }
  }

  /// Membuka halaman Info Aplikasi, tempat sebagian ROM menyembunyikan
  /// "Mulai otomatis" / "Autostart".
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } on MissingPluginException {
      // Bukan Android.
    } on PlatformException {
      // Layar pengaturan tidak tersedia di perangkat ini.
    }
  }
}
