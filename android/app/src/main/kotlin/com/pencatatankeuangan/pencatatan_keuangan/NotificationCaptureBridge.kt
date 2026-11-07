package com.pencatatankeuangan.pencatatan_keuangan

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Menjalankan mesin Flutter latar untuk memproses notifikasi.
 *
 * Listener Android tidak menulis Drift sendiri. Ia hanya menyimpan event lalu
 * membangunkan isolate ini; parsing dan penulisan dilakukan oleh kode Dart yang
 * sama dengan aplikasi utama.
 */
object NotificationCaptureBridge {
    private const val TAG = "SpendlyNotification"
    private const val CHANNEL = "spendly/notification_capture"
    private const val ENTRYPOINT = "notificationCaptureMain"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var engine: FlutterEngine? = null

    @Volatile
    private var channel: MethodChannel? = null

    @Volatile
    private var starting = false

    @Volatile
    private var dartReady = false

    fun wake(context: Context) {
        mainHandler.post {
            if (engine == null) {
                startEngine(context.applicationContext)
            } else if (dartReady) {
                channel?.invokeMethod("wake", null)
            }
        }
    }

    private fun startEngine(context: Context) {
        if (engine != null || starting) return
        starting = true
        dartReady = false

        var flutterEngine: FlutterEngine? = null
        try {
            val created = FlutterEngine(context)
            flutterEngine = created
            val methodChannel = MethodChannel(
                created.dartExecutor.binaryMessenger,
                CHANNEL,
            )
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> {
                        dartReady = true
                        result.success(true)
                        // Event yang masuk sebelum isolate siap tetap ada di
                        // antrean; bangunkan sekali lagi sekarang.
                        methodChannel.invokeMethod("wake", null)
                    }

                    "drain" -> result.success(NotificationCaptureQueue.drain(context))
                    "ack" -> {
                        val ids = (call.arguments as? List<*>)
                            ?.mapNotNull { it?.toString() }
                            ?: emptyList()
                        NotificationCaptureQueue.ack(context, ids)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

            // Pasang handler sebelum Dart berjalan. Dengan begitu panggilan
            // `ready` dari isolate tidak bisa mendahului handler platform.
            engine = created
            channel = methodChannel

            val bundlePath = FlutterInjector.instance()
                .flutterLoader()
                .findAppBundlePath()
            created.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(bundlePath, ENTRYPOINT),
            )
        } catch (error: Throwable) {
            // Jangan mencatat isi notifikasi. Antrean tetap tersimpan dan akan
            // disedot oleh aplikasi utama saat dibuka.
            Log.e(TAG, "Mesin latar notifikasi gagal dimulai", error)
            dartReady = false
            channel?.setMethodCallHandler(null)
            channel = null
            engine = null
            flutterEngine?.destroy()
        } finally {
            starting = false
        }
    }

    fun shutdown() {
        mainHandler.post {
            dartReady = false
            channel?.setMethodCallHandler(null)
            channel = null
            engine?.destroy()
            engine = null
        }
    }
}
