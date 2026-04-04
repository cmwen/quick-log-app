package com.cmwen.quick_log_app

import android.app.Service
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.MediaStore

class TravelPhotoMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val processRunnable = Runnable { processLatestPhoto() }
    private var contentObserver: ContentObserver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!TravelCaptureBridge.isMonitoringRequested(this) ||
            !TravelCaptureBridge.hasPermission(this)
        ) {
            TravelCaptureBridge.setMonitoringActive(this, false)
            stopSelf()
            return START_NOT_STICKY
        }

        ensureObserverRegistered()
        TravelCaptureBridge.setMonitoringActive(this, true)
        TravelCaptureBridge.updateStatusMessage(
            this,
            "Watching for new photos while Travel Mode is active."
        )
        return START_STICKY
    }

    override fun onDestroy() {
        contentObserver?.let { contentResolver.unregisterContentObserver(it) }
        contentObserver = null
        handler.removeCallbacksAndMessages(null)
        TravelCaptureBridge.setMonitoringActive(this, false)
        if (TravelCaptureBridge.isMonitoringRequested(this) &&
            TravelCaptureBridge.hasPermission(this)
        ) {
            TravelCaptureBridge.updateStatusMessage(
                this,
                "Photo monitoring paused. Open Quick Log to resume watching for new photos."
            )
        }
        super.onDestroy()
    }

    private fun ensureObserverRegistered() {
        if (contentObserver != null) {
            return
        }

        TravelCaptureBridge.queryLatestObservedPhoto(this)?.let { latestPhoto ->
            TravelCaptureBridge.markProcessedPhoto(this, latestPhoto.id)
        }

        contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                schedulePhotoProcessing()
            }

            override fun onChange(selfChange: Boolean, uri: Uri?) {
                schedulePhotoProcessing()
            }
        }

        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            contentObserver!!
        )
    }

    private fun schedulePhotoProcessing() {
        handler.removeCallbacks(processRunnable)
        handler.postDelayed(processRunnable, 1200L)
    }

    private fun processLatestPhoto() {
        if (!TravelCaptureBridge.isMonitoringRequested(this) ||
            !TravelCaptureBridge.hasPermission(this)
        ) {
            stopSelf()
            return
        }

        val latestPhoto = TravelCaptureBridge.queryLatestObservedPhoto(this) ?: return
        if (latestPhoto.id == TravelCaptureBridge.lastProcessedPhotoId(this)) {
            return
        }

        TravelCaptureBridge.markProcessedPhoto(this, latestPhoto.id)
        TravelCaptureBridge.insertPhotoTravelLog(this, latestPhoto)
    }
}
