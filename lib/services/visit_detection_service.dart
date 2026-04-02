import 'package:geolocator/geolocator.dart';
import 'package:quick_log_app/models/log_entry.dart';

class VisitDetectionService {
  static const double _minimumAccuracyMeters = 80;
  static const double _arrivalRadiusMeters = 125;
  static const double _departureRadiusMeters = 180;
  static const Duration _travelDwellThreshold = Duration(minutes: 8);
  static const Duration _everydayDwellThreshold = Duration(minutes: 12);
  static const Duration _mergeCooldown = Duration(minutes: 45);
  static const Duration _minimumGapBeforeLeaving = Duration(minutes: 3);
  static const double _minimumVisitDistanceMeters = 150;

  VisitCandidate? updateCandidate({
    required VisitCandidate? candidate,
    required Position position,
    required bool travelModeEnabled,
  }) {
    if ((position.accuracy).isFinite &&
        position.accuracy > _minimumAccuracyMeters) {
      return candidate;
    }

    final timestamp = position.timestamp;
    if (candidate == null) {
      return VisitCandidate.start(position, timestamp);
    }

    final distance = Geolocator.distanceBetween(
      candidate.centerLatitude,
      candidate.centerLongitude,
      position.latitude,
      position.longitude,
    );

    if (distance <= _arrivalRadiusMeters) {
      return candidate.absorb(position, timestamp);
    }

    final dwellThreshold = travelModeEnabled
        ? _travelDwellThreshold
        : _everydayDwellThreshold;

    if (candidate.duration >= dwellThreshold &&
        distance >= _minimumVisitDistanceMeters &&
        timestamp.difference(candidate.lastSeenAt) >=
            _minimumGapBeforeLeaving) {
      return candidate;
    }

    return VisitCandidate.start(position, timestamp);
  }

  LogEntry? buildAutoVisitEntry({
    required VisitCandidate candidate,
    required String? locationLabel,
    required LogEntry? latestLoggedVisit,
  }) {
    if (candidate.duration < _travelDwellThreshold) {
      return null;
    }

    if (latestLoggedVisit != null &&
        latestLoggedVisit.hasLocation &&
        latestLoggedVisit.visitStartedAt != null) {
      final sameWindow =
          candidate.startedAt
              .difference(latestLoggedVisit.visitStartedAt!)
              .abs() <
          _mergeCooldown;
      final distance = Geolocator.distanceBetween(
        latestLoggedVisit.latitude!,
        latestLoggedVisit.longitude!,
        candidate.centerLatitude,
        candidate.centerLongitude,
      );
      if (sameWindow && distance < _departureRadiusMeters) {
        return null;
      }
    }

    return LogEntry(
      createdAt: candidate.startedAt,
      tags: const <String>[],
      latitude: candidate.centerLatitude,
      longitude: candidate.centerLongitude,
      locationLabel: locationLabel,
      source: EntrySource.autoVisit,
      reviewStatus: EntryReviewStatus.needsReview,
      visitStartedAt: candidate.startedAt,
      visitEndedAt: candidate.lastSeenAt,
      visitDurationMinutes: candidate.duration.inMinutes,
    );
  }
}

class VisitCandidate {
  final DateTime startedAt;
  final DateTime lastSeenAt;
  final double centerLatitude;
  final double centerLongitude;
  final int sampleCount;

  const VisitCandidate({
    required this.startedAt,
    required this.lastSeenAt,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.sampleCount,
  });

  Duration get duration => lastSeenAt.difference(startedAt);

  factory VisitCandidate.start(Position position, DateTime timestamp) {
    return VisitCandidate(
      startedAt: timestamp,
      lastSeenAt: timestamp,
      centerLatitude: position.latitude,
      centerLongitude: position.longitude,
      sampleCount: 1,
    );
  }

  VisitCandidate absorb(Position position, DateTime timestamp) {
    final nextCount = sampleCount + 1;
    return VisitCandidate(
      startedAt: startedAt,
      lastSeenAt: timestamp,
      centerLatitude:
          ((centerLatitude * sampleCount) + position.latitude) / nextCount,
      centerLongitude:
          ((centerLongitude * sampleCount) + position.longitude) / nextCount,
      sampleCount: nextCount,
    );
  }
}
