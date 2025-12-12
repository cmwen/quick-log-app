# Quick Log - Android App

Official website: https://cmwen.github.io/quick-log-app

An Android-only tag-first logging application for quick note-taking with location tracking. Built with Flutter for optimal Android performance.

## ✨ Features

- 🏷️ **Tag-First Logging**: Quickly categorize entries with customizable tags
- 📍 **Location Tracking**: Automatic GPS location capture with geocoding
- 📝 **Optional Notes**: Add detailed notes to any entry
- 🗄️ **Local Database**: All data stored securely on-device with SQLite
- 🎨 **Material Design 3**: Beautiful, modern Android UI
- 🌙 **Dark Mode**: Automatic theme switching based on system settings

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
| `ACCESS_FINE_LOCATION` | GPS location for accurate tracking |
| `ACCESS_COARSE_LOCATION` | Network-based location fallback |
| `INTERNET` | Geocoding service for location names |

Users will be prompted to grant location permissions on first use.

## 🏗️ Project Structure

```
├── lib/
│   ├── main.dart              # App entry point
│   ├── data/
│   │   └── database_helper.dart  # SQLite database operations
│   ├── models/
│   │   ├── log_entry.dart     # Entry data model
│   │   └── log_tag.dart       # Tag data model
│   ├── screens/
│   │   ├── main_screen.dart   # Main logging screen
│   │   ├── entries_screen.dart # View past entries
│   │   └── tags_screen.dart   # Manage tags
│   └── widgets/
│       └── tag_chip.dart      # Reusable tag widget
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

- [GETTING_STARTED.md](GETTING_STARTED.md) - Detailed setup guide
- [APP_CUSTOMIZATION.md](APP_CUSTOMIZATION.md) - Customization options
- [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Build performance details
- [TESTING.md](TESTING.md) - Testing guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

## 🛠️ Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `sqflite` | Local SQLite database |
| `path_provider` | File system paths |
| `geolocator` | GPS location services |
| `geocoding` | Reverse geocoding |
| `intl` | Date/time formatting |
| `flutter_chips_input` | Tag input UI |

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
