package com.cmwen.quick_log_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
                QuickLogWidgetBridge.keyStatusLine,
                arguments[QuickLogWidgetBridge.keyStatusLine] as? String ?: "Ready to log"
            )
            .putString(
                QuickLogWidgetBridge.keyContentTitle,
                arguments[QuickLogWidgetBridge.keyContentTitle] as? String ?: "Start your first log"
            )
            .putString(
                QuickLogWidgetBridge.keyContentBody,
                arguments[QuickLogWidgetBridge.keyContentBody] as? String ?: ""
            )
            .putString(
                QuickLogWidgetBridge.keySecondaryActionLabel,
                arguments[QuickLogWidgetBridge.keySecondaryActionLabel] as? String ?: "Entries"
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
}
