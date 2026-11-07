package com.pencatatankeuangan.pencatatan_keuangan

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Antrean notifikasi mentah di penyimpanan privat aplikasi.
 *
 * Event tidak dihapus sebelum Dart menyatakan sudah diproses. Kalau mesin
 * Flutter latar gagal hidup, antrean tetap ada dan disedot saat aplikasi
 * dibuka. Teks notifikasi tidak pernah ditulis ke log.
 */
object NotificationCaptureQueue {
    private const val PREFS = "spendly_notification_queue"
    private const val KEY_EVENTS = "events"
    private const val MAX_EVENTS = 200
    private const val MAX_TEXT = 2000

    private val lock = Any()

    /** Mengembalikan true bila event baru benar-benar masuk antrean. */
    fun enqueue(
        context: Context,
        packageName: String,
        title: String,
        message: String,
        postedAt: Long,
    ): Boolean = synchronized(lock) {
        val safeTitle = title.take(MAX_TEXT)
        val safeMessage = message.take(MAX_TEXT)
        val sourceKey = buildSourceKey(packageName, postedAt, safeTitle, safeMessage)

        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val events = JSONArray(prefs.getString(KEY_EVENTS, "[]") ?: "[]")

            for (index in 0 until events.length()) {
                val existing = events.optJSONObject(index) ?: continue
                if (existing.optString("sourceKey") == sourceKey) return false
            }

            val event = JSONObject()
                .put("id", UUID.randomUUID().toString())
                .put("packageName", packageName)
                .put("title", safeTitle)
                .put("message", safeMessage)
                .put("postedAt", postedAt)
                .put("sourceKey", sourceKey)

            events.put(event)
            while (events.length() > MAX_EVENTS) {
                events.remove(0)
            }

            prefs.edit().putString(KEY_EVENTS, events.toString()).apply()
            true
        } catch (_: Exception) {
            false
        }
    }

    fun drain(context: Context): List<Map<String, Any>> = synchronized(lock) {
        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val events = JSONArray(prefs.getString(KEY_EVENTS, "[]") ?: "[]")
            val result = ArrayList<Map<String, Any>>(events.length())

            for (index in 0 until events.length()) {
                val event = events.optJSONObject(index) ?: continue
                val id = event.optString("id")
                val packageName = event.optString("packageName")
                if (id.isEmpty() || packageName.isEmpty()) continue

                result.add(
                    mapOf(
                        "id" to id,
                        "packageName" to packageName,
                        "title" to event.optString("title"),
                        "message" to event.optString("message"),
                        "postedAt" to event.optLong("postedAt"),
                    ),
                )
            }
            result
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun ack(context: Context, ids: List<String>) = synchronized(lock) {
        if (ids.isEmpty()) return@synchronized
        val wanted = ids.toHashSet()

        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val oldEvents = JSONArray(prefs.getString(KEY_EVENTS, "[]") ?: "[]")
            val remaining = JSONArray()

            for (index in 0 until oldEvents.length()) {
                val event = oldEvents.optJSONObject(index) ?: continue
                if (event.optString("id") !in wanted) {
                    remaining.put(event)
                }
            }

            prefs.edit().putString(KEY_EVENTS, remaining.toString()).apply()
        } catch (_: Exception) {
            // Kalau penghapusan gagal, event akan dicoba lagi. Draft sudah
            // dilindungi source_key unik, jadi tidak akan berganda.
        }
    }

    private fun buildSourceKey(
        packageName: String,
        postedAt: Long,
        title: String,
        message: String,
    ): String = "$packageName|$postedAt|${title.trim()}|${message.trim()}"
}
