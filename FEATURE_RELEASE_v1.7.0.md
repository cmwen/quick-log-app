# Quick Log v1.7.0 - Release Summary

## Overview

Quick Log v1.7.0 is a polish release focused on faster record-screen saving, richer Android theming, and cleaner home screen widgets.

## What's New

### 1. Sticky Save Action on the Record Screen

**What changed**
- The Record tab now tracks whether the inline **Save Entry** button is still visible.
- When that button scrolls off-screen, Quick Log shows a small floating save action instead.

**Why it matters**
- Saving stays one tap away on shorter devices and when the form grows with suggestions, notes, and location cards.
- Users no longer need to scroll back to the bottom just to save an entry.

### 2. Dynamic Android Theming

**What changed**
- Quick Log now uses `dynamic_color` to harmonize Material 3 colors with Android's Material You palette when the device supports it.
- Seeded blue light and dark color schemes remain as fallbacks.

**Why it matters**
- The app feels more native on modern Android devices without changing the existing theme-mode settings.
- Light and dark themes stay consistent even when dynamic colors are unavailable.

### 3. Home Screen Widget Visual Refresh

**What changed**
- Travel and Quick Tags widget layouts were tightened up by removing redundant title rows.
- Widget text colors now use theme-aware color resources instead of hard-coded values.
- Spacing was tuned so the primary content and actions fit more comfortably across widget sizes.

**Why it matters**
- The widgets look cleaner on more launchers and remain easier to read in different themes.
- Quick actions like **Log here**, **New entry**, **Entries**, and **Review** stay prominent.

### 4. Regression Coverage for Save Ergonomics

**What changed**
- Widget tests now verify that the floating save action only appears when the inline save button is actually out of view.

**Why it matters**
- The new save behavior is protected against layout regressions as the Record screen evolves.

## Files Updated for This Release

### Application code
1. `lib/main.dart`
2. `lib/screens/main_screen.dart`
3. `android/app/src/main/res/layout/quick_log_widget.xml`
4. `android/app/src/main/res/layout/quick_log_widget_compact.xml`
5. `android/app/src/main/res/layout/quick_log_widget_tags.xml`
6. `android/app/src/main/res/layout/quick_log_widget_travel.xml`
7. `test/widget_test.dart`
8. `pubspec.yaml`
9. `pubspec.lock`

### Documentation
1. `README.md`
2. `QUICK_LOG_README.md`
3. `docs/IMPLEMENTATION_STATUS.md`
4. `FEATURE_RELEASE_v1.7.0.md`

## Breaking Changes

**None.** Existing data, settings, widgets, and release workflows remain compatible.

## Migration Notes

- No database migration is required.
- Existing theme preferences still work as before.
- Existing widget placements continue to function with the refreshed layouts.

## Release Notes

- Added a sticky floating **Save** action when the Record screen's main save button scrolls off-screen.
- Added dynamic Android theming with Material You harmonization and safe fallback color schemes.
- Refreshed the Travel and Quick Tags widgets with tighter spacing and theme-aware colors.
- Added widget-test coverage for the sticky save behavior.

## Validation Focus

- Record tab save behavior on small and tall screens
- Dynamic-color fallback behavior on devices without Material You support
- Travel and Quick Tags widget readability in light and dark launcher themes

## Version Metadata

- **Version:** `1.7.0`
- **Build:** `17`
- **Release Date:** `2026-05-02`
