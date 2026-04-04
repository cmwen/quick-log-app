import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';

enum WidgetLaunchDestination { record, entries }

class WidgetLaunchAction {
  final WidgetLaunchDestination destination;
  final String? tagId;

  const WidgetLaunchAction({required this.destination, this.tagId});

  factory WidgetLaunchAction.fromMap(Map<Object?, Object?> raw) {
    final destinationName = raw['destination'] as String? ?? 'record';

    return WidgetLaunchAction(
      destination: WidgetLaunchDestination.values.firstWhere(
        (value) => value.name == destinationName,
        orElse: () => WidgetLaunchDestination.record,
      ),
      tagId: raw['tagId'] as String?,
    );
  }
}

class WidgetShortcut {
  final String id;
  final String label;

  const WidgetShortcut({required this.id, required this.label});
}

class HomeWidgetSnapshot {
  final String statusLine;
  final String contentTitle;
  final String contentBody;
  final String secondaryActionLabel;
  final List<WidgetShortcut> shortcuts;

  const HomeWidgetSnapshot({
    required this.statusLine,
    required this.contentTitle,
    required this.contentBody,
    required this.secondaryActionLabel,
    required this.shortcuts,
  });

  Map<String, Object?> toMap() {
    final paddedShortcuts = [
      ...shortcuts.take(3),
      ...List<WidgetShortcut>.filled(
        3 - shortcuts.take(3).length,
        const WidgetShortcut(id: '', label: ''),
      ),
    ];

    return {
      'statusLine': statusLine,
      'contentTitle': contentTitle,
      'contentBody': contentBody,
      'secondaryActionLabel': secondaryActionLabel,
      'shortcut1Id': paddedShortcuts[0].id,
      'shortcut1Label': paddedShortcuts[0].label,
      'shortcut2Id': paddedShortcuts[1].id,
      'shortcut2Label': paddedShortcuts[1].label,
      'shortcut3Id': paddedShortcuts[2].id,
      'shortcut3Label': paddedShortcuts[2].label,
    };
  }
}

class HomeWidgetSnapshotBuilder {
  static const String _defaultStatusLine = 'Ready to log';
  static const String _emptyStateTitle = 'Start your first log';
  static const String _emptyStateBody =
      'Open Quick Log to choose tags and save your first entry.';

  const HomeWidgetSnapshotBuilder._();

  static HomeWidgetSnapshot build({
    required int pendingReviewCount,
    required LogEntry? latestEntry,
    required List<LogTag> shortcutTags,
    required Map<String, String> tagLabels,
    required bool locationEnabled,
    required String? locationLabel,
  }) {
    final statusLine = _buildStatusLine(
      pendingReviewCount: pendingReviewCount,
      locationEnabled: locationEnabled,
      locationLabel: locationLabel,
    );

    if (latestEntry == null) {
      return HomeWidgetSnapshot(
        statusLine: statusLine,
        contentTitle: _emptyStateTitle,
        contentBody: _emptyStateBody,
        secondaryActionLabel: pendingReviewCount > 0 ? 'Review' : 'Entries',
        shortcuts: const <WidgetShortcut>[],
      );
    }

    return HomeWidgetSnapshot(
      statusLine: statusLine,
      contentTitle: _buildEntryTitle(latestEntry, tagLabels),
      contentBody: _buildEntryBody(latestEntry),
      secondaryActionLabel: pendingReviewCount > 0 ? 'Review' : 'Entries',
      shortcuts: shortcutTags
          .take(3)
          .map((tag) => WidgetShortcut(id: tag.id, label: tag.label))
          .toList(growable: false),
    );
  }

  static String _buildStatusLine({
    required int pendingReviewCount,
    required bool locationEnabled,
    required String? locationLabel,
  }) {
    if (pendingReviewCount > 0) {
      return pendingReviewCount == 1
          ? '1 travel log needs review'
          : '$pendingReviewCount travel logs need review';
    }

    if (!locationEnabled) {
      return 'Location off';
    }

    if (locationLabel != null && locationLabel.isNotEmpty) {
      return locationLabel;
    }

    return _defaultStatusLine;
  }

  static String _buildEntryTitle(
    LogEntry entry,
    Map<String, String> tagLabels,
  ) {
    if (entry.tags.isNotEmpty) {
      final labels = entry.tags
          .map((tagId) => tagLabels[tagId] ?? tagId)
          .where((label) => label.isNotEmpty)
          .toList(growable: false);

      if (labels.length == 1) {
        return labels.first;
      }

      if (labels.length > 1) {
        return '${labels.first} +${labels.length - 1}';
      }
    }

    if (entry.isAutoTracked) {
      return 'Travel log';
    }

    if (entry.hasLocation) {
      return 'Location only';
    }

    return 'Latest entry';
  }

  static String _buildEntryBody(LogEntry entry) {
    final note = entry.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }

    final locationLabel = entry.locationLabel?.trim();
    if (locationLabel != null && locationLabel.isNotEmpty) {
      return locationLabel;
    }

    return 'Saved ${DateFormat('MMM d • h:mm a').format(entry.createdAt)}';
  }
}

class QuickLogHomeWidgetService {
  QuickLogHomeWidgetService._();

  static final QuickLogHomeWidgetService instance =
      QuickLogHomeWidgetService._();

  static const MethodChannel _channel = MethodChannel('quick_log_app/widget');
  static const String _locationEnabledKey = 'location_enabled';
  static const String _locationLabelKey = 'last_location_label';

  Future<WidgetLaunchAction?> consumeLaunchAction() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final rawAction = await _channel.invokeMethod<Object?>(
        'consumeLaunchAction',
      );
      if (rawAction is Map<Object?, Object?>) {
        return WidgetLaunchAction.fromMap(rawAction);
      }
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> sync() async {
    if (!Platform.isAndroid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final latestEntry = await DatabaseHelper.instance.getLatestEntry();
    final pendingReviewCount = await DatabaseHelper.instance
        .getPendingReviewCount();
    final shortcutTags = await DatabaseHelper.instance.getRecentlyUsedTags(
      limit: 3,
    );
    final allTags = await DatabaseHelper.instance.getAllTags();
    final tagLabels = {for (final tag in allTags) tag.id: tag.label};

    final snapshot = HomeWidgetSnapshotBuilder.build(
      pendingReviewCount: pendingReviewCount,
      latestEntry: latestEntry,
      shortcutTags: shortcutTags,
      tagLabels: tagLabels,
      locationEnabled: prefs.getBool(_locationEnabledKey) ?? true,
      locationLabel: prefs.getString(_locationLabelKey),
    );

    try {
      await _channel.invokeMethod<void>('updateHomeWidget', snapshot.toMap());
    } on MissingPluginException {
      // Widget updates are only available on Android where the native bridge exists.
    }
  }
}
