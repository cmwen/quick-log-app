import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _locationEnabledKey = 'location_enabled';
  bool _locationEnabled = true;

  bool get locationEnabled => _locationEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _locationEnabled = prefs.getBool(_locationEnabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setLocationEnabled(bool enabled) async {
    _locationEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationEnabledKey, enabled);
  }
}
