import 'package:flutter_test/flutter_test.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsProvider> createProvider({
    Map<String, Object> initialValues = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final provider = SettingsProvider();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return provider;
  }

  group('SettingsProvider', () {
    test(
      'travel mode enables bundled automatic capture with battery saver',
      () async {
        final provider = await createProvider();

        await provider.setTravelModeEnabled(true);

        expect(provider.locationEnabled, isTrue);
        expect(provider.backgroundTrackingEnabled, isTrue);
        expect(provider.travelModeEnabled, isTrue);
        expect(provider.autoVisitLoggingEnabled, isTrue);
        expect(provider.batterySaverEnabled, isTrue);
      },
    );

    test(
      'disabling travel mode turns off auto-capture parts but keeps location on',
      () async {
        final provider = await createProvider();

        await provider.setTravelModeEnabled(true);
        await provider.setTravelModeEnabled(false);

        expect(provider.locationEnabled, isTrue);
        expect(provider.backgroundTrackingEnabled, isFalse);
        expect(provider.travelModeEnabled, isFalse);
        expect(provider.autoVisitLoggingEnabled, isFalse);
      },
    );

    test(
      'turning off background tracking also turns off travel capture bundle',
      () async {
        final provider = await createProvider();

        await provider.setTravelModeEnabled(true);
        await provider.setBackgroundTrackingEnabled(false);

        expect(provider.backgroundTrackingEnabled, isFalse);
        expect(provider.travelModeEnabled, isFalse);
        expect(provider.autoVisitLoggingEnabled, isFalse);
      },
    );
  });
}
