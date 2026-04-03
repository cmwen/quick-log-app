import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/services/visit_detection_service.dart';

void main() {
  group('VisitDetectionService', () {
    final service = VisitDetectionService();

    Position buildPosition({
      required double latitude,
      required double longitude,
      required DateTime timestamp,
    }) {
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    test('travel mode saves shorter meaningful stops for review', () {
      final startedAt = DateTime(2024, 1, 1, 9, 0);
      final endedAt = startedAt.add(const Duration(minutes: 9));
      final candidate =
          VisitCandidate.start(
            buildPosition(
              latitude: 37.7749,
              longitude: -122.4194,
              timestamp: startedAt,
            ),
            startedAt,
          ).absorb(
            buildPosition(
              latitude: 37.7750,
              longitude: -122.4195,
              timestamp: endedAt,
            ),
            endedAt,
          );

      final travelEntry = service.buildAutoVisitEntry(
        candidate: candidate,
        locationLabel: 'San Francisco',
        latestLoggedVisit: null,
        travelModeEnabled: true,
      );
      final everydayEntry = service.buildAutoVisitEntry(
        candidate: candidate,
        locationLabel: 'San Francisco',
        latestLoggedVisit: null,
        travelModeEnabled: false,
      );

      expect(travelEntry, isNotNull);
      expect(travelEntry!.reviewStatus, EntryReviewStatus.needsReview);
      expect(everydayEntry, isNull);
    });

    test('everyday auto-log still saves longer stops', () {
      final startedAt = DateTime(2024, 1, 1, 9, 0);
      final endedAt = startedAt.add(const Duration(minutes: 13));
      final candidate = VisitCandidate(
        startedAt: startedAt,
        lastSeenAt: endedAt,
        centerLatitude: 37.7749,
        centerLongitude: -122.4194,
        sampleCount: 4,
      );

      final entry = service.buildAutoVisitEntry(
        candidate: candidate,
        locationLabel: 'San Francisco',
        latestLoggedVisit: null,
        travelModeEnabled: false,
      );

      expect(entry, isNotNull);
      expect(entry!.visitDurationMinutes, 13);
    });
  });
}
