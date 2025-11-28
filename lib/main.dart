import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_log_app/providers/theme_provider.dart';
import 'package:quick_log_app/screens/main_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const QuickLogApp(),
    ),
  );
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
