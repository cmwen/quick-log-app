package com.cmwen.quick_log_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import kotlin.math.absoluteValue

class QuickLogAppWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, QuickLogAppWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            appWidgetIds.forEach { appWidgetId ->
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(
                QuickLogWidgetBridge.preferencesName,
                Context.MODE_PRIVATE
            )

            val views = RemoteViews(context.packageName, R.layout.quick_log_widget)

            views.setTextViewText(
                R.id.widget_status,
                prefs.getString(QuickLogWidgetBridge.keyStatusLine, "Ready to log")
            )
            views.setTextViewText(
                R.id.widget_content_title,
                prefs.getString(QuickLogWidgetBridge.keyContentTitle, "Start your first log")
            )

            val contentBody =
                prefs.getString(
                    QuickLogWidgetBridge.keyContentBody,
                    "Open Quick Log to choose tags and save your first entry."
                ).orEmpty()
            views.setTextViewText(R.id.widget_content_body, contentBody)
            views.setViewVisibility(
                R.id.widget_content_body,
                if (contentBody.isBlank()) View.GONE else View.VISIBLE
            )

            val secondaryLabel =
                prefs.getString(QuickLogWidgetBridge.keySecondaryActionLabel, "Entries")
                    .orEmpty()
                    .ifBlank { "Entries" }
            views.setTextViewText(R.id.widget_secondary_action, secondaryLabel)

            views.setOnClickPendingIntent(
                R.id.widget_primary_action,
                createLaunchPendingIntent(
                    context = context,
                    destination = "record",
                    appWidgetId = appWidgetId,
                    requestKey = "primary"
                )
            )
            views.setOnClickPendingIntent(
                R.id.widget_secondary_action,
                createLaunchPendingIntent(
                    context = context,
                    destination = "entries",
                    appWidgetId = appWidgetId,
                    requestKey = "secondary"
                )
            )
            views.setOnClickPendingIntent(
                R.id.widget_header,
                createLaunchPendingIntent(
                    context = context,
                    destination = if (secondaryLabel == "Review") "entries" else "record",
                    appWidgetId = appWidgetId,
                    requestKey = "header"
                )
            )

            bindShortcutButton(
                views = views,
                context = context,
                appWidgetId = appWidgetId,
                buttonId = R.id.widget_shortcut_1,
                label = prefs.getString(QuickLogWidgetBridge.keyShortcut1Label, "").orEmpty(),
                tagId = prefs.getString(QuickLogWidgetBridge.keyShortcut1Id, "").orEmpty(),
                requestKey = "shortcut1"
            )
            bindShortcutButton(
                views = views,
                context = context,
                appWidgetId = appWidgetId,
                buttonId = R.id.widget_shortcut_2,
                label = prefs.getString(QuickLogWidgetBridge.keyShortcut2Label, "").orEmpty(),
                tagId = prefs.getString(QuickLogWidgetBridge.keyShortcut2Id, "").orEmpty(),
                requestKey = "shortcut2"
            )
            bindShortcutButton(
                views = views,
                context = context,
                appWidgetId = appWidgetId,
                buttonId = R.id.widget_shortcut_3,
                label = prefs.getString(QuickLogWidgetBridge.keyShortcut3Label, "").orEmpty(),
                tagId = prefs.getString(QuickLogWidgetBridge.keyShortcut3Id, "").orEmpty(),
                requestKey = "shortcut3"
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun bindShortcutButton(
            views: RemoteViews,
            context: Context,
            appWidgetId: Int,
            buttonId: Int,
            label: String,
            tagId: String,
            requestKey: String
        ) {
            val shouldShow = label.isNotBlank() && tagId.isNotBlank()
            views.setViewVisibility(buttonId, if (shouldShow) View.VISIBLE else View.GONE)
            if (!shouldShow) {
                return
            }

            views.setTextViewText(buttonId, label)
            views.setOnClickPendingIntent(
                buttonId,
                createLaunchPendingIntent(
                    context = context,
                    destination = "record",
                    appWidgetId = appWidgetId,
                    requestKey = requestKey,
                    tagId = tagId
                )
            )
        }

        private fun createLaunchPendingIntent(
            context: Context,
            destination: String,
            appWidgetId: Int,
            requestKey: String,
            tagId: String? = null
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(QuickLogWidgetBridge.extraDestination, destination)
                if (!tagId.isNullOrBlank()) {
                    putExtra(QuickLogWidgetBridge.extraTagId, tagId)
                }
            }

            val requestCode =
                "$appWidgetId:$requestKey:${tagId.orEmpty()}".hashCode().absoluteValue

            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
