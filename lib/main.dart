import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_log_app/providers/location_tracking_provider.dart';
import 'package:quick_log_app/providers/theme_provider.dart';
import 'package:quick_log_app/providers/settings_provider.dart';
import 'package:quick_log_app/screens/main_screen.dart';

void main() {
  runApp(const QuickLogRoot());
}

class QuickLogRoot extends StatelessWidget {
  const QuickLogRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, LocationTrackingProvider>(
          create: (_) => LocationTrackingProvider(),
          update: (_, settingsProvider, locationProvider) {
            final provider = locationProvider ?? LocationTrackingProvider();
            provider.updateSettings(settingsProvider);
            return provider;
          },
        ),
      ],
      child: const QuickLogApp(),
    );
  }
}

/// Quick Log - A tag-first logging application
class QuickLogApp extends StatelessWidget {
  const QuickLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Quick Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
