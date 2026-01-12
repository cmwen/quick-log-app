import 'dart:math' as math;
import 'package:quick_log_app/models/log_tag.dart';
import 'package:quick_log_app/models/log_entry.dart';

/// Service for providing intelligent tag suggestions based on user patterns
class TagSuggestionService {
  // Constants for algorithm tuning
  static const double _suggestionThreshold = 0.1;
  static const double _earthRadiusMeters = 6371000.0;

  /// Get suggested tags based on current context
  ///
  /// Uses multiple factors:
  /// - Time of day (hour)
  /// - Day of week (0-6, Monday-Sunday)
  /// - Day of month (1-31)
  /// - Location proximity (if available)
  static List<LogTag> getSuggestedTags({
    required List<LogEntry> historicalEntries,
    required List<LogTag> allTags,
    required DateTime currentTime,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    if (historicalEntries.isEmpty || allTags.isEmpty) {
      return [];
    }

    final tagScores = <String, double>{};

    // Initialize all tag scores to 0
    for (var tag in allTags) {
      tagScores[tag.id] = 0.0;
    }

    // Analyze historical entries and score tags based on context similarity
    for (var entry in historicalEntries) {
      final contextScore = _calculateContextSimilarity(
        entry: entry,
        currentTime: currentTime,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
      );

      // Add weighted score to each tag in this entry
      for (var tagId in entry.tags) {
        if (tagScores.containsKey(tagId)) {
          tagScores[tagId] = tagScores[tagId]! + contextScore;
        }
      }
    }

    // Sort tags by score (descending) and return top suggestions
    final sortedTags = allTags.toList()
      ..sort((a, b) {
        final scoreA = tagScores[a.id] ?? 0.0;
        final scoreB = tagScores[b.id] ?? 0.0;
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }
        // If scores are equal, prefer tags with higher usage count
        return b.usageCount.compareTo(a.usageCount);
      });

    // Return tags with significant scores (above threshold)
    return sortedTags
        .where((tag) => (tagScores[tag.id] ?? 0.0) > _suggestionThreshold)
        .take(8) // Return up to 8 suggestions
        .toList();
  }

  /// Calculate how similar the entry's context is to current context
  /// Returns a score between 0 and 1 (higher = more similar)
  static double _calculateContextSimilarity({
    required LogEntry entry,
    required DateTime currentTime,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    double totalScore = 0.0;
    int factors = 0;

    // 1. Time of day similarity (within 1 hour window)
    final hourScore = _calculateHourSimilarity(
      entry.createdAt.hour,
      currentTime.hour,
    );
    totalScore += hourScore * 2.0; // Weight: 2x
    factors += 2;

    // 2. Day of week similarity
    final dayOfWeekScore = _calculateDayOfWeekSimilarity(
      entry.createdAt.weekday,
      currentTime.weekday,
    );
    totalScore += dayOfWeekScore * 1.5; // Weight: 1.5x
    factors += 1;

    // 3. Day of month similarity (for monthly recurring activities)
    final dayOfMonthScore = _calculateDayOfMonthSimilarity(
      entry.createdAt.day,
      currentTime.day,
    );
    totalScore += dayOfMonthScore * 1.0; // Weight: 1x
    factors += 1;

    // 4. Location proximity (if available)
    if (currentLatitude != null &&
        currentLongitude != null &&
        entry.latitude != null &&
        entry.longitude != null) {
      final locationScore = _calculateLocationSimilarity(
        entry.latitude!,
        entry.longitude!,
        currentLatitude,
        currentLongitude,
      );
      totalScore += locationScore * 2.5; // Weight: 2.5x (location is important)
      factors += 2;
    }

    // 5. Recency bonus (more recent entries are more relevant)
    final recencyScore = _calculateRecencyScore(entry.createdAt, currentTime);
    totalScore += recencyScore * 1.0; // Weight: 1x
    factors += 1;

    return factors > 0 ? totalScore / factors : 0.0;
  }

  /// Calculate similarity between two hours (0-23)
  /// Returns 1.0 if within 1 hour, decreases linearly to 0 at 6+ hours apart
  static double _calculateHourSimilarity(int hour1, int hour2) {
    final diff = (hour1 - hour2).abs();
    // Handle wrap-around (e.g., 23 and 0 are 1 hour apart)
    final actualDiff = diff > 12 ? 24 - diff : diff;

    if (actualDiff == 0) return 1.0;
    if (actualDiff == 1) return 0.8;
    if (actualDiff == 2) return 0.5;
    if (actualDiff == 3) return 0.3;
    if (actualDiff <= 5) return 0.1;
    return 0.0;
  }

  /// Calculate similarity between days of week
  /// Returns 1.0 for same day, 0.5 for adjacent days, 0.2 for same weekend pattern
  static double _calculateDayOfWeekSimilarity(int day1, int day2) {
    if (day1 == day2) return 1.0;

    // Adjacent days get some similarity
    final diff = (day1 - day2).abs();
    if (diff == 1 || diff == 6) return 0.5; // Adjacent or wrap-around

    // Weekend pattern (Saturday = 6, Sunday = 7 in Dart DateTime.weekday)
    final isWeekend1 = day1 == 6 || day1 == 7;
    final isWeekend2 = day2 == 6 || day2 == 7;
    if (isWeekend1 && isWeekend2) return 0.4; // Both weekends

    // Weekday pattern (Monday-Friday = 1-5)
    if (!isWeekend1 && !isWeekend2) return 0.2; // Both weekdays

    return 0.0;
  }

  /// Calculate similarity between days of month
  /// Returns 1.0 for same day, partial scores for nearby days
  static double _calculateDayOfMonthSimilarity(int day1, int day2) {
    if (day1 == day2) return 1.0;

    final diff = (day1 - day2).abs();
    if (diff == 1) return 0.3; // Adjacent days
    if (diff <= 3) return 0.15; // Within 3 days
    if (diff <= 7) return 0.05; // Within a week

    return 0.0;
  }

  /// Calculate location similarity using haversine distance
  /// Returns 1.0 if very close (<100m), decreases to 0 at 5km+ distance
  static double _calculateLocationSimilarity(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final distance = _haversineDistance(lat1, lon1, lat2, lon2);

    // Distance thresholds (in meters)
    if (distance < 100) return 1.0; // Same building/area
    if (distance < 500) return 0.8; // Same neighborhood
    if (distance < 1000) return 0.5; // Within 1km
    if (distance < 2000) return 0.3; // Within 2km
    if (distance < 5000) return 0.1; // Within 5km

    return 0.0; // Too far away
  }

  /// Calculate haversine distance between two points in meters
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Calculate recency score - more recent entries are more relevant
  /// Returns score between 0 and 1
  static double _calculateRecencyScore(
    DateTime entryTime,
    DateTime currentTime,
  ) {
    final daysDiff = currentTime.difference(entryTime).inDays;

    if (daysDiff <= 1) return 1.0; // Yesterday or today
    if (daysDiff <= 3) return 0.8; // Within 3 days
    if (daysDiff <= 7) return 0.6; // Within a week
    if (daysDiff <= 14) return 0.4; // Within 2 weeks
    if (daysDiff <= 30) return 0.2; // Within a month
    if (daysDiff <= 60) return 0.1; // Within 2 months

    return 0.05; // Older entries have minimal influence
  }
}
