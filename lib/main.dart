import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_log_app/providers/auto_visit_provider.dart';
import 'package:quick_log_app/providers/location_tracking_provider.dart';
import 'package:quick_log_app/providers/theme_provider.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:quick_log_app/providers/travel_media_provider.dart';
import 'package:quick_log_app/screens/main_screen.dart';
import 'package:quick_log_app/services/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialLaunchAction = await QuickLogHomeWidgetService.instance
      .consumeLaunchAction();
  runApp(QuickLogRoot(initialLaunchAction: initialLaunchAction));
}

class QuickLogRoot extends StatelessWidget {
  const QuickLogRoot({super.key, this.initialLaunchAction});

  final WidgetLaunchAction? initialLaunchAction;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, AutoVisitProvider>(
          create: (_) => AutoVisitProvider(),
          update: (_, settingsProvider, autoVisitProvider) {
            final provider = autoVisitProvider ?? AutoVisitProvider();
            provider.updateSettings(settingsProvider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<SettingsProvider, TravelMediaProvider>(
          create: (_) => TravelMediaProvider(),
          update: (_, settingsProvider, travelMediaProvider) {
            final provider = travelMediaProvider ?? TravelMediaProvider();
            provider.updateSettings(settingsProvider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<SettingsProvider, LocationTrackingProvider>(
          create: (_) => LocationTrackingProvider(),
          update: (context, settingsProvider, locationProvider) {
            final provider = locationProvider ?? LocationTrackingProvider();
            provider.updateSettings(settingsProvider);
            provider.updateAutoVisitProvider(context.read<AutoVisitProvider>());
            return provider;
          },
        ),
      ],
      child: QuickLogApp(initialLaunchAction: initialLaunchAction),
    );
  }
}

/// Quick Log - A tag-first logging application
class QuickLogApp extends StatelessWidget {
  const QuickLogApp({super.key, this.initialLaunchAction});

  final WidgetLaunchAction? initialLaunchAction;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final fallbackLight = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        );
        final fallbackDark = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          title: 'Quick Log',
          theme: ThemeData(
            colorScheme: lightDynamic?.harmonized() ?? fallbackLight,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic?.harmonized() ?? fallbackDark,
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          home: MainScreen(initialLaunchAction: initialLaunchAction),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
