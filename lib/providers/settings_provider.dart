import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _locationEnabledKey = 'location_enabled';
  static const String _backgroundTrackingEnabledKey =
      'background_tracking_enabled';
  static const String _batterySaverEnabledKey = 'battery_saver_enabled';
  static const String _travelModeEnabledKey = 'travel_mode_enabled';
  static const String _autoVisitLoggingEnabledKey =
      'auto_visit_logging_enabled';

  bool _locationEnabled = true;
  bool _backgroundTrackingEnabled = false;
  bool _batterySaverEnabled = true;
  bool _travelModeEnabled = false;
  bool _autoVisitLoggingEnabled = false;
  bool _isLoaded = false;

  bool get locationEnabled => _locationEnabled;
  bool get backgroundTrackingEnabled => _backgroundTrackingEnabled;
  bool get batterySaverEnabled => _batterySaverEnabled;
  bool get travelModeEnabled => _travelModeEnabled;
  bool get autoVisitLoggingEnabled => _autoVisitLoggingEnabled;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _locationEnabled = prefs.getBool(_locationEnabledKey) ?? true;
    _backgroundTrackingEnabled =
        prefs.getBool(_backgroundTrackingEnabledKey) ?? false;
    _batterySaverEnabled = prefs.getBool(_batterySaverEnabledKey) ?? true;
    _travelModeEnabled = prefs.getBool(_travelModeEnabledKey) ?? false;
    _autoVisitLoggingEnabled =
        prefs.getBool(_autoVisitLoggingEnabledKey) ?? false;
    _normalizeState();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocationEnabled(bool enabled) async {
    _locationEnabled = enabled;
    _normalizeState();
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setBackgroundTrackingEnabled(bool enabled) async {
    _backgroundTrackingEnabled = enabled;
    if (!enabled) {
      _travelModeEnabled = false;
      _autoVisitLoggingEnabled = false;
    }
    _normalizeState();
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setBatterySaverEnabled(bool enabled) async {
    _batterySaverEnabled = enabled;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setTravelModeEnabled(bool enabled) async {
    _travelModeEnabled = enabled;
    if (enabled) {
      _batterySaverEnabled = true;
    } else {
      _backgroundTrackingEnabled = false;
      _autoVisitLoggingEnabled = false;
    }
    _normalizeState();
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setAutoVisitLoggingEnabled(bool enabled) async {
    _autoVisitLoggingEnabled = enabled;
    if (enabled) {
      _batterySaverEnabled = true;
    } else {
      _travelModeEnabled = false;
    }
    _normalizeState();
    notifyListeners();
    await _persistSettings();
  }

  void _normalizeState() {
    if (!_locationEnabled) {
      _backgroundTrackingEnabled = false;
      _travelModeEnabled = false;
      _autoVisitLoggingEnabled = false;
      return;
    }

    if (_travelModeEnabled || _autoVisitLoggingEnabled) {
      _locationEnabled = true;
      _backgroundTrackingEnabled = true;
      _travelModeEnabled = true;
      _autoVisitLoggingEnabled = true;
      return;
    }

    if (!_backgroundTrackingEnabled) {
      _travelModeEnabled = false;
      _autoVisitLoggingEnabled = false;
    }
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, _locationEnabled);
    await prefs.setBool(
      _backgroundTrackingEnabledKey,
      _backgroundTrackingEnabled,
    );
    await prefs.setBool(_batterySaverEnabledKey, _batterySaverEnabled);
    await prefs.setBool(_travelModeEnabledKey, _travelModeEnabled);
    await prefs.setBool(_autoVisitLoggingEnabledKey, _autoVisitLoggingEnabled);
  }
}
