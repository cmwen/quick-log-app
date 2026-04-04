import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:quick_log_app/services/android_travel_capture_service.dart';

class TravelMediaProvider extends ChangeNotifier {
  SettingsProvider? _settings;
  AndroidTravelCaptureStatus _status = AndroidTravelCaptureStatus.unsupported();
  bool _isBusy = false;
  bool? _lastDesiredMonitoringState;

  AndroidTravelCaptureStatus get status => _status;
  bool get isBusy => _isBusy;

  String get statusMessage {
    final settings = _settings;
    if (!_status.supported) {
      return _status.statusMessage;
    }
    if (settings == null || !settings.isLoaded) {
      return 'Loading photo-triggered travel log status...';
    }
    if (!settings.travelModeEnabled) {
      return 'Enable Travel Mode to watch for new photos.';
    }
    if (!settings.photoTravelLoggingEnabled) {
      return 'Photo-triggered travel logs are off.';
    }
    if (!_status.permissionGranted) {
      return 'Allow ${_status.permissionLabel} access so Quick Log can detect new photos.';
    }
    return _status.lastEventMessage ?? _status.statusMessage;
  }

  void updateSettings(SettingsProvider settings) {
    final shouldRefresh =
        _settings?.isLoaded != settings.isLoaded ||
        _settings?.travelModeEnabled != settings.travelModeEnabled ||
        _settings?.photoTravelLoggingEnabled !=
            settings.photoTravelLoggingEnabled;

    _settings = settings;

    if (shouldRefresh) {
      unawaited(_syncWithSettings());
    }
  }

  Future<void> refreshStatus() async {
    _status = await AndroidTravelCaptureService.instance.getStatus();
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    _isBusy = true;
    notifyListeners();

    try {
      _status = await AndroidTravelCaptureService.instance.requestPermission();
      return _status.permissionGranted;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncWithSettings() async {
    final settings = _settings;
    if (settings == null || !settings.isLoaded) {
      return;
    }

    final shouldMonitor =
        defaultTargetPlatform == TargetPlatform.android &&
        settings.travelModeEnabled &&
        settings.photoTravelLoggingEnabled;

    if (_lastDesiredMonitoringState == shouldMonitor && _status.supported) {
      _status = await AndroidTravelCaptureService.instance.getStatus();
      notifyListeners();
      return;
    }

    _lastDesiredMonitoringState = shouldMonitor;
    _status = await AndroidTravelCaptureService.instance.setMonitoringEnabled(
      shouldMonitor,
    );
    notifyListeners();
  }
}
