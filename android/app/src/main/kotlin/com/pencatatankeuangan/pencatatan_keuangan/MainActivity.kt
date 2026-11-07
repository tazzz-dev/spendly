package com.pencatatankeuangan.pencatatan_keuangan

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val accessChannel = "spendly/notification_access"
    private val captureChannel = "spendly/notification_capture"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            accessChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(
                    mapOf(
                        "granted" to isNotificationAccessGranted(),
                        "connected" to SpendlyNotificationListenerService.isConnected,
                    ),
                )

                "openSettings" -> {
                    try {
                        startActivity(notificationAccessIntent())
                        result.success(null)
                    } catch (error: Exception) {
                        result.error(
                            "SETTINGS_UNAVAILABLE",
                            "Tidak dapat membuka pengaturan akses notifikasi",
                            error.message,
                        )
                    }
                }

                // Panduan agar layanan tidak dimatikan sistem saat aplikasi
                // ditutup. Keduanya hanya membuka layar sistem; tidak ada izin
                // istimewa yang diminta diam-diam.
                "openBatterySettings" -> {
                    try {
                        startActivity(batteryOptimizationIntent())
                        result.success(null)
                    } catch (error: Exception) {
                        result.error(
                            "SETTINGS_UNAVAILABLE",
                            "Tidak dapat membuka pengaturan baterai",
                            error.message,
                        )
                    }
                }

                "openAppSettings" -> {
                    try {
                        startActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                        result.success(null)
                    } catch (error: Exception) {
                        result.error(
                            "SETTINGS_UNAVAILABLE",
                            "Tidak dapat membuka info aplikasi",
                            error.message,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }

        // Saluran yang sama dipakai mesin latar. Di sini ia melayani penyedotan
        // antrean saat aplikasi utama dibuka atau dilanjutkan.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            captureChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> result.success(true)

                "drain" -> result.success(
                    NotificationCaptureQueue.drain(applicationContext),
                )

                "ack" -> {
                    val ids = (call.arguments as? List<*>)
                        ?.mapNotNull { it?.toString() }
                        ?: emptyList()
                    NotificationCaptureQueue.ack(applicationContext, ids)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false

        val expected = ComponentName(
            this,
            SpendlyNotificationListenerService::class.java,
        )

        return enabled.split(':').any { flattened ->
            ComponentName.unflattenFromString(flattened) == expected
        }
    }

    private fun batteryOptimizationIntent(): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        } else {
            Intent(Settings.ACTION_SETTINGS)
        }
    }

    private fun notificationAccessIntent(): Intent {
        val component = ComponentName(
            this,
            SpendlyNotificationListenerService::class.java,
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    component.flattenToString(),
                )
        } else {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        }
    }
}
