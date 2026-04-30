import 'package:flutter_test/flutter_test.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/services/home_widget_service.dart';

void main() {
  group('HomeWidgetSnapshotBuilder', () {
    test('uses empty state copy when there are no entries yet', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        pendingReviewCount: 0,
        latestEntry: null,
        shortcutTags: const <LogTag>[],
        tagLabels: const <String, String>{},
        locationEnabled: false,
        locationLabel: null,
      );

      expect(snapshot.travel.statusLine, 'Location off');
      expect(snapshot.travel.contentTitle, 'Log current location');
      expect(
        snapshot.travel.contentBody,
        'Enable location tracking in Settings to log your current place.',
      );
      expect(snapshot.tags.contentTitle, 'Start your first log');
      expect(
        snapshot.tags.contentBody,
        'Open Quick Log to choose tags and save your first entry.',
      );
      expect(snapshot.tags.secondaryActionLabel, 'Entries');
      expect(snapshot.tags.shortcuts, isEmpty);
    });

    test('prioritizes pending review status and recent tag shortcuts', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        pendingReviewCount: 2,
        latestEntry: LogEntry(
          createdAt: DateTime(2026, 4, 4, 8, 30),
          note: 'Coffee and planning',
          tags: const ['work', 'focused'],
        ),
        shortcutTags: [
          LogTag(
            id: 'work',
            label: 'Work',
            category: TagCategory.activity,
            usageCount: 5,
          ),
          LogTag(
            id: 'focused',
            label: 'Focused',
            category: TagCategory.mood,
            usageCount: 4,
          ),
        ],
        tagLabels: const {'work': 'Work', 'focused': 'Focused'},
        locationEnabled: true,
        locationLabel: 'Downtown',
      );

      expect(snapshot.travel.statusLine, '2 travel logs need review');
      expect(snapshot.travel.contentTitle, 'Review travel logs');
      expect(snapshot.travel.secondaryActionLabel, 'Review');
      expect(snapshot.tags.contentTitle, 'Work +1');
      expect(snapshot.tags.contentBody, 'Coffee and planning');
      expect(snapshot.tags.secondaryActionLabel, 'Review');
      expect(snapshot.tags.shortcuts.map((shortcut) => shortcut.label), [
        'Work',
        'Focused',
      ]);
    });

    test(
      'falls back to travel copy when an auto-tracked entry has no tags',
      () {
        final snapshot = HomeWidgetSnapshotBuilder.build(
          pendingReviewCount: 0,
          latestEntry: LogEntry(
            createdAt: DateTime(2026, 4, 4, 9, 15),
            source: EntrySource.autoVisit,
          ),
          shortcutTags: const <LogTag>[],
          tagLabels: const <String, String>{},
          locationEnabled: true,
          locationLabel: 'Terminal 2',
        );

        expect(snapshot.travel.statusLine, 'Terminal 2');
        expect(snapshot.travel.contentBody, 'Save an entry for Terminal 2.');
        expect(snapshot.tags.contentTitle, 'Travel log');
        expect(snapshot.tags.contentBody, startsWith('Saved '));
      },
    );

    test('uses travel photo copy for photo-triggered entries', () {
      final snapshot = HomeWidgetSnapshotBuilder.build(
        pendingReviewCount: 0,
        latestEntry: LogEntry(
          createdAt: DateTime(2026, 4, 4, 10, 45),
          source: EntrySource.autoPhoto,
          locationLabel: 'Museum District',
        ),
        shortcutTags: const <LogTag>[],
        tagLabels: const <String, String>{},
        locationEnabled: true,
        locationLabel: 'Museum District',
      );

      expect(snapshot.travel.contentBody, 'Save an entry for Museum District.');
      expect(snapshot.tags.contentTitle, 'Travel photo');
      expect(snapshot.tags.contentBody, 'Museum District');
    });
  });
}
