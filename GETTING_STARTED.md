# Getting Started Guide

Welcome! This guide will help you set up and customize the Quick Log Android app.

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ Flutter SDK 3.10.1+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- ✅ Dart 3.10.1+
- ✅ Java 17+ (for Android builds)
- ✅ Android Studio or Android SDK
- ✅ Git
- ✅ VS Code with GitHub Copilot (recommended for AI assistance)

Verify your setup:
```bash
flutter doctor -v
java -version  # Should show version 17+
```

## 🚀 Quick Start Checklist

Follow these steps in order to set up the app:

### Step 1: Clone and Setup

```bash
# Clone this repository
git clone https://github.com/cmwen/quick-log-app.git
cd quick-log-app

# Get dependencies
flutter pub get

# Verify everything works
flutter analyze
```

### Step 2: Run on Android

```bash
# List available devices
flutter devices

# Run on connected Android device or emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Step 3: Customize Your App (Optional)

If you want to customize the app:

#### Files to Update:

1. **`pubspec.yaml`** (Line 1):
   ```yaml
   name: your_app_name  # Change from quick_log_app
   description: "Your app description"
   ```

2. **`lib/main.dart`** (Import statement):
   ```dart
   import 'package:your_app_name/screens/main_screen.dart';
   ```

3. **`android/app/build.gradle.kts`**:
   ```kotlin
   namespace = "com.yourcompany.yourapp"
   applicationId = "com.yourcompany.yourapp"
   ```

4. **`android/app/src/main/AndroidManifest.xml`**:
   ```xml
   android:label="Your App Name"
   ```

#### Using AI to Rename

Ask your AI agent:
```
Please rename this Flutter app from "quick_log_app" to "my_app_name" 
and update the package name from "com.cmwen.quick_log_app" to "com.mycompany.my_app". 
Update all necessary files including pubspec.yaml, build.gradle.kts, AndroidManifest.xml, 
and Dart imports.
```

### Step 4: Create App Icon

Use the provided prompt to generate a custom icon:

```
@icon-generation.prompt.md

Create an app launcher icon for [describe your app]. 
Style: [flat/gradient/minimal], 
Primary color: #[hex], 
Symbol: [describe icon concept]
```

Or use flutter_launcher_icons:

1. Add to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   
   flutter_launcher_icons:
     android: true
     image_path: "assets/icon/app_icon.png"
   ```

2. Run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

### Step 5: Set Up GitHub Repository

1. **Create new repository** on GitHub

2. **Update remote**:
   ```bash
   git remote set-url origin https://github.com/yourusername/your-repo-name.git
   ```

3. **Configure signing secrets** (for releases):
   
   Generate keystore:
   ```bash
   keytool -genkey -v -keystore release-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias release
   ```
   
   Add GitHub Secrets:
   - `ANDROID_KEYSTORE_BASE64`: `base64 -i release-keystore.jks`
   - `ANDROID_KEYSTORE_PASSWORD`: Your keystore password
   - `ANDROID_KEY_ALIAS`: `release`
   - `ANDROID_KEY_PASSWORD`: Your key password

4. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Initial setup"
   git push -u origin main
   ```

### Step 6: Test Your Setup

```bash
# Run on Android emulator or device
flutter run

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Run tests
flutter test
flutter analyze
```

## 🤖 Using AI Agents for Development

This template includes custom GitHub Copilot agents to accelerate development:

### Available Agents

1. **@product-owner** - Define features and requirements
2. **@experience-designer** - Design user flows and interfaces
3. **@architect** - Plan technical architecture
4. **@researcher** - Research dependencies and best practices
5. **@flutter-developer** - Implement features
6. **@doc-writer** - Create documentation

### Example Workflow

```
@flutter-developer Add a new screen to view entry statistics with charts
```

## 📚 Key Documentation

- [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Build performance tips
- [AGENTS.md](AGENTS.md) - AI agent configuration details
- [TESTING.md](TESTING.md) - Testing guide

## 🐛 Troubleshooting

### Build Issues

**Java version mismatch**:
```bash
# Check Java version
java -version

# Set JAVA_HOME (macOS/Linux)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

**Gradle build fails**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### App Not Opening on Device

1. **Check Flutter installation**: `flutter doctor -v`
2. **Verify Android SDK**: Ensure API level 21+ is installed
3. **Check device connection**: `flutter devices`
4. **Enable USB debugging** on your Android device
5. **Run in verbose mode**: `flutter run -v`

### Location Not Working

1. **Grant location permissions** when prompted
2. **Enable location services** on the device
3. **Check GPS availability**: Some emulators need location simulation

### Import Errors After Renaming

```bash
flutter clean
flutter pub get
dart fix --apply
```

## ✅ Setup Complete!

Once you've completed all steps, you should have:
- ✅ App running on Android device/emulator
- ✅ GitHub repository configured
- ✅ CI/CD workflows ready for releases
- ✅ AI agents configured for development

**You're ready to use Quick Log!** 🎉
