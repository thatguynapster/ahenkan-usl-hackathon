# End-to-End Integration Tests

This directory contains end-to-end integration tests for the sign language communication app.

## Test Coverage

The integration tests cover the following requirements:

### 1. Complete Sign-to-Text Flow with History (Requirements 2.1, 2.2, 3.1, 7.1)

-   Tests the complete flow of recording sign language gestures
-   Verifies interpretation results are displayed
-   Confirms messages are added to session history

### 2. Complete Text-to-Sign Flow with History (Requirements 4.1, 5.1, 7.1)

-   Tests text input and sign language video generation
-   Verifies character counter functionality
-   Confirms messages are added to session history

### 3. Language Switching Across All Features (Requirement 6.3)

-   Tests language selection persistence
-   Verifies language changes affect all screens
-   Confirms language preference is maintained during navigation

### 4. Session History Management (Requirements 7.1, 7.2, 7.4)

-   Tests adding messages to history from both modes
-   Verifies chronological ordering of messages
-   Confirms history display functionality

### 5. Navigation Transitions (Requirement 6.2)

-   Verifies navigation between screens completes within 1 second
-   Tests smooth transitions between all three screens

### 6. App Stability (Requirement 3.4)

-   Tests navigation stability across all screens
-   Verifies no crashes during screen transitions

## Running the Tests

To run the integration tests:

```bash
flutter test test/integration/app_integration_test.dart
```

To run with extended timeout:

```bash
flutter test test/integration/app_integration_test.dart --timeout=120s
```

## Test Notes

-   Tests use mock SharedPreferences for isolated testing
-   Tests verify core functionality and user flows
-   Layout overflow warnings in test environment are expected and don't affect actual app functionality
-   Tests focus on validating business logic and user interactions rather than pixel-perfect UI rendering

## Test Structure

Each test follows this pattern:

1. Build and initialize the app
2. Navigate to the appropriate screen
3. Perform user actions (tap buttons, enter text, etc.)
4. Verify expected outcomes
5. Check that data persists across navigation

## Requirements Mapping

| Test                       | Requirements Covered |
| -------------------------- | -------------------- |
| Complete sign-to-text flow | 2.1, 2.2, 3.1, 7.1   |
| Complete text-to-sign flow | 4.1, 5.1, 7.1        |
| Language switching         | 6.3                  |
| Session history management | 7.1, 7.2, 7.4        |
| Navigation transitions     | 6.2                  |
| App stability              | 3.4                  |
