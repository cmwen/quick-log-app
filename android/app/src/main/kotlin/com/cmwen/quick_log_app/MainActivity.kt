package com.cmwen.quick_log_app

import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingTravelCapturePermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QuickLogWidgetBridge.channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateHomeWidget" -> {
                    updateHomeWidget(call)
                    result.success(null)
                }
                "consumeLaunchAction" -> result.success(consumeLaunchAction())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TravelCaptureBridge.channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus" -> result.success(TravelCaptureBridge.buildStatus(this))
                "requestPermission" -> requestTravelCapturePermission(result)
                "setMonitoringEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    TravelCaptureBridge.setMonitoringRequested(this, enabled)
                    if (enabled && TravelCaptureBridge.hasPermission(this)) {
                        TravelCaptureBridge.startMonitoring(this)
                    } else {
                        TravelCaptureBridge.stopMonitoring(this)
                    }
                    result.success(TravelCaptureBridge.buildStatus(this))
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun updateHomeWidget(call: MethodCall) {
        val arguments = call.arguments as? Map<*, *> ?: return
        val prefs = getSharedPreferences(QuickLogWidgetBridge.preferencesName, MODE_PRIVATE)

        prefs.edit()
            .putString(
                QuickLogWidgetBridge.keyTravelStatusLine,
                arguments[QuickLogWidgetBridge.keyTravelStatusLine] as? String ?: "Ready to log"
            )
            .putString(
                QuickLogWidgetBridge.keyTravelContentTitle,
                arguments[QuickLogWidgetBridge.keyTravelContentTitle] as? String
                    ?: "Log current location"
            )
            .putString(
                QuickLogWidgetBridge.keyTravelContentBody,
                arguments[QuickLogWidgetBridge.keyTravelContentBody] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyTravelSecondaryActionLabel,
                arguments[QuickLogWidgetBridge.keyTravelSecondaryActionLabel] as? String ?: "Entries"
            )
            .putString(
                QuickLogWidgetBridge.keyTagsStatusLine,
                arguments[QuickLogWidgetBridge.keyTagsStatusLine] as? String ?: "Ready to log"
            )
            .putString(
                QuickLogWidgetBridge.keyTagsContentTitle,
                arguments[QuickLogWidgetBridge.keyTagsContentTitle] as? String
                    ?: "Start your first log"
            )
            .putString(
                QuickLogWidgetBridge.keyTagsContentBody,
                arguments[QuickLogWidgetBridge.keyTagsContentBody] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyTagsSecondaryActionLabel,
                arguments[QuickLogWidgetBridge.keyTagsSecondaryActionLabel] as? String ?: "Entries"
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut1Id,
                arguments[QuickLogWidgetBridge.keyShortcut1Id] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut1Label,
                arguments[QuickLogWidgetBridge.keyShortcut1Label] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut2Id,
                arguments[QuickLogWidgetBridge.keyShortcut2Id] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut2Label,
                arguments[QuickLogWidgetBridge.keyShortcut2Label] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut3Id,
                arguments[QuickLogWidgetBridge.keyShortcut3Id] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keyShortcut3Label,
                arguments[QuickLogWidgetBridge.keyShortcut3Label] as? String ?: ""
            )
            .apply()

        QuickLogAppWidgetProvider.updateAll(this)
        QuickLogTagsAppWidgetProvider.updateAll(this)
    }

    private fun consumeLaunchAction(): Map<String, String>? {
        val currentIntent = intent ?: return null
        val destination =
            currentIntent.getStringExtra(QuickLogWidgetBridge.extraDestination) ?: return null

        val action = linkedMapOf("destination" to destination)
        currentIntent.getStringExtra(QuickLogWidgetBridge.extraTagId)?.let { tagId ->
            action["tagId"] = tagId
        }

        currentIntent.removeExtra(QuickLogWidgetBridge.extraDestination)
        currentIntent.removeExtra(QuickLogWidgetBridge.extraTagId)
        return action
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != travelCapturePermissionRequestCode) {
            return
        }

        if (TravelCaptureBridge.isMonitoringRequested(this) &&
            TravelCaptureBridge.hasPermission(this)
        ) {
            TravelCaptureBridge.startMonitoring(this)
        } else {
            TravelCaptureBridge.stopMonitoring(this)
        }

        pendingTravelCapturePermissionResult?.success(
            TravelCaptureBridge.buildStatus(this)
        )
        pendingTravelCapturePermissionResult = null
    }

    private fun requestTravelCapturePermission(result: MethodChannel.Result) {
        val permission = TravelCaptureBridge.requiredPermission()
        if (permission == null || TravelCaptureBridge.hasPermission(this)) {
            result.success(TravelCaptureBridge.buildStatus(this))
            return
        }

        if (pendingTravelCapturePermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "A photo permission request is already in progress.",
                null
            )
            return
        }

        pendingTravelCapturePermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            travelCapturePermissionRequestCode
        )
    }

    companion object {
        private const val travelCapturePermissionRequestCode = 4201
    }
}
