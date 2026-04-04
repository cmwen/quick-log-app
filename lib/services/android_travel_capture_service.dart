import 'dart:io';

import 'package:flutter/services.dart';

class AndroidTravelCaptureStatus {
  final bool supported;
  final bool permissionGranted;
  final bool monitoringRequested;
  final bool monitoringActive;
  final String permissionLabel;
  final String statusMessage;
  final String? lastEventMessage;
  final DateTime? lastEventAt;

  const AndroidTravelCaptureStatus({
    required this.supported,
    required this.permissionGranted,
    required this.monitoringRequested,
    required this.monitoringActive,
    required this.permissionLabel,
    required this.statusMessage,
    this.lastEventMessage,
    this.lastEventAt,
  });

  factory AndroidTravelCaptureStatus.unsupported() {
    return const AndroidTravelCaptureStatus(
      supported: false,
      permissionGranted: false,
      monitoringRequested: false,
      monitoringActive: false,
      permissionLabel: 'Photos and videos',
      statusMessage:
          'Photo-triggered travel logs are available on Android only.',
    );
  }

  factory AndroidTravelCaptureStatus.fromMap(Map<Object?, Object?> raw) {
    final lastEventAtMillis = raw['lastEventAt'] as int?;

    return AndroidTravelCaptureStatus(
      supported: raw['supported'] as bool? ?? true,
      permissionGranted: raw['permissionGranted'] as bool? ?? false,
      monitoringRequested: raw['monitoringRequested'] as bool? ?? false,
      monitoringActive: raw['monitoringActive'] as bool? ?? false,
      permissionLabel: raw['permissionLabel'] as String? ?? 'Photos and videos',
      statusMessage: raw['statusMessage'] as String? ?? 'Status unavailable.',
      lastEventMessage: raw['lastEventMessage'] as String?,
      lastEventAt: lastEventAtMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastEventAtMillis),
    );
  }
}

class AndroidTravelCaptureService {
  AndroidTravelCaptureService._();

  static final AndroidTravelCaptureService instance =
      AndroidTravelCaptureService._();

  static const MethodChannel _channel = MethodChannel(
    'quick_log_app/travel_capture',
  );

  Future<AndroidTravelCaptureStatus> getStatus() async {
    if (!Platform.isAndroid) {
      return AndroidTravelCaptureStatus.unsupported();
    }

    try {
      final rawStatus = await _channel.invokeMethod<Object?>('getStatus');
      if (rawStatus is Map<Object?, Object?>) {
        return AndroidTravelCaptureStatus.fromMap(rawStatus);
      }
    } on MissingPluginException {
      return AndroidTravelCaptureStatus.unsupported();
    }

    return AndroidTravelCaptureStatus.unsupported();
  }

  Future<AndroidTravelCaptureStatus> requestPermission() async {
    if (!Platform.isAndroid) {
      return AndroidTravelCaptureStatus.unsupported();
    }

    try {
      final rawStatus = await _channel.invokeMethod<Object?>(
        'requestPermission',
      );
      if (rawStatus is Map<Object?, Object?>) {
        return AndroidTravelCaptureStatus.fromMap(rawStatus);
      }
    } on MissingPluginException {
      return AndroidTravelCaptureStatus.unsupported();
    }

    return AndroidTravelCaptureStatus.unsupported();
  }

  Future<AndroidTravelCaptureStatus> setMonitoringEnabled(bool enabled) async {
    if (!Platform.isAndroid) {
      return AndroidTravelCaptureStatus.unsupported();
    }

    try {
      final rawStatus = await _channel.invokeMethod<Object?>(
        'setMonitoringEnabled',
        <String, Object?>{'enabled': enabled},
      );
      if (rawStatus is Map<Object?, Object?>) {
        return AndroidTravelCaptureStatus.fromMap(rawStatus);
      }
    } on MissingPluginException {
      return AndroidTravelCaptureStatus.unsupported();
    }

    return AndroidTravelCaptureStatus.unsupported();
  }
}
