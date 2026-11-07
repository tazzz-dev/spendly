package com.pencatatankeuangan.pencatatan_keuangan

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Penangkap notifikasi dari bank dan dompet digital yang didukung.
 *
 * Layanan ini sengaja tipis: menyaring paket, mengambil judul/isi, menyimpan
 * event, lalu membangunkan mesin Flutter latar. Tidak ada teks notifikasi yang
 * dicatat ke log.
 */
class SpendlyNotificationListenerService : NotificationListenerService() {
    companion object {
        @Volatile
        var isConnected: Boolean = false
            private set

        /**
         * Nama paket target. Selaras dengan `lib/domain/notification_source.dart`.
         * Beberapa aplikasi punya nama paket lama dan baru; keduanya diterima.
         */
        private val TARGET_PACKAGES = setOf(
            "com.bca",
            "id.co.bankmandiri.livin",
            "id.co.bri.brimo",
            "com.gojek.app",
            "com.gojek.gopay",
            "club.sobatovo.android",
            "ovo.id",
            "id.dana",
            "com.shopee.id",
            "com.shopeepay.id",
            "com.bcadigital.blu",
            "id.co.bankbkemobile.digital",
        )
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isConnected = true
        // Layanan bisa terikat kembali setelah reboot atau pembaruan aplikasi
        // tanpa ada notifikasi baru. Bangunkan mesin latar sekali supaya
        // antrean lama ikut tersedot ke basis data.
        NotificationCaptureBridge.wake(applicationContext)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isConnected = false
    }

    override fun onNotificationPosted(notification: StatusBarNotification) {
        val packageName = notification.packageName
        if (packageName !in TARGET_PACKAGES) return

        val posted = notification.notification ?: return
        // Ringkasan grup hanya mengulang isi notifikasi lain.
        if ((posted.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

        val extras = posted.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)
            ?.toString()
            ?.trim()
            .orEmpty()
        val message = (
            extras.getCharSequence(Notification.EXTRA_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_SUB_TEXT)
            )
            ?.toString()
            ?.trim()
            .orEmpty()

        if (title.isEmpty() && message.isEmpty()) return

        val added = NotificationCaptureQueue.enqueue(
            applicationContext,
            packageName,
            title,
            message,
            notification.postTime,
        )
        if (added) {
            NotificationCaptureBridge.wake(applicationContext)
        }
    }

    override fun onDestroy() {
        isConnected = false
        NotificationCaptureBridge.shutdown()
        super.onDestroy()
    }
}
