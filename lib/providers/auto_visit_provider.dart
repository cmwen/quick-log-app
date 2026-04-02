import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quick_log_app/data/database_helper.dart';
import 'package:quick_log_app/models/log_entry.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:quick_log_app/services/visit_detection_service.dart';

class AutoVisitProvider extends ChangeNotifier {
  final VisitDetectionService _visitDetectionService = VisitDetectionService();

  SettingsProvider? _settings;
  VisitCandidate? _candidate;
  LogEntry? _lastAutoLoggedVisit;
  bool _isEnabled = false;
  String _statusMessage = 'Auto-logging is off.';
  String? _lastError;

  bool get isEnabled => _isEnabled;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;
  VisitCandidate? get candidate => _candidate;

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    _isEnabled =
        settings.isLoaded &&
        settings.locationEnabled &&
        settings.backgroundTrackingEnabled &&
        settings.autoVisitLoggingEnabled;
    _statusMessage = _isEnabled
        ? (settings.travelModeEnabled
              ? 'Travel mode is watching for meaningful stops.'
              : 'Auto-logging is watching for dwell-based stops.')
        : 'Auto-logging is off.';
    notifyListeners();
  }

  Future<void> handlePosition(Position position) async {
    final settings = _settings;
    if (!_isEnabled || settings == null) {
      return;
    }

    try {
      _candidate = _visitDetectionService.updateCandidate(
        candidate: _candidate,
        position: position,
        travelModeEnabled: settings.travelModeEnabled,
      );

      if (_candidate == null) {
        return;
      }

      _lastAutoLoggedVisit ??= await DatabaseHelper.instance
          .getLatestAutoVisitEntry();
      final label = await _resolveLocationLabel(_candidate!);
      final nextEntry = _visitDetectionService.buildAutoVisitEntry(
        candidate: _candidate!,
        locationLabel: label,
        latestLoggedVisit: _lastAutoLoggedVisit,
      );

      if (nextEntry == null) {
        _statusMessage = settings.travelModeEnabled
            ? 'Travel mode is learning your current stop.'
            : 'Watching for longer stops before auto-saving.';
        notifyListeners();
        return;
      }

      final id = await DatabaseHelper.instance.insertEntry(nextEntry);
      _lastAutoLoggedVisit = nextEntry.copyWith(id: id);
      _candidate = null;
      _lastError = null;
      _statusMessage = nextEntry.locationLabel != null
          ? 'Logged ${nextEntry.locationLabel} automatically.'
          : 'Logged a new visit automatically.';
      notifyListeners();
    } catch (error) {
      _lastError = 'Auto-log failed: $error';
      notifyListeners();
    }
  }

  Future<String?> _resolveLocationLabel(VisitCandidate candidate) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        candidate.centerLatitude,
        candidate.centerLongitude,
      );
      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.name != null && place.name!.isNotEmpty) place.name!,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality!,
      ];
      if (parts.isEmpty) {
        return null;
      }
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
