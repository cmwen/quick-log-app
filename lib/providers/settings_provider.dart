import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _locationEnabledKey = 'location_enabled';
  static const String _backgroundTrackingEnabledKey =
      'background_tracking_enabled';
  static const String _batterySaverEnabledKey = 'battery_saver_enabled';

  bool _locationEnabled = true;
  bool _backgroundTrackingEnabled = false;
  bool _batterySaverEnabled = true;
  bool _isLoaded = false;

  bool get locationEnabled => _locationEnabled;
  bool get backgroundTrackingEnabled => _backgroundTrackingEnabled;
  bool get batterySaverEnabled => _batterySaverEnabled;
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
    if (!_locationEnabled) {
      _backgroundTrackingEnabled = false;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocationEnabled(bool enabled) async {
    _locationEnabled = enabled;
    if (!enabled) {
      _backgroundTrackingEnabled = false;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, enabled);
    if (!enabled) {
      await prefs.setBool(_backgroundTrackingEnabledKey, false);
    }
  }

  Future<void> setBackgroundTrackingEnabled(bool enabled) async {
    _backgroundTrackingEnabled = enabled;
    if (enabled) {
      _locationEnabled = true;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundTrackingEnabledKey, enabled);
    if (enabled) {
      await prefs.setBool(_locationEnabledKey, true);
    }
  }

  Future<void> setBatterySaverEnabled(bool enabled) async {
    _batterySaverEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_batterySaverEnabledKey, enabled);
  }
}
