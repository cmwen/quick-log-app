# Quick Log App Icon Specification

## Icon Concept

The Quick Log app icon represents a tag-first logging application with location tracking capabilities.

### Design Elements

1. **Primary Symbol**: A tag/label icon (representing the tag-first approach)
2. **Secondary Element**: A pen/pencil (representing quick logging)
3. **Accent**: A location pin or dot (representing location tracking)

### Color Scheme

- **Primary**: Blue (#2196F3) - Represents reliability, clarity, and focus
- **Accent**: White or light color for contrast
- **Style**: Material Design 3 principles

### Icon Concept Description

**Simple Design:**
```
┌─────────────┐
│   📝 🏷️    │  - A blue tag shape with a pen/pencil icon
│      •      │  - Small location dot at bottom
└─────────────┘
```

The icon should be:
- Clean and minimal
- Instantly recognizable as a logging/note-taking tool
- The tag shape emphasizes the "tag-first" approach
- Modern Material Design 3 aesthetic
- Works well at all sizes (from 48x48 to 512x512)

## Icon Generation Instructions

For AI image generation or designer:

**Prompt for Icon Generator:**
"Create a mobile app icon for a logging application. Design a rounded square icon with a blue (#2196F3) tag/label shape in the center. Add a white pen or pencil symbol overlaying the tag. Include a small location pin dot at the bottom. Use Material Design 3 style with smooth gradients, clean lines, and a modern minimal aesthetic. The icon should be suitable for both iOS and Android platforms."

**Alternative Simpler Design:**
"Blue rounded square icon with a white tag/label symbol and a small white pen icon in the corner. Material Design 3 style, minimal and clean."

## Icon Files Needed

To generate proper app icons, you would need to create these sizes:

### Android (mipmap directories)
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192

### iOS
- 20x20 (iPhone Notification)
- 29x29 (Settings)
- 40x40 (Spotlight)
- 58x58 (Settings @2x)
- 60x60 (iPhone App)
- 76x76 (iPad App)
- 80x80 (Spotlight @2x)
- 87x87 (Settings @3x)
- 120x120 (iPhone App @2x)
- 152x152 (iPad App @2x)
- 167x167 (iPad Pro App @2x)
- 180x180 (iPhone App @3x)
- 1024x1024 (App Store)

### Web
- 192x192
- 512x512

## Using Flutter Launcher Icons Package

To automatically generate all required icon sizes, use the `flutter_launcher_icons` package:

1. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # Your 1024x1024 source icon
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/icon/foreground.png"
```

2. Place your 1024x1024 icon in `assets/icon/icon.png`

3. Run: `flutter pub run flutter_launcher_icons`

## Current Status

The app currently uses the default Flutter icon. To update:

1. Create or obtain the icon design (1024x1024 PNG)
2. Use flutter_launcher_icons package to generate all sizes
3. Or manually replace icons in:
   - `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - `web/icons/`

## Notes for AI Implementation

If an AI is generating the icon:
- Start with a 1024x1024 canvas
- Use the blue color #2196F3 as the primary color
- Keep design simple and scalable
- Ensure good contrast for small sizes
- Test at multiple resolutions
- Consider adaptive icons for Android (separate foreground/background layers)
