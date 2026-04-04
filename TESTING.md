# Testing Guide

This document provides comprehensive testing guidelines for the Flutter application.

## Overview

Flutter provides excellent built-in testing support at three levels:
- **Unit Tests**: Test individual functions, methods, and classes
- **Widget Tests**: Test individual widgets and their interactions
- **Integration Tests**: Test complete app flows on real devices/emulators

## Running Tests

### All Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Verbose output
flutter test --verbose
```

### Specific Tests
```bash
# Run specific test file
flutter test test/widget_test.dart
flutter test test/home_widget_service_test.dart
flutter test test/settings_provider_test.dart
flutter test test/visit_detection_service_test.dart

# Run tests matching pattern
flutter test --plain-name "Quick Log app starts"
```

## Current Automated Suites

The repository currently includes these committed test suites:

- `test/widget_test.dart` - smoke test that boots `QuickLogRoot`
- `test/home_widget_service_test.dart` - verifies Android widget snapshot defaults, review priority, and shortcut labels
- `test/settings_provider_test.dart` - verifies Travel Mode bundling and background-tracking setting normalization
- `test/visit_detection_service_test.dart` - verifies travel-mode review entries and everyday dwell thresholds

### Watch Mode
```bash
# Re-run tests on file changes
flutter test --watch
```

## Test Structure

### Unit Tests

Location: `test/` (for example `test/home_widget_service_test.dart`, `test/settings_provider_test.dart`, and `test/visit_detection_service_test.dart`)

Example:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calculator', () {
    test('adds two numbers', () {
      expect(2 + 2, equals(4));
    });

    test('subtracts two numbers', () {
      expect(5 - 3, equals(2));
    });
  });
}
```

### Widget Tests

Location: `test/widget_test.dart` or `test/widgets/`

Example:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_log_app/main.dart';

void main() {
  testWidgets('Quick Log app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickLogRoot());
    await tester.pumpAndSettle();

    expect(find.text('Quick Log'), findsOneWidget);
  });
}
```

### Integration Tests

Location: `integration_test/`

Setup:
```bash
# Add integration_test dependency to pubspec.yaml
flutter pub add --dev integration_test
```

Example:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quick_log_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Quick Log'), findsOneWidget);
    await tester.tap(find.text('See all tags'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Select Tags'), findsOneWidget);
  });
}
```

Run integration tests:
```bash
flutter test integration_test
```

## Test Coverage

### Generate Coverage
```bash
# Run tests with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals
- Aim for >80% coverage for critical business logic
- Focus on testing user-facing features
- Don't obsess over 100% coverage

## Mocking

### Using Mockito

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

Example:
```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ApiService])
void main() {
  test('fetches data from API', () async {
    final mockApi = MockApiService();
    when(mockApi.fetchData()).thenAnswer((_) async => 'test data');
    
    final result = await mockApi.fetchData();
    expect(result, equals('test data'));
    verify(mockApi.fetchData()).called(1);
  });
}
```

## Testing Best Practices

### 1. Test Naming
```dart
// Good
test('should return user when authentication succeeds', () {});
testWidgets('should display error message when network fails', (tester) async {});

// Bad
test('test1', () {});
testWidgets('widget test', (tester) async {});
```

### 2. Arrange-Act-Assert Pattern
```dart
test('adds item to cart', () {
  // Arrange
  final cart = ShoppingCart();
  final item = Product('Widget', 9.99);
  
  // Act
  cart.add(item);
  
  // Assert
  expect(cart.items.length, equals(1));
  expect(cart.total, equals(9.99));
});
```

### 3. Widget Testing Tips
```dart
testWidgets('example', (WidgetTester tester) async {
  // Use pumpWidget to build the widget tree
  await tester.pumpWidget(const MaterialApp(home: MyWidget()));
  
  // Use pump() to trigger a single frame
  await tester.pump();
  
  // Use pumpAndSettle() to wait for all animations
  await tester.pumpAndSettle();
  
  // Find widgets
  expect(find.text('Hello'), findsOneWidget);
  expect(find.byType(TextField), findsWidgets);
  expect(find.byKey(const Key('submit')), findsOneWidget);
  
  // Interact with widgets
  await tester.tap(find.byIcon(Icons.add));
  await tester.enterText(find.byType(TextField), 'test');
  await tester.drag(find.byType(ListView), const Offset(0, -200));
});
```

### 4. Test Organization
```dart
void main() {
  group('UserRepository', () {
    late UserRepository repository;
    
    setUp(() {
      repository = UserRepository();
    });
    
    tearDown(() {
      repository.dispose();
    });
    
    group('fetchUser', () {
      test('returns user when successful', () {});
      test('throws exception when not found', () {});
    });
    
    group('updateUser', () {
      test('updates user successfully', () {});
      test('validates input', () {});
    });
  });
}
```

## Golden Tests

Golden tests compare widget screenshots against reference images:

```dart
testWidgets('golden test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('golden/my_widget.png'),
  );
});
```

Update golden files:
```bash
flutter test --update-goldens
```

## Debugging Tests

### Print Debug Info
```dart
test('debug test', () {
  final value = calculateSomething();
  debugPrint('Value: $value');
  expect(value, equals(42));
});
```

### Run Single Test
```bash
# Run specific test by line number
flutter test test/widget_test.dart:10

# Run with debugging
flutter test --pause-after-load
```

## CI/CD Integration

Tests run automatically on:
- Every push to main/develop
- Every pull request
- Before releases

See `.github/workflows/build.yml` for configuration.

## Common Issues

### Issue: Tests time out
```dart
// Increase timeout
test('long running test', () {
  // test code
}, timeout: const Timeout(Duration(seconds: 60)));
```

### Issue: Widget tests fail on CI
```dart
// Ensure MaterialApp wrapper
await tester.pumpWidget(
  const MaterialApp(
    home: MyWidget(),
  ),
);
```

### Issue: Async tests fail
```dart
// Use async/await properly
test('async test', () async {
  final result = await Future.delayed(
    const Duration(seconds: 1),
    () => 'done',
  );
  expect(result, equals('done'));
});
```

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Flutter Test API](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)

## Quick Reference

```bash
# Common commands
flutter test                          # Run all tests
flutter test --coverage               # With coverage
flutter test test/widget_test.dart    # Specific file
flutter test test/settings_provider_test.dart
flutter test test/visit_detection_service_test.dart
flutter test --update-goldens         # Update golden files
flutter test --verbose                # Verbose output
flutter test --watch                  # Watch mode

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests
flutter test integration_test
flutter drive --target=integration_test/app_test.dart
```
