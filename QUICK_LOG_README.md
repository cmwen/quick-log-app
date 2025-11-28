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
- **Entry Management** - View, filter, and delete past entries with swipe actions
- **Tag Management** - Add custom tags and view usage statistics

### Map & Location
- **Map View** - Interactive OpenStreetMap showing all logged locations
- **Location Markers** - Tap markers to view entry details
- **Automatic Location** - GPS capture with reverse geocoding

### Data Management
- **Export to JSON** - Full data export in LLM-friendly format
- **Export to CSV** - Spreadsheet-compatible export
- **Import from JSON** - Restore entries from backup
- **Share Data** - Share exports via system share sheet

### Settings & Customization
- **Theme Selection** - Choose System, Light, or Dark theme
- **Persistent Settings** - Preferences saved across sessions
- **Custom App Icon** - Blue-themed branded icon

### User Experience
- **Material Design 3** - Modern, beautiful UI
- **Dark Mode** - Theme switching based on preference or system
- **Swipe Actions** - Swipe left to delete, right to edit entries
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
4. **Swipe left** on an entry to delete it
5. **Swipe right** on an entry to edit it

### Using the Map View

1. Navigate to the **Map** tab (or tap the map icon)
2. View all logged locations as markers on the map
3. Tap a marker to see entry details in a popup
4. Use pinch gestures to zoom in/out

### Exporting Data

1. Navigate to the **Settings** tab
2. Choose export format:
   - **Export JSON** - Complete data backup (recommended for restore)
   - **Export CSV** - Spreadsheet-compatible format
3. Use the share sheet to save or send the file

### Importing Data

1. Navigate to the **Settings** tab
2. Tap **Import JSON**
3. Select a previously exported JSON file
4. Entries will be merged with existing data

### Changing Theme

1. Navigate to the **Settings** tab
2. Under **Theme**, select:
   - **System** - Follow device dark/light mode
   - **Light** - Always use light theme
   - **Dark** - Always use dark theme
3. Changes apply immediately and persist

## 🏗️ Architecture

### Tech Stack

- **Framework**: Flutter 3.10.1+
- **Language**: Dart 3.10.1+
- **Database**: SQLite (sqflite)
- **Location**: Geolocator + Geocoding
- **Maps**: flutter_map with OpenStreetMap
- **Export/Import**: share_plus, file_picker
- **Settings**: shared_preferences
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
├── providers/
│   └── theme_provider.dart   # Theme state management
├── screens/
│   ├── main_screen.dart      # Entry creation screen
│   ├── entries_screen.dart   # Entry list with swipe actions
│   ├── tags_screen.dart      # Tag management
│   ├── map_screen.dart       # Map view with markers
│   └── settings_screen.dart  # Theme & export settings
├── services/
│   └── export_service.dart   # JSON/CSV export logic
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

### Phase 1 ✅ Complete
- [x] Core entry creation with tags
- [x] Location tracking
- [x] Entry management
- [x] Tag management
- [x] Material Design 3 UI

### Phase 2 ✅ Complete
- [x] Custom app icon (blue theme)
- [x] Map visualization of logged locations
- [x] Export to JSON/CSV
- [x] Import from JSON
- [x] Settings screen with theme selection
- [x] Swipe actions (edit/delete entries)

### Phase 3 (Planned)
- [ ] Search and advanced filtering
- [ ] Statistics and insights
- [ ] Tag relationship suggestions
- [ ] Date range filtering

### Phase 4 (Future)
- [ ] Data backup/restore to cloud
- [ ] Widgets for quick logging
- [ ] Custom color themes

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
  - flutter_map - OpenStreetMap integration
  - latlong2 - Coordinate handling
  - share_plus - Share functionality
  - file_picker - File selection
  - shared_preferences - Settings persistence
  - intl - Date formatting
  - provider - State management
  - flutter_launcher_icons - App icon generation

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/quick-log-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/quick-log-app/discussions)
- **Email**: your.email@example.com

## 📊 Status

- **Version**: 1.0.0+1
- **Status**: Release - All planned features complete
- **Platform**: Android ✅

---

Made with ❤️ using Flutter
