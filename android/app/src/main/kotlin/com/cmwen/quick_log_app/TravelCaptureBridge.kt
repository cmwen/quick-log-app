package com.cmwen.quick_log_app

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object TravelCaptureBridge {
    const val channelName = "quick_log_app/travel_capture"
    private const val preferencesName = "quick_log_travel_capture"
    private const val flutterPreferencesName = "FlutterSharedPreferences"
    private const val flutterPrefix = "flutter."

    private const val keyMonitoringRequested = "monitoring_requested"
    private const val keyMonitoringActive = "monitoring_active"
    private const val keyStatusMessage = "status_message"
    private const val keyLastEventMessage = "last_event_message"
    private const val keyLastEventAt = "last_event_at"
    private const val keyLastProcessedPhotoId = "last_processed_photo_id"

    private const val databaseName = "quicklog.db"

    private const val flutterLocationEnabledKey = "${flutterPrefix}location_enabled"
    private const val flutterLatitudeKey = "${flutterPrefix}last_latitude"
    private const val flutterLongitudeKey = "${flutterPrefix}last_longitude"
    private const val flutterLocationLabelKey = "${flutterPrefix}last_location_label"

    data class CachedLocation(
        val latitude: Double,
        val longitude: Double,
        val label: String?
    )

    data class ObservedPhoto(
        val id: Long,
        val eventAtMillis: Long
    )

    data class LatestEntry(
        val createdAtMillis: Long,
        val note: String?,
        val tags: List<String>,
        val locationLabel: String?,
        val source: String,
        val hasLocation: Boolean
    )

    fun requiredPermission(): String? {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
                Manifest.permission.READ_MEDIA_IMAGES
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                Manifest.permission.READ_EXTERNAL_STORAGE
            else -> null
        }
    }

    fun permissionLabel(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            "Photos and videos"
        } else {
            "photos and media"
        }
    }

    fun hasPermission(context: Context): Boolean {
        val permission = requiredPermission() ?: return true
        return ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun isMonitoringRequested(context: Context): Boolean {
        return prefs(context).getBoolean(keyMonitoringRequested, false)
    }

    fun setMonitoringRequested(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(keyMonitoringRequested, enabled).apply()
    }

    fun setMonitoringActive(context: Context, active: Boolean) {
        prefs(context).edit().putBoolean(keyMonitoringActive, active).apply()
    }

    fun startMonitoring(context: Context) {
        if (!isMonitoringRequested(context) || !hasPermission(context)) {
            stopMonitoring(context)
            return
        }

        context.startService(Intent(context, TravelPhotoMonitorService::class.java))
    }

    fun stopMonitoring(context: Context) {
        context.stopService(Intent(context, TravelPhotoMonitorService::class.java))
        setMonitoringActive(context, false)
        updateStatusMessage(
            context,
            if (isMonitoringRequested(context) && !hasPermission(context)) {
                "Allow ${permissionLabel()} access to watch for new photos."
            } else {
                "Photo-triggered travel logs are off."
            }
        )
    }

    fun buildStatus(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val statusMessage = prefs.getString(
            keyStatusMessage,
            defaultStatusMessage(context)
        ).orEmpty()

        return linkedMapOf(
            "supported" to true,
            "permissionGranted" to hasPermission(context),
            "monitoringRequested" to isMonitoringRequested(context),
            "monitoringActive" to prefs.getBoolean(keyMonitoringActive, false),
            "permissionLabel" to permissionLabel(),
            "statusMessage" to statusMessage,
            "lastEventMessage" to prefs.getString(keyLastEventMessage, null),
            "lastEventAt" to prefs.getLong(keyLastEventAt, 0L).takeIf { it > 0L }
        )
    }

    fun updateStatusMessage(
        context: Context,
        message: String,
        lastEventMessage: String? = null,
        lastEventAt: Long? = null
    ) {
        prefs(context).edit().apply {
            putString(keyStatusMessage, message)
            if (lastEventMessage == null) {
                remove(keyLastEventMessage)
            } else {
                putString(keyLastEventMessage, lastEventMessage)
            }
            if (lastEventAt == null) {
                remove(keyLastEventAt)
            } else {
                putLong(keyLastEventAt, lastEventAt)
            }
        }.apply()
    }

    fun lastProcessedPhotoId(context: Context): Long {
        return prefs(context).getLong(keyLastProcessedPhotoId, -1L)
    }

    fun markProcessedPhoto(context: Context, photoId: Long) {
        prefs(context).edit().putLong(keyLastProcessedPhotoId, photoId).apply()
    }

    fun getCachedLocation(context: Context): CachedLocation? {
        val flutterPrefs = context.getSharedPreferences(
            flutterPreferencesName,
            Context.MODE_PRIVATE
        )

        if (!flutterPrefs.getBoolean(flutterLocationEnabledKey, true)) {
            return null
        }

        if (!flutterPrefs.contains(flutterLatitudeKey) || !flutterPrefs.contains(flutterLongitudeKey)) {
            return null
        }

        val allValues = flutterPrefs.all
        val latitude = parseDoublePref(allValues[flutterLatitudeKey]) ?: return null
        val longitude = parseDoublePref(allValues[flutterLongitudeKey]) ?: return null

        return CachedLocation(
            latitude = latitude,
            longitude = longitude,
            label = flutterPrefs.getString(flutterLocationLabelKey, null)
        )
    }

    fun insertPhotoTravelLog(
        context: Context,
        photo: ObservedPhoto
    ): Boolean {
        val location = getCachedLocation(context)
        if (location == null) {
            updateStatusMessage(
                context,
                "Photo detected, but no recent location was available.",
                lastEventMessage = "Skipped a photo capture because Quick Log had no cached location.",
                lastEventAt = photo.eventAtMillis
            )
            return false
        }

        val databasePath = context.getDatabasePath(databaseName)
        if (!databasePath.exists()) {
            updateStatusMessage(
                context,
                "Photo detected, but Quick Log is not ready yet.",
                lastEventMessage = "Skipped a photo capture because the Quick Log database was unavailable.",
                lastEventAt = photo.eventAtMillis
            )
            return false
        }

        val db = SQLiteDatabase.openDatabase(
            databasePath.path,
            null,
            SQLiteDatabase.OPEN_READWRITE
        )

        try {
            val values = ContentValues().apply {
                put("createdAt", photo.eventAtMillis)
                put("note", "Photo captured")
                put("tags", "")
                put("latitude", location.latitude)
                put("longitude", location.longitude)
                put("locationLabel", location.label)
                put("source", "autoPhoto")
                put("reviewStatus", "needsReview")
            }

            val rowId = db.insert("entries", null, values)
            if (rowId == -1L) {
                updateStatusMessage(
                    context,
                    "Photo detected, but Quick Log could not save it.",
                    lastEventMessage = "Quick Log could not save a photo-triggered travel log.",
                    lastEventAt = photo.eventAtMillis
                )
                return false
            }

            syncHomeWidgetSnapshot(context, db)
            updateStatusMessage(
                context,
                "Watching for new photos while Travel Mode is active.",
                lastEventMessage = location.label?.let {
                    "Saved a photo-triggered travel log for $it."
                } ?: "Saved a photo-triggered travel log.",
                lastEventAt = photo.eventAtMillis
            )
            return true
        } finally {
            db.close()
        }
    }

    fun syncHomeWidgetSnapshot(context: Context, existingDb: SQLiteDatabase? = null) {
        val databasePath = context.getDatabasePath(databaseName)
        if (!databasePath.exists()) {
            return
        }

        val db = existingDb ?: SQLiteDatabase.openDatabase(
            databasePath.path,
            null,
            SQLiteDatabase.OPEN_READONLY
        )

        try {
            val latestEntry = queryLatestEntry(db)
            val pendingReviewCount = queryPendingReviewCount(db)
            val shortcuts = queryShortcutTags(db)
            val tagLabels = queryTagLabels(db)
            val flutterPrefs = context.getSharedPreferences(
                flutterPreferencesName,
                Context.MODE_PRIVATE
            )

            val snapshot = buildWidgetSnapshot(
                pendingReviewCount = pendingReviewCount,
                latestEntry = latestEntry,
                shortcuts = shortcuts,
                tagLabels = tagLabels,
                locationEnabled = flutterPrefs.getBoolean(flutterLocationEnabledKey, true),
                locationLabel = flutterPrefs.getString(flutterLocationLabelKey, null)
            )

            val prefs = context.getSharedPreferences(
                QuickLogWidgetBridge.preferencesName,
                Context.MODE_PRIVATE
            )

            prefs.edit()
                .putString(QuickLogWidgetBridge.keyStatusLine, snapshot["statusLine"] as String)
                .putString(QuickLogWidgetBridge.keyContentTitle, snapshot["contentTitle"] as String)
                .putString(QuickLogWidgetBridge.keyContentBody, snapshot["contentBody"] as String)
                .putString(
                    QuickLogWidgetBridge.keySecondaryActionLabel,
                    snapshot["secondaryActionLabel"] as String
                )
                .putString(QuickLogWidgetBridge.keyShortcut1Id, snapshot["shortcut1Id"] as String)
                .putString(
                    QuickLogWidgetBridge.keyShortcut1Label,
                    snapshot["shortcut1Label"] as String
                )
                .putString(QuickLogWidgetBridge.keyShortcut2Id, snapshot["shortcut2Id"] as String)
                .putString(
                    QuickLogWidgetBridge.keyShortcut2Label,
                    snapshot["shortcut2Label"] as String
                )
                .putString(QuickLogWidgetBridge.keyShortcut3Id, snapshot["shortcut3Id"] as String)
                .putString(
                    QuickLogWidgetBridge.keyShortcut3Label,
                    snapshot["shortcut3Label"] as String
                )
                .apply()

            QuickLogAppWidgetProvider.updateAll(context)
        } finally {
            if (existingDb == null) {
                db.close()
            }
        }
    }

    fun queryLatestObservedPhoto(context: Context): ObservedPhoto? {
        val projection = mutableListOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.BUCKET_DISPLAY_NAME
        ).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                add(MediaStore.Images.Media.RELATIVE_PATH)
            }
        }.toTypedArray()

        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC LIMIT 5"
        val now = System.currentTimeMillis()

        context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
            val dateAddedIndex =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
            val dateTakenIndex =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_TAKEN)
            val mimeTypeIndex =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
            val bucketIndex =
                cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME)
            val relativePathIndex = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                cursor.getColumnIndex(MediaStore.Images.Media.RELATIVE_PATH)
            } else {
                -1
            }

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex)
                val mimeType = cursor.getString(mimeTypeIndex).orEmpty()
                if (!mimeType.startsWith("image/")) {
                    continue
                }

                val bucketName = cursor.getString(bucketIndex).orEmpty()
                val relativePath = if (relativePathIndex >= 0) {
                    cursor.getString(relativePathIndex).orEmpty()
                } else {
                    ""
                }

                if (bucketName.contains("screenshot", ignoreCase = true) ||
                    relativePath.contains("screenshot", ignoreCase = true)
                ) {
                    continue
                }

                val dateAddedMillis = cursor.getLong(dateAddedIndex) * 1000L
                val dateTakenMillis = cursor.getLong(dateTakenIndex)
                val eventAtMillis = when {
                    dateTakenMillis > 0L -> dateTakenMillis
                    dateAddedMillis > 0L -> dateAddedMillis
                    else -> now
                }

                if (now - eventAtMillis > 10 * 60 * 1000L) {
                    continue
                }

                return ObservedPhoto(id = id, eventAtMillis = eventAtMillis)
            }
        }

        return null
    }

    private fun buildWidgetSnapshot(
        pendingReviewCount: Int,
        latestEntry: LatestEntry?,
        shortcuts: List<Pair<String, String>>,
        tagLabels: Map<String, String>,
        locationEnabled: Boolean,
        locationLabel: String?
    ): Map<String, Any> {
        val statusLine = when {
            pendingReviewCount > 1 -> "$pendingReviewCount travel logs need review"
            pendingReviewCount == 1 -> "1 travel log needs review"
            !locationEnabled -> "Location off"
            !locationLabel.isNullOrBlank() -> locationLabel
            else -> "Ready to log"
        }

        if (latestEntry == null) {
            return linkedMapOf(
                "statusLine" to statusLine,
                "contentTitle" to "Start your first log",
                "contentBody" to "Open Quick Log to choose tags and save your first entry.",
                "secondaryActionLabel" to if (pendingReviewCount > 0) "Review" else "Entries",
                "shortcut1Id" to shortcuts.getOrNull(0)?.first.orEmpty(),
                "shortcut1Label" to shortcuts.getOrNull(0)?.second.orEmpty(),
                "shortcut2Id" to shortcuts.getOrNull(1)?.first.orEmpty(),
                "shortcut2Label" to shortcuts.getOrNull(1)?.second.orEmpty(),
                "shortcut3Id" to shortcuts.getOrNull(2)?.first.orEmpty(),
                "shortcut3Label" to shortcuts.getOrNull(2)?.second.orEmpty()
            )
        }

        val title = when {
            latestEntry.tags.isNotEmpty() -> {
                val labels = latestEntry.tags.mapNotNull { tagLabels[it] ?: it.takeIf(String::isNotBlank) }
                when {
                    labels.size == 1 -> labels.first()
                    labels.size > 1 -> "${labels.first()} +${labels.size - 1}"
                    latestEntry.source == "autoPhoto" -> "Travel photo"
                    latestEntry.source == "autoVisit" -> "Travel log"
                    latestEntry.hasLocation -> "Location only"
                    else -> "Latest entry"
                }
            }
            latestEntry.source == "autoPhoto" -> "Travel photo"
            latestEntry.source == "autoVisit" -> "Travel log"
            latestEntry.hasLocation -> "Location only"
            else -> "Latest entry"
        }

        val contentBody = latestEntry.note?.trim()?.takeIf(String::isNotEmpty)
            ?: latestEntry.locationLabel?.trim()?.takeIf(String::isNotEmpty)
            ?: "Saved ${SimpleDateFormat("MMM d • h:mm a", Locale.getDefault()).format(Date(latestEntry.createdAtMillis))}"

        return linkedMapOf(
            "statusLine" to statusLine,
            "contentTitle" to title,
            "contentBody" to contentBody,
            "secondaryActionLabel" to if (pendingReviewCount > 0) "Review" else "Entries",
            "shortcut1Id" to shortcuts.getOrNull(0)?.first.orEmpty(),
            "shortcut1Label" to shortcuts.getOrNull(0)?.second.orEmpty(),
            "shortcut2Id" to shortcuts.getOrNull(1)?.first.orEmpty(),
            "shortcut2Label" to shortcuts.getOrNull(1)?.second.orEmpty(),
            "shortcut3Id" to shortcuts.getOrNull(2)?.first.orEmpty(),
            "shortcut3Label" to shortcuts.getOrNull(2)?.second.orEmpty()
        )
    }

    private fun queryLatestEntry(db: SQLiteDatabase): LatestEntry? {
        val cursor = db.query(
            "entries",
            arrayOf("createdAt", "note", "tags", "locationLabel", "source", "latitude", "longitude"),
            null,
            null,
            null,
            null,
            "createdAt DESC",
            "1"
        )

        cursor.use {
            if (!it.moveToFirst()) {
                return null
            }

            val tags = it.getString(it.getColumnIndexOrThrow("tags"))
                .orEmpty()
                .split(',')
                .filter(String::isNotBlank)

            return LatestEntry(
                createdAtMillis = it.getLong(it.getColumnIndexOrThrow("createdAt")),
                note = it.getString(it.getColumnIndexOrThrow("note")),
                tags = tags,
                locationLabel = it.getString(it.getColumnIndexOrThrow("locationLabel")),
                source = it.getString(it.getColumnIndexOrThrow("source")).orEmpty(),
                hasLocation =
                    !it.isNull(it.getColumnIndexOrThrow("latitude")) &&
                        !it.isNull(it.getColumnIndexOrThrow("longitude"))
            )
        }
    }

    private fun queryPendingReviewCount(db: SQLiteDatabase): Int {
        return db.rawQuery(
            "SELECT COUNT(*) FROM entries WHERE reviewStatus = ?",
            arrayOf("needsReview")
        ).use {
            if (it.moveToFirst()) it.getInt(0) else 0
        }
    }

    private fun queryShortcutTags(db: SQLiteDatabase): List<Pair<String, String>> {
        return db.query(
            "tags",
            arrayOf("id", "label"),
            "usageCount > 0",
            null,
            null,
            null,
            "usageCount DESC, label ASC",
            "3"
        ).use { cursor ->
            buildList {
                while (cursor.moveToNext()) {
                    add(
                        cursor.getString(cursor.getColumnIndexOrThrow("id")).orEmpty() to
                            cursor.getString(cursor.getColumnIndexOrThrow("label")).orEmpty()
                    )
                }
            }
        }
    }

    private fun queryTagLabels(db: SQLiteDatabase): Map<String, String> {
        return db.query(
            "tags",
            arrayOf("id", "label"),
            null,
            null,
            null,
            null,
            null
        ).use { cursor ->
            buildMap {
                while (cursor.moveToNext()) {
                    put(
                        cursor.getString(cursor.getColumnIndexOrThrow("id")).orEmpty(),
                        cursor.getString(cursor.getColumnIndexOrThrow("label")).orEmpty()
                    )
                }
            }
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun parseDoublePref(value: Any?): Double? {
        return when (value) {
            is Double -> value
            is Float -> value.toDouble()
            is Long -> {
                val asDouble = value.toDouble()
                if (asDouble in -180.0..180.0) asDouble else Double.fromBits(value)
            }
            is Int -> value.toDouble()
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        }
    }

    private fun defaultStatusMessage(context: Context): String {
        return when {
            !isMonitoringRequested(context) -> "Photo-triggered travel logs are off."
            !hasPermission(context) -> "Allow ${permissionLabel()} access to watch for new photos."
            else -> "Watching for new photos while Travel Mode is active."
        }
    }
}
