# Quick Log - Android App

Official website: https://cmwen.github.io/quick-log-app

An Android-first tag-based logging app for quick note-taking with smart tag suggestions, optional location tracking, map history, and local import/export. Built with Flutter.

## ✨ Features

- 🏷️ **Tag-First Logging**: Create entries by selecting tags first, then optionally adding notes
- 💡 **Smart Tag Suggestions**: Suggestions adapt to your time, day, and location patterns
- 🔎 **Searchable Tag Picker**: Browse, search, and filter tags by category
- 📍 **Optional Location Tracking**: Capture location labels and coordinates when enabled
- 🗺️ **Map View**: Review entries with location data on an interactive map
- 🧰 **Entry Management**: Filter, inspect, edit, and delete saved entries
- 📤 **Import / Export**: Export all data to JSON/CSV and import JSON backups
- ⚙️ **Settings**: Theme selection, location toggle, background tracking, and GPS battery saver
- 🗄️ **Local-Only Storage**: Entries and tags stay on-device in SQLite

## 🚀 Quick Start

### Prerequisites

- ✅ Flutter SDK 3.10.1+
- ✅ Dart 3.10.1+
- ✅ Java 17+
- ✅ Android SDK with API level 21+ (Android 5.0+)
- ✅ Android device or emulator

Verify setup: `flutter doctor -v && java -version`

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/cmwen/quick-log-app.git
cd quick-log-app

# Get dependencies
flutter pub get

# Verify everything works
flutter analyze
```

### 2. Run on Android

```bash
# Run on connected Android device or emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release
```

## 📱 Android Permissions

The app requires the following permissions:

| Permission | Purpose |
|------------|---------|
| `ACCESS_FINE_LOCATION` | Precise GPS location for entries and map data |
| `ACCESS_COARSE_LOCATION` | Lower-accuracy location fallback |
| `ACCESS_BACKGROUND_LOCATION` | Optional background tracking when enabled in Settings |
| `FOREGROUND_SERVICE` | Required for Android foreground tracking service |
| `FOREGROUND_SERVICE_LOCATION` | Required for foreground location updates on newer Android versions |
| `INTERNET` | Reverse geocoding and OpenStreetMap tiles |

The app works without location access, but map features and automatic location capture require permission. Background tracking only activates if you enable it in **Settings** and grant Android's **Allow all the time** location permission.

## 🏗️ Project Structure

```
├── lib/
│   ├── main.dart                   # App entry point
│   ├── data/
│   │   └── database_helper.dart    # SQLite database operations
│   ├── models/
│   │   ├── log_entry.dart          # Entry data model
│   │   └── log_tag.dart            # Tag data model
│   ├── providers/
│   │   ├── location_tracking_provider.dart
│   │   ├── settings_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── main_screen.dart        # Record screen with suggestions
│   │   ├── entries_screen.dart     # View, filter, edit, delete entries
│   │   ├── tags_screen.dart        # Manage tags
│   │   ├── map_screen.dart         # Location history map
│   │   └── settings_screen.dart    # Theme, privacy, export/import
│   ├── services/
│   │   ├── data_export_service.dart
│   │   └── tag_suggestion_service.dart
│   └── widgets/
│       └── tag_chip.dart           # Reusable tag widget
├── android/                   # Android platform configuration
├── test/                      # Unit and widget tests
└── pubspec.yaml              # Dependencies
```

## ⚡ Build Performance

Optimized for fast Android builds:

- **Java 17** baseline for modern Android development
- **Parallel Gradle builds** with 4 workers (local)
- **R8 code shrinking**: 40-60% smaller release APKs
- **Build caching** enabled for faster incremental builds

### Expected Build Times

| Build Type | Time |
|------------|------|
| Debug APK (cached) | 30-60s |
| Release APK | 1-2 min |
| App Bundle | 1-2 min |

## 🔄 CI/CD Workflows

### Automated Workflows

- **build.yml**: Tests, lints, builds APK on every push
- **release.yml**: Signed releases on version tags
- **pre-release.yml**: Manual beta/alpha releases

### Setup Signed Releases

```bash
# 1. Generate keystore
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# 2. Add GitHub Secrets
- ANDROID_KEYSTORE_BASE64: `base64 -i release.jks`
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS: release
- ANDROID_KEY_PASSWORD

# 3. Tag and push
git tag v1.0.0 && git push --tags
```

## 📚 Documentation

- [QUICK_LOG_README.md](QUICK_LOG_README.md) - Detailed user guide and feature walkthrough
- [GETTING_STARTED.md](GETTING_STARTED.md) - Detailed setup guide
- [APP_CUSTOMIZATION.md](APP_CUSTOMIZATION.md) - Customization options
- [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Build performance details
- [TESTING.md](TESTING.md) - Testing guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

## 🛠️ Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | App settings and theme state |
| `sqflite` | Local SQLite database |
| `path_provider` / `path` | Local file and database paths |
| `geolocator` | GPS location services and background updates |
| `geocoding` | Reverse geocoding for human-readable locations |
| `flutter_map` / `latlong2` | Map rendering with OpenStreetMap |
| `share_plus` / `file_picker` | Exporting and importing app data |
| `shared_preferences` | Persisting settings |
| `package_info_plus` | App version display |
| `intl` | Date/time formatting |
| `flutter_chips_input` | Tag selection UI |

## 🤖 AI-Powered Development

This project includes 6 specialized AI agents for VS Code:

| Agent | Purpose |
|-------|---------|
| **@product-owner** | Define features & requirements |
| **@experience-designer** | Design UX & user flows |
| **@architect** | Plan technical architecture |
| **@researcher** | Find packages & best practices |
| **@flutter-developer** | Implement features & fix bugs |
| **@doc-writer** | Write documentation |

## Troubleshooting

### App not opening on device

1. **Check Flutter installation**: `flutter doctor -v`
2. **Verify Android SDK**: Ensure API level 21+ is installed
3. **Check device connection**: `flutter devices`
4. **Enable USB debugging** on your Android device
5. **Run in verbose mode**: `flutter run -v`

### Location not working

1. **Grant location permissions** when prompted
2. **Enable location services** on the device
3. **Check GPS availability**: Some emulators need location simulation

### Build failures

1. **Clean and rebuild**: `flutter clean && flutter pub get && flutter build apk`
2. **Check Java version**: Must be Java 17+
3. **Update Gradle**: Check `android/gradle/wrapper/gradle-wrapper.properties`

## License

MIT License - see [LICENSE](LICENSE)
