package com.pencatatankeuangan.pencatatan_keuangan

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.service.notification.NotificationListenerService

/**
 * Memastikan penangkap notifikasi hidup lagi setelah HP menyala ulang atau
 * aplikasi diperbarui.
 *
 * Android biasanya mengikat ulang NotificationListenerService sendiri, tetapi
 * beberapa ROM (Xiaomi, Oppo, Vivo, Samsung) menahannya sampai aplikasi dibuka.
 * Permintaan rebind di sini adalah usaha pertama; kalau sistem tetap menolak,
 * antrean event tidak hilang karena tersimpan di SharedPreferences dan akan
 * disedot saat aplikasi dibuka.
 */
class SpendlyBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            // Beberapa produsen mengirim varian cepat selain BOOT_COMPLETED.
            // Android tidak menyediakan konstanta untuk keduanya.
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> Unit
            else -> return
        }

        try {
            NotificationListenerService.requestRebind(
                ComponentName(
                    context,
                    SpendlyNotificationListenerService::class.java,
                ),
            )
        } catch (_: Exception) {
            // Sebagian produsen memblokir permintaan ini. Bukan kegagalan
            // fatal: layanan tetap akan terikat saat pengguna membuka aplikasi.
        }

        // Sedot event yang sempat masuk sebelum reboot, tanpa menunggu UI.
        NotificationCaptureBridge.wake(context.applicationContext)
    }
}
