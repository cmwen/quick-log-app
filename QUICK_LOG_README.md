# Quick Log 📝

A tag-first logging Android application for quick note-taking with automatic location tracking.

![Platform](https://img.shields.io/badge/platform-Android-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.10.1+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### Core Functionality
- **Tag-First Approach** - Select tags before writing, emphasizing quick categorization
- **Smart Tag System** - Pre-populated tags across 5 categories (Activity, Location, Mood, People, Custom)
- **Automatic Location Tracking** - GPS coordinates and geocoded address capture
- **Quick Entry Creation** - Minimal friction for fast logging
- **Entry Management** - View, filter, and delete past entries
- **Tag Management** - Add custom tags and view usage statistics

### User Experience
- **Material Design 3** - Modern, beautiful UI
- **Dark Mode** - Automatic theme switching based on system preferences
- **Offline First** - All data stored locally with SQLite
- **No Login Required** - Privacy-focused, local-only storage
- **Fast & Lightweight** - Optimized performance

## 📱 Screenshots

*Note: Screenshots to be added after icon is finalized*

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart 3.10.1 or higher
- Android Studio / VS Code with Flutter extensions
- Android SDK API 21+ (Android 5.0+)
- Java 17+

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/cmwen/quick-log-app.git
cd quick-log-app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# Run on connected device/emulator
flutter run

# Or run in release mode
flutter run --release
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

## 📖 How to Use

### Creating a Log Entry

1. **Select Tags** - Tap on tag chips to select categories (Activity, Mood, Location, People)
2. **Add Note (Optional)** - Write additional context in the note field
3. **Location** - Location is captured automatically (if permitted)
4. **Save** - Tap "Save Entry" to log your entry

### Managing Tags

1. Navigate to the **Tags** tab
2. Filter by category using the category chips
3. Tap **+** button to add custom tags
4. View usage statistics for each tag
5. Delete unused tags by tapping the delete icon

### Viewing Entries

1. Navigate to the **Entries** tab
2. Tap any entry to view full details
3. Pull down to refresh the list
4. Tap the more icon to delete an entry

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.10.1+
- **Language**: Dart 3.10.1+
- **Database**: SQLite (sqflite)
- **Location**: Geolocator + Geocoding
- **State Management**: StatefulWidget (can be upgraded to Provider/Riverpod)
- **UI**: Material Design 3

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── data/
│   └── database_helper.dart  # SQLite database operations
├── models/
│   ├── log_entry.dart        # Entry data model
│   └── log_tag.dart          # Tag data model & categories
├── screens/
│   ├── main_screen.dart      # Entry creation screen
│   ├── entries_screen.dart   # Entry list & details
│   └── tags_screen.dart      # Tag management
└── widgets/
    └── tag_chip.dart         # Reusable tag chip widget
```

### Data Models

**LogEntry**
```dart
- id: int?
- createdAt: DateTime
- note: String?
- tags: List<String>
- latitude: double?
- longitude: double?
- locationLabel: String?
```

**LogTag**
```dart
- id: String
- label: String
- category: TagCategory (Activity, Location, Mood, People, Custom)
- usageCount: int
```

## 🎨 Design Philosophy

1. **Tag-First** - Tags are the primary way to categorize entries, not an afterthought
2. **Speed** - Creating an entry should take seconds, not minutes
3. **Context** - Location and time are captured automatically
4. **Privacy** - All data stays on your device
5. **Simplicity** - Clean, minimal UI focused on the essentials

## 🔒 Privacy & Permissions

### Required Permissions

- **Location (Android/iOS)** - To capture where entries are created
  - Can be denied; app will work without location tracking
  - Location data never leaves your device

### Data Storage

- All data stored locally in SQLite database
- No cloud sync or external servers
- No analytics or tracking
- No account or login required

## 🛣️ Roadmap

### Phase 1 (Current) ✅
- [x] Core entry creation with tags
- [x] Location tracking
- [x] Entry management
- [x] Tag management
- [x] Material Design 3 UI

### Phase 2 (Planned)
- [ ] Map visualization of logged locations
- [ ] Export to JSON/CSV
- [ ] Search and advanced filtering
- [ ] Statistics and insights
- [ ] Custom app icon

### Phase 3 (Future)
- [ ] Tag relationship suggestions
- [ ] Data backup/restore
- [ ] Widgets for quick logging

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- Open source community for packages used:
  - sqflite - SQLite database
  - geolocator - Location services
  - geocoding - Reverse geocoding
  - intl - Date formatting
  - provider - State management

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/quick-log-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/quick-log-app/discussions)
- **Email**: your.email@example.com

## 📊 Status

- **Version**: 1.0.0+1
- **Status**: Beta - Core features complete
- **Platform**: Android ✅

---

Made with ❤️ using Flutter
