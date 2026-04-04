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

      expect(snapshot.statusLine, 'Location off');
      expect(snapshot.contentTitle, 'Start your first log');
      expect(
        snapshot.contentBody,
        'Open Quick Log to choose tags and save your first entry.',
      );
      expect(snapshot.secondaryActionLabel, 'Entries');
      expect(snapshot.shortcuts, isEmpty);
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

      expect(snapshot.statusLine, '2 travel logs need review');
      expect(snapshot.contentTitle, 'Work +1');
      expect(snapshot.contentBody, 'Coffee and planning');
      expect(snapshot.secondaryActionLabel, 'Review');
      expect(snapshot.shortcuts.map((shortcut) => shortcut.label), [
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

        expect(snapshot.statusLine, 'Terminal 2');
        expect(snapshot.contentTitle, 'Travel log');
        expect(snapshot.contentBody, startsWith('Saved '));
      },
    );
  });
}
