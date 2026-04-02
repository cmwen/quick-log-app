import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quick_log_app/providers/auto_visit_provider.dart';
import 'package:quick_log_app/providers/settings_provider.dart';

class LocationTrackingProvider extends ChangeNotifier {
  static const String _latitudeKey = 'last_latitude';
  static const String _longitudeKey = 'last_longitude';
  static const String _locationLabelKey = 'last_location_label';
  static const String _updatedAtKey = 'last_location_updated_at';

  static const Duration _balancedInterval = Duration(minutes: 1);
  static const Duration _batterySaverInterval = Duration(minutes: 2);
  static const double _batterySaverDistanceFilter = 100;
  static const double _balancedDistanceFilter = 25;
  static const double _geocodeRefreshDistanceMeters = 250;
  static const Duration _geocodeRefreshWindow = Duration(minutes: 5);

  SettingsProvider? _settings;
  AutoVisitProvider? _autoVisitProvider;
  StreamSubscription<Position>? _positionSubscription;

  double? _latitude;
  double? _longitude;
  String? _locationLabel;
  DateTime? _lastUpdatedAt;
  bool _isRefreshing = false;
  bool _isTracking = false;
  String? _lastError;
  String _statusMessage = 'Location tracking is turned off.';

  double? _lastGeocodedLatitude;
  double? _lastGeocodedLongitude;
  DateTime? _lastGeocodedAt;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get locationLabel => _locationLabel;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  bool get isRefreshing => _isRefreshing;
  bool get isTracking => _isTracking;
  String? get lastError => _lastError;
  String get statusMessage => _statusMessage;
  bool get hasLocation => _latitude != null && _longitude != null;

  LocationTrackingProvider() {
    unawaited(_loadCachedLocation());
  }

  void updateSettings(SettingsProvider settings) {
    final shouldResync =
        _settings?.isLoaded != settings.isLoaded ||
        _settings?.locationEnabled != settings.locationEnabled ||
        _settings?.backgroundTrackingEnabled !=
            settings.backgroundTrackingEnabled ||
        _settings?.batterySaverEnabled != settings.batterySaverEnabled;

    _settings = settings;

    if (shouldResync) {
      unawaited(_syncTrackingWithSettings());
    }
  }

  void updateAutoVisitProvider(AutoVisitProvider provider) {
    _autoVisitProvider = provider;
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _latitude = prefs.getDouble(_latitudeKey);
    _longitude = prefs.getDouble(_longitudeKey);
    _locationLabel = prefs.getString(_locationLabelKey);

    final updatedAtMillis = prefs.getInt(_updatedAtKey);
    if (updatedAtMillis != null) {
      _lastUpdatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMillis);
      _lastGeocodedAt = _lastUpdatedAt;
      _lastGeocodedLatitude = _latitude;
      _lastGeocodedLongitude = _longitude;
    }

    if (hasLocation) {
      _statusMessage =
          'Using cached location until a fresh GPS fix is available.';
    }

    notifyListeners();
  }

  Future<void> _syncTrackingWithSettings() async {
    final settings = _settings;
    if (settings == null || !settings.isLoaded) {
      return;
    }

    if (!settings.locationEnabled) {
      await _stopTracking(clearLocation: true);
      _statusMessage = 'Location tracking is turned off.';
      _lastError = null;
      notifyListeners();
      return;
    }

    final permissionGranted = await _ensurePermission(
      requireBackground: settings.backgroundTrackingEnabled,
    );

    if (!permissionGranted) {
      await _stopTracking(clearLocation: false);
      notifyListeners();
      return;
    }

    await _startTracking();
  }

  Future<bool> requestTrackingPermission({
    bool requireBackground = false,
    bool openSettingsForBackground = false,
  }) async {
    final granted = await _ensurePermission(
      requireBackground: requireBackground,
      openSettingsForBackground: openSettingsForBackground,
    );

    if (granted && _settings?.locationEnabled == true) {
      await _startTracking();
    }

    notifyListeners();
    return granted;
  }

  Future<void> refreshLocation({bool promptForPermission = false}) async {
    final settings = _settings;
    if (settings == null || !settings.locationEnabled) {
      _lastError = 'Enable location tracking in Settings first.';
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    try {
      final permissionGranted = await _ensurePermission(
        requireBackground: settings.backgroundTrackingEnabled,
        openSettingsForBackground: promptForPermission,
      );

      if (!permissionGranted) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );

      await _handlePositionUpdate(position, forceGeocode: true);
      _statusMessage = settings.backgroundTrackingEnabled
          ? _batterySaverMessage(settings.batterySaverEnabled)
          : 'Tracking location while the app is open.';
    } catch (error) {
      _lastError = 'Unable to refresh location: $error';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _startTracking() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }

    final locationSettings = _buildLocationSettings();

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) => unawaited(_handlePositionUpdate(position)),
          onError: (Object error) {
            _isTracking = false;
            _lastError = 'Location updates stopped: $error';
            notifyListeners();
          },
        );

    _isTracking = true;
    _statusMessage = settings.backgroundTrackingEnabled
        ? _batterySaverMessage(settings.batterySaverEnabled)
        : 'Tracking location while the app is open.';
    notifyListeners();

    if (!hasLocation) {
      await refreshLocation();
    }
  }

  Future<void> _stopTracking({required bool clearLocation}) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;

    if (clearLocation) {
      _latitude = null;
      _longitude = null;
      _locationLabel = null;
      _lastUpdatedAt = null;
      _lastGeocodedLatitude = null;
      _lastGeocodedLongitude = null;
      _lastGeocodedAt = null;
      await _persistCachedLocation();
    }
  }

  Future<bool> _ensurePermission({
    required bool requireBackground,
    bool openSettingsForBackground = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _lastError = 'Location services are disabled on this device.';
      _statusMessage = 'Turn on Android location services to track position.';
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _lastError = 'Location permission was denied.';
      _statusMessage = 'Allow location access to use GPS features.';
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _lastError =
          'Location permission is permanently denied. Enable it in Android settings.';
      _statusMessage = 'Open Android settings to restore location access.';
      return false;
    }

    if (requireBackground && permission != LocationPermission.always) {
      _lastError =
          'Background tracking needs Android "Allow all the time" location access.';
      _statusMessage =
          'Grant "Allow all the time" in Android settings to keep tracking in the background.';
      if (openSettingsForBackground) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    _lastError = null;
    return true;
  }

  LocationSettings _buildLocationSettings() {
    final settings = _settings;
    final batterySaverEnabled = settings?.batterySaverEnabled ?? true;
    final backgroundTrackingEnabled =
        settings?.backgroundTrackingEnabled ?? false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: batterySaverEnabled
            ? LocationAccuracy.low
            : LocationAccuracy.medium,
        distanceFilter: batterySaverEnabled
            ? _batterySaverDistanceFilter.toInt()
            : _balancedDistanceFilter.toInt(),
        intervalDuration: batterySaverEnabled
            ? _batterySaverInterval
            : _balancedInterval,
        foregroundNotificationConfig: backgroundTrackingEnabled
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Quick Log is tracking location',
                notificationText:
                    'Background GPS is active. Disable it anytime in Settings.',
                enableWakeLock: false,
              )
            : null,
      );
    }

    return LocationSettings(
      accuracy: batterySaverEnabled
          ? LocationAccuracy.low
          : LocationAccuracy.medium,
      distanceFilter: batterySaverEnabled
          ? _batterySaverDistanceFilter.toInt()
          : _balancedDistanceFilter.toInt(),
    );
  }

  String _batterySaverMessage(bool batterySaverEnabled) {
    return batterySaverEnabled
        ? 'Background tracking is on with battery saver mode.'
        : 'Background tracking is on with balanced accuracy.';
  }

  Future<void> _handlePositionUpdate(
    Position position, {
    bool forceGeocode = false,
  }) async {
    _latitude = position.latitude;
    _longitude = position.longitude;
    _lastUpdatedAt = position.timestamp;

    if (forceGeocode || _shouldRefreshPlacemark(position)) {
      final resolvedLabel = await _resolveLocationLabel(position);
      if (resolvedLabel != null && resolvedLabel.isNotEmpty) {
        _locationLabel = resolvedLabel;
        _lastGeocodedLatitude = position.latitude;
        _lastGeocodedLongitude = position.longitude;
        _lastGeocodedAt = DateTime.now();
      }
    }

    await _persistCachedLocation();
    await _autoVisitProvider?.handlePosition(position);
    notifyListeners();
  }

  bool _shouldRefreshPlacemark(Position position) {
    if (_locationLabel == null || _lastGeocodedAt == null) {
      return true;
    }

    final timeSinceLastGeocode = DateTime.now().difference(_lastGeocodedAt!);
    if (timeSinceLastGeocode >= _geocodeRefreshWindow) {
      return true;
    }

    if (_lastGeocodedLatitude == null || _lastGeocodedLongitude == null) {
      return true;
    }

    final movedDistance = Geolocator.distanceBetween(
      _lastGeocodedLatitude!,
      _lastGeocodedLongitude!,
      position.latitude,
      position.longitude,
    );

    return movedDistance >= _geocodeRefreshDistanceMeters;
  }

  Future<String?> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return _locationLabel;
      }

      final place = placemarks.first;
      final parts = [place.name, place.locality]
          .where((part) => part != null && part.isNotEmpty)
          .cast<String>()
          .toList();

      return parts.isEmpty ? _locationLabel : parts.join(', ');
    } catch (_) {
      return _locationLabel;
    }
  }

  Future<void> _persistCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    if (_latitude == null || _longitude == null) {
      await prefs.remove(_latitudeKey);
      await prefs.remove(_longitudeKey);
      await prefs.remove(_locationLabelKey);
      await prefs.remove(_updatedAtKey);
      return;
    }

    await prefs.setDouble(_latitudeKey, _latitude!);
    await prefs.setDouble(_longitudeKey, _longitude!);
    if (_locationLabel != null && _locationLabel!.isNotEmpty) {
      await prefs.setString(_locationLabelKey, _locationLabel!);
    }
    if (_lastUpdatedAt != null) {
      await prefs.setInt(_updatedAtKey, _lastUpdatedAt!.millisecondsSinceEpoch);
    }
  }

  @override
  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    super.dispose();
  }
}
