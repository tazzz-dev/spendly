import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'data/providers.dart';
import 'data/sync/supabase_bootstrap.dart';
import 'data/sync/sync_config.dart';
import 'notification_background.dart';

/// Entry point mesin latar untuk auto-capture notifikasi.
///
/// Fungsi ini dipanggil oleh `SpendlyNotificationListenerService` lewat
/// `DartExecutor.DartEntrypoint`. Harus berada di pustaka `main.dart` karena
/// Android memanggilnya berdasarkan nama fungsi pada pustaka utama.
@pragma('vm:entry-point')
Future<void> notificationCaptureMain() => runNotificationCapture();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // intl perlu data lokal dimuat sebelum `DateFormat('...', 'id_ID')` dipakai.
  await initializeDateFormatting('id_ID');

  final database = AppDatabase();

  // Di web, tautan balik OAuth Google hanya bisa diproses bila Supabase sudah
  // menyala. Penyalaan ditunda ke setelah frame pertama supaya cold start
  // tidak menunggu jaringan; di ponsel, Supabase baru dimuat ketika pengguna
  // membuka halaman Sinkronisasi.
  if (kIsWeb && SyncConfig.isConfigured) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmWebAuth());
    });
  }

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const SpendlyApp(),
    ),
  );
}

Future<void> _warmWebAuth() async {
  try {
    await SupabaseBootstrap.ensureInitialized();
  } catch (error) {
    // Build tanpa konfigurasi atau jaringan bermasalah: aplikasi lokal tetap
    // berjalan, dan pesannya muncul saat halaman Sinkronisasi dibuka.
    debugPrint('Sinkronisasi web belum siap: $error');
  }
}
