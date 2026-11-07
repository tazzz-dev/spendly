import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/app_preferences.dart';

/// Menyelaraskan pengingat harian di sistem dengan setelan pengguna. SPEC ST-6.
///
/// Dipisah sebagai antarmuka supaya lapisan layar tidak menempel langsung ke
/// plugin notifikasi, dan supaya perilakunya bisa diganti di test tanpa
/// menyentuh saluran platform.
abstract class ReminderScheduler {
  /// Menjadwalkan ulang pengingat sesuai [enabled] dan [clock].
  ///
  /// Mengembalikan `false` bila izin notifikasi ditolak, sehingga pemanggil
  /// bisa memberi tahu pengguna. Ketika [enabled] bernilai salah, jadwal lama
  /// dibatalkan dan hasilnya selalu `true`.
  Future<bool> sync({
    required bool enabled,
    required ReminderClock clock,
    required String title,
    required String body,
  });
}

/// Pelaksana [ReminderScheduler] di atas `flutter_local_notifications`.
///
/// Zona waktu dipatok ke `Asia/Jakarta` (WIB): SPEC G-4 mencatat Indonesia
/// tidak memakai DST dan aplikasi ini berbahasa Indonesia lebih dulu, jadi
/// satu zona tetap lebih jujur daripada menebak dari jam perangkat tanpa
/// pustaka zona. Bila kelak perlu WITA/WIT, cukup ganti lokasi di satu tempat.
class LocalNotificationsReminderScheduler implements ReminderScheduler {
  LocalNotificationsReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Satu pengingat saja; id tetap supaya penjadwalan ulang menimpa yang lama.
  static const int notificationId = 1001;
  static const String channelId = 'daily_reminder';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Pengingat Harian',
      channelDescription: 'Pengingat untuk mencatat keuangan harian',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  @override
  Future<bool> sync({
    required bool enabled,
    required ReminderClock clock,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();

      // Selalu batalkan dulu: setelan lama dan baru tidak boleh hidup bersama.
      await _plugin.cancel(id: notificationId);
      if (!enabled) return true;

      final granted = await _requestPermission();
      if (granted == false) return false;

      await _plugin.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: _nextInstance(clock),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // `time` berarti berulang setiap hari pada jam yang sama. SPEC ST-6.
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (error) {
      // Pengingat yang gagal tidak boleh menjatuhkan layar Pengaturan; setelan
      // sudah tersimpan lebih dulu di `app_settings`.
      debugPrint('Gagal menjadwalkan pengingat: $error');
      return true;
    }
  }

  /// Meminta izin notifikasi saat pengingat dinyalakan. SPEC O-2.
  Future<bool?> _requestPermission() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return Future<bool?>.value(null);
      return android.requestNotificationsPermission();
    }
    // iOS meminta izin saat initialize (DarwinInitializationSettings).
    return Future<bool?>.value(true);
  }

  /// Kemunculan berikutnya pada jam [clock]; hari ini bila belum lewat,
  /// selain itu besok.
  tz.TZDateTime _nextInstance(ReminderClock clock) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      clock.hour,
      clock.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}

/// Gerbang tunggal ke penjadwal pengingat.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationsReminderScheduler(),
);
