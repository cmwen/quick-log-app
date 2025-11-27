# App Customization Guide (Android)

This guide provides a comprehensive checklist and AI prompts for customizing the Quick Log app for your specific needs.

## 📝 Complete Customization Checklist

### Phase 1: Identity and Branding

- [ ] **App Name**
  - [ ] `pubspec.yaml` - name field
  - [ ] `lib/main.dart` - MaterialApp title
  - [ ] `android/app/src/main/AndroidManifest.xml` - android:label

- [ ] **Package Identifier**
  - [ ] `android/app/build.gradle.kts` - namespace and applicationId
  
- [ ] **Description**
  - [ ] `pubspec.yaml` - description field
  - [ ] `README.md` - project description

### Phase 2: Visual Identity

- [ ] **App Icon**
  - [ ] Create 1024×1024 master icon
  - [ ] Android: `android/app/src/main/res/mipmap-*`
    - mdpi: 48×48
    - hdpi: 72×72
    - xhdpi: 96×96
    - xxhdpi: 144×144
    - xxxhdpi: 192×192

- [ ] **Color Theme**
  - [ ] `lib/main.dart` - MaterialApp theme
  - [ ] Primary color (seedColor)
  - [ ] Dark mode theme

- [ ] **Splash Screen** (Optional)
  - [ ] Use flutter_native_splash package
  - [ ] Configure in `pubspec.yaml`

### Phase 3: Configuration

- [ ] **Repository Setup**
  - [ ] GitHub repository URL
  - [ ] Update git remote
  - [ ] README.md - repository links

- [ ] **GitHub Secrets** (for CI/CD)
  - [ ] `ANDROID_KEYSTORE_BASE64`
  - [ ] `ANDROID_KEYSTORE_PASSWORD`
  - [ ] `ANDROID_KEY_ALIAS`
  - [ ] `ANDROID_KEY_PASSWORD`
  - [ ] `CODECOV_TOKEN` (optional)

- [ ] **Version Management**
  - [ ] `pubspec.yaml` - version: 1.0.0+1
  - [ ] Plan version numbering strategy

### Phase 4: Feature Planning

- [ ] **Define Core Features**
  - [ ] User stories with @product-owner
  - [ ] Feature prioritization
  - [ ] MVP scope

- [ ] **Design User Experience**
  - [ ] User flows with @experience-designer
  - [ ] Screen designs
  - [ ] Navigation structure

- [ ] **Technical Architecture**
  - [ ] State management (Provider, Riverpod, Bloc)
  - [ ] Data persistence (sqflite, hive, isar)
  - [ ] API integration architecture

## 🤖 AI Prompts for Customization

### Step 1: Rename App

```
@flutter-developer Please rename this Flutter Android app:
- Current name: "quick_log_app"
- New name: "my_app_name"
- Current package: "com.cmwen.quick_log_app"
- New package: "com.mycompany.my_app"

Update all necessary files including:
- pubspec.yaml
- lib/main.dart (imports and title)
- test/widget_test.dart (imports)
- android/app/build.gradle.kts (namespace and applicationId)
- android/app/src/main/AndroidManifest.xml (label)

After updating, run `flutter pub get` and verify everything compiles.
```

### Step 2: Generate App Icon

```
@icon-generation.prompt.md

Create an app launcher icon for my [TYPE OF APP] app.

Requirements:
- App concept: [DESCRIBE YOUR APP]
- Style: [flat/gradient/minimal/modern]
- Primary color: #[HEX CODE]
- Symbol/concept: [DESCRIBE ICON CONCEPT]

Please provide:
1. A 1024×1024 PNG master icon
2. Instructions for using flutter_launcher_icons package for Android
3. Alt text for accessibility

Save the master icon to `assets/icon/app_icon.png`.
```

### Step 3: Customize Theme

```
@flutter-developer Please customize the app theme in lib/main.dart:

Brand colors:
- Primary: #[HEX] ([COLOR NAME])
- Secondary: #[HEX] ([COLOR NAME])
- Background: #[HEX]

Requirements:
- Use Material Design 3
- Support dark mode
- Use ColorScheme.fromSeed for consistency
```

### Step 4: Add New Feature

```
@flutter-developer Implement [FEATURE NAME] feature:

Requirements:
- [REQUIREMENT 1]
- [REQUIREMENT 2]
- [REQUIREMENT 3]

Technical approach:
- Create models in lib/models/
- Implement UI in lib/screens/[feature_name]/
- Add database operations in lib/data/database_helper.dart

After implementation:
1. Write unit tests
2. Run `dart format .`
3. Run `flutter analyze`
4. Run `flutter test`
```

## 🔍 Verification Checklist

After customization, verify:

### Build Verification
```bash
# Clean start
flutter clean
flutter pub get

# Check for issues
flutter analyze
dart format --set-exit-if-changed .

# Run tests
flutter test

# Build Android
flutter build apk --release
flutter build appbundle --release
```

### Visual Verification
- [ ] App icon shows correctly in launcher
- [ ] App name displays correctly in app drawer
- [ ] Theme colors match brand
- [ ] Dark mode works correctly

### Functional Verification
- [ ] App launches without errors
- [ ] Navigation works correctly
- [ ] Location permissions prompt works
- [ ] Tags can be created and selected
- [ ] Entries are saved correctly
- [ ] All imports reference correct package name

## 📦 Recommended Dependencies

### Essential Packages
```yaml
dependencies:
  # State Management
  provider: ^6.1.1              # Already included
  
  # Local Storage
  sqflite: ^2.3.0               # Already included
  path_provider: ^2.1.1         # Already included
  
  # Location
  geolocator: ^10.1.0           # Already included
  geocoding: ^2.1.1             # Already included
  
  # Date/Time
  intl: ^0.19.0                 # Already included
  
  # UI Components
  flutter_chips_input: ^2.0.0   # Already included
  
dev_dependencies:
  # Icons
  flutter_launcher_icons: ^0.13.1
  
  # Testing
  mockito: ^5.4.4
```

## 💡 Best Practices

1. **Keep it simple** - Start with MVP features
2. **Test early** - Write tests as you implement features
3. **Use AI agents** - Let them handle boilerplate and research
4. **Document decisions** - Save to docs/ folder for future reference
5. **Follow conventions** - Use Flutter/Dart style guides
6. **Build often** - Test on real Android devices regularly
7. **Accessibility first** - Design for all users from the start

## 🚀 Ready to Build!

Once you've completed these customizations, you'll have:
- ✅ Fully branded app with custom name and icon
- ✅ Configured CI/CD pipeline for Android
- ✅ Ready-to-use development environment

**Start building your features with the AI agents!**
