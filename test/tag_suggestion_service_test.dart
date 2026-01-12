import 'package:flutter_test/flutter_test.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/services/tag_suggestion_service.dart';

void main() {
  group('TagSuggestionService', () {
    late List<LogTag> allTags;
    late List<LogEntry> historicalEntries;

    setUp(() {
      // Create sample tags
      allTags = [
        LogTag(id: 'work', label: 'Work', category: TagCategory.activity, usageCount: 10),
        LogTag(id: 'exercise', label: 'Exercise', category: TagCategory.activity, usageCount: 5),
        LogTag(id: 'home', label: 'Home', category: TagCategory.location, usageCount: 8),
        LogTag(id: 'happy', label: 'Happy', category: TagCategory.mood, usageCount: 6),
        LogTag(id: 'cafe', label: 'Café', category: TagCategory.location, usageCount: 3),
      ];

      // Create sample historical entries
      final now = DateTime.now();
      historicalEntries = [
        // Work entries at 9am on weekdays
        LogEntry(
          id: 1,
          createdAt: DateTime(now.year, now.month, now.day - 1, 9, 0),
          tags: ['work', 'home'],
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        LogEntry(
          id: 2,
          createdAt: DateTime(now.year, now.month, now.day - 2, 9, 30),
          tags: ['work'],
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        // Exercise entries at 6pm
        LogEntry(
          id: 3,
          createdAt: DateTime(now.year, now.month, now.day - 1, 18, 0),
          tags: ['exercise', 'happy'],
          latitude: 37.7849,
          longitude: -122.4094,
        ),
        LogEntry(
          id: 4,
          createdAt: DateTime(now.year, now.month, now.day - 8, 18, 15),
          tags: ['exercise'],
          latitude: 37.7849,
          longitude: -122.4094,
        ),
      ];
    });

    test('should return empty list when no historical data', () {
      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: [],
        allTags: allTags,
        currentTime: DateTime.now(),
      );

      expect(suggestions, isEmpty);
    });

    test('should suggest tags based on time of day (morning work pattern)', () {
      final now = DateTime.now();
      final morningTime = DateTime(now.year, now.month, now.day, 9, 0);

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: historicalEntries,
        allTags: allTags,
        currentTime: morningTime,
      );

      // Should suggest work-related tags for morning time
      expect(suggestions, isNotEmpty);
      final tagIds = suggestions.map((t) => t.id).toList();
      expect(tagIds, contains('work'));
    });

    test('should suggest tags based on time of day (evening exercise pattern)', () {
      final now = DateTime.now();
      final eveningTime = DateTime(now.year, now.month, now.day, 18, 0);

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: historicalEntries,
        allTags: allTags,
        currentTime: eveningTime,
      );

      // Should suggest exercise-related tags for evening time
      expect(suggestions, isNotEmpty);
      final tagIds = suggestions.map((t) => t.id).toList();
      expect(tagIds, contains('exercise'));
    });

    test('should consider location proximity in suggestions', () {
      final now = DateTime.now();
      final morningTime = DateTime(now.year, now.month, now.day, 9, 0);

      // Near work location
      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: historicalEntries,
        allTags: allTags,
        currentTime: morningTime,
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
      );

      expect(suggestions, isNotEmpty);
      // Work should be suggested since we're at similar location and time
      final tagIds = suggestions.map((t) => t.id).toList();
      expect(tagIds, contains('work'));
    });

    test('should limit suggestions to maximum of 8 tags', () {
      // Create many historical entries with different tags
      final manyEntries = List.generate(20, (i) {
        return LogEntry(
          id: i,
          createdAt: DateTime.now().subtract(Duration(days: i)),
          tags: ['work', 'home', 'exercise'],
        );
      });

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: manyEntries,
        allTags: allTags,
        currentTime: DateTime.now(),
      );

      expect(suggestions.length, lessThanOrEqualTo(8));
    });

    test('should handle entries without location data', () {
      final entriesNoLocation = [
        LogEntry(
          id: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          tags: ['work'],
        ),
      ];

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: entriesNoLocation,
        allTags: allTags,
        currentTime: DateTime.now(),
      );

      // Should still work without location
      expect(suggestions, isNotEmpty);
    });

    test('should prefer more recent patterns', () {
      final now = DateTime.now();
      final recentAndOldEntries = [
        // Recent entry with 'exercise'
        LogEntry(
          id: 1,
          createdAt: now.subtract(const Duration(days: 1)),
          tags: ['exercise'],
        ),
        // Old entry with 'work'
        LogEntry(
          id: 2,
          createdAt: now.subtract(const Duration(days: 60)),
          tags: ['work'],
        ),
      ];

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: recentAndOldEntries,
        allTags: allTags,
        currentTime: now,
      );

      expect(suggestions, isNotEmpty);
      // Recent 'exercise' should be ranked higher than old 'work'
      if (suggestions.isNotEmpty) {
        expect(suggestions.first.id, 'exercise');
      }
    });

    test('should match day of week patterns', () {
      final now = DateTime.now();
      
      // Create entries on same day of week
      final sameDayEntries = [
        LogEntry(
          id: 1,
          createdAt: DateTime(now.year, now.month, now.day - 7, 10, 0), // Same day, last week
          tags: ['work', 'cafe'],
        ),
        LogEntry(
          id: 2,
          createdAt: DateTime(now.year, now.month, now.day - 14, 10, 30), // Same day, 2 weeks ago
          tags: ['work'],
        ),
      ];

      final suggestions = TagSuggestionService.getSuggestedTags(
        historicalEntries: sameDayEntries,
        allTags: allTags,
        currentTime: now,
      );

      expect(suggestions, isNotEmpty);
      // Should suggest work since it appears on same day of week
      final tagIds = suggestions.map((t) => t.id).toList();
      expect(tagIds, contains('work'));
    });
  });
}
