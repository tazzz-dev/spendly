import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'data/db/app_database.dart';
import 'data/notification_capture_channel.dart';
import 'data/notification_repository.dart';
import 'data/transaction_repository.dart';

/// Titik masuk mesin Flutter latar yang dijalankan oleh
/// `SpendlyNotificationListenerService`.
///
/// Native hanya menyimpan notifikasi mentah dan membangunkan mesin ini. Semua
/// parsing dan penulisan Drift terjadi di sini, memakai aturan Dart yang sama
/// dengan yang diuji di `test/domain/notification_parser_test.dart`.
Future<void> runNotificationCapture() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = NotificationRepository(
    database,
    TransactionRepository(database),
  );
  final sync = NotificationInboxSync(repository);

  const channel = MethodChannel('spendly/notification_capture');
  channel.setMethodCallHandler((call) async {
    if (call.method == 'wake') {
      await sync.sync();
    }
    return null;
  });

  try {
    // Beri tahu native bahwa handler sudah siap, lalu sedot event yang sudah
    // menumpuk sebelum mesin ini hidup.
    await channel.invokeMethod<void>('ready');
    await sync.sync();
  } on MissingPluginException {
    // Seharusnya tidak terjadi ketika dipanggil dari layanan Android.
  } on PlatformException {
    // Biarkan antrean native; percobaan berikutnya masih mungkin.
  }

  // Jangan biarkan isolate selesai. FlutterEngine akan mematikannya ketika
  // layanan Android berhenti.
  await Completer<void>().future;
}
