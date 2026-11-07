import 'package:flutter/services.dart';

import '../domain/captured_notification.dart';
import 'notification_repository.dart';

/// Jembatan ke antrean notifikasi di sisi Android.
///
/// Antrean native sengaja tetap ada sampai Dart menyatakan event sudah
/// diproses. Dengan begitu notifikasi tidak hilang ketika mesin Flutter latar
/// gagal dimulai atau proses aplikasi dimatikan Android.
class NotificationCaptureChannel {
  const NotificationCaptureChannel();

  static const MethodChannel _channel = MethodChannel(
    'spendly/notification_capture',
  );

  Future<List<CapturedNotification>> drain() async {
    final result = await _channel.invokeMethod<List<Object?>>('drain');
    if (result == null || result.isEmpty) return const [];

    final events = <CapturedNotification>[];
    for (final item in result) {
      if (item is Map) {
        events.add(CapturedNotification.fromMap(item.cast<Object?, Object?>()));
      }
    }
    return events;
  }

  Future<void> ack(Iterable<String> ids) async {
    final values = ids.where((id) => id.isNotEmpty).toList(growable: false);
    if (values.isEmpty) return;
    await _channel.invokeMethod<void>('ack', values);
  }
}

/// Menyedot antrean native ke Drift.
///
/// Dipakai dua tempat: mesin Flutter latar yang dijalankan oleh listener
/// Android, dan aplikasi utama saat dibuka/dilanjutkan. Keduanya idempoten
/// karena repository memakai `source_key` unik.
class NotificationInboxSync {
  NotificationInboxSync(
    this._repository, {
    this.channel = const NotificationCaptureChannel(),
  });

  final NotificationRepository _repository;
  final NotificationCaptureChannel channel;
  bool _running = false;

  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      final events = await channel.drain();
      if (events.isEmpty) return;
      final acknowledged = await _repository.ingestMany(events);
      await channel.ack(acknowledged);
    } on MissingPluginException {
      // Test widget atau platform selain Android: tidak ada antrean native.
    } on PlatformException {
      // Biarkan event di antrean; percobaan berikutnya akan mengambilnya.
    } finally {
      _running = false;
    }
  }
}
