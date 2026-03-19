# MediGuide AI

MediGuide AI is a Flutter + Firebase mobile app for finding nearby medical help and managing basic health context in one flow.

Core user journey:

1. Sign in with Firebase Auth
2. Complete profile setup
3. Open the nearby medical help screen
4. Search nearby hospitals / clinics / pharmacies on a real Google Map
5. Open place details
6. Check route options
7. Save useful places to Firestore favorites

## Main Features

- Firebase Email/Password authentication
- Firebase Google sign in
- Automatic verification email after registration
- Session persistence after app restart
- Firestore-backed user profile
- Firestore-backed saved places
- Firestore-backed recent searches
- Multi-language UI:
  - English
  - Russian
  - Kazakh
  - Turkish
- Theme switching:
  - Light
  - Dark
  - System
- Real Google Map on the nearby screen
- Current user location with permission handling
- Nearby medical place search
- Place details bottom sheet
- In-app route calculation for:
  - driving
  - walking
  - public transport
  - scooter / two-wheeler fallback
- Save / remove favorite places
- Profile editing and health data CRUD
- Custom Android app icon

## Tech Stack

- Flutter 3 / Dart 3
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Google Maps Flutter
- Geolocator
- HTTP
- Provider
- Shared Preferences
- Google Fonts
- URL Launcher

## Project Structure

```text
lib/
  firebase_options.dart
  main.dart
  models/
    models.dart
  screens/
    auth_screen.dart
    home_screen.dart
    main_shell.dart
    medicine_screen.dart
    nearby_screen.dart
    onboarding_screen.dart
    profile_screen.dart
    profile_setup_screen.dart
    symptom_screen.dart
  services/
    app_localizations.dart
    health_services.dart
    maps_service.dart
    providers.dart
  utils/
    app_constants.dart
    app_theme.dart
  widgets/
    common_widgets.dart
```

## Firebase Setup

Before running the project on a real device, configure Firebase Console:

1. Enable `Email/Password` in Firebase Authentication
2. Enable `Google` in Firebase Authentication
3. Add Android `SHA-1` and `SHA-256`
4. Download/update `android/app/google-services.json`
5. Create Firestore Database
6. Configure Firebase Auth email templates for verification / welcome flow

## Google Maps / Places / Routes Setup

The nearby medical help screen uses:

- `Maps SDK for Android`
- `Places API (New)`
- `Routes API`

Required Google Cloud steps:

1. Open the same Google Cloud project used by Firebase
2. Enable:
   - `Maps SDK for Android`
   - `Places API (New)`
   - `Routes API`
3. Make sure the Android app API key is allowed to use those APIs
4. Keep the API key available through the Android resources generated from `google-services.json`

Important:

- The Android manifest now reads the Maps key from `@string/google_api_key`
- REST calls for Places / Routes use the same project API key through `firebase_options.dart`
- If Maps or Places show authorization errors, the project API key usually needs API enablement or restriction updates in Google Cloud Console
- Runtime verification in this workspace showed that `Places API (New)` and `Routes API` are currently disabled for project `381853942853`, so they must be enabled before the live nearby search and in-app routing can return real results
- Runtime verification in this workspace also showed that Firebase Auth currently returns `CONFIGURATION_NOT_FOUND` for `accounts:signUp`, `accounts:createAuthUri`, and verification email calls with the project API keys. That must be fixed in Firebase Console before live Email/Password, Google sign-in, and verification email can work end-to-end.

## Firestore Data Model

Main profile document:

```text
users/{uid}
```

Main profile fields:

- `uid`
- `name`
- `email`
- `avatarEmoji`
- `bloodType`
- `weight`
- `height`
- `allergies`
- `conditions`
- `recentActivity`
- `preferredLocale`
- `preferredTheme`
- `profileCompleted`
- `emailVerified`
- `createdAt`
- `updatedAt`

Saved places collection:

```text
users/{uid}/saved_places/{placeId}
```

Saved place fields include:

- `id`
- `name`
- `address`
- `latitude`
- `longitude`
- `category`
- `types`
- `rating`
- `userRatingCount`
- `openNow`
- `phoneNumber`
- `websiteUri`
- `distanceMeters`
- `photoName`
- `photoUrl`
- `businessStatus`
- `createdAt`
- `updatedAt`

Recent searches collection:

```text
users/{uid}/recent_searches/{searchId}
```

Recent search fields:

- `query`
- `category`
- `updatedAt`

## Run Locally

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk
```

Generated output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Screenshots

Placeholders for GitHub publishing:

- `docs/screenshots/auth.png`
- `docs/screenshots/profile.png`
- `docs/screenshots/map-search.png`
- `docs/screenshots/place-details.png`
- `docs/screenshots/routes.png`

## Stability Notes

- `flutter analyze` should pass cleanly
- The project is APK-ready for Android
- If the auth screen shows `CONFIGURATION_NOT_FOUND`, the Firebase project still needs Authentication setup in Firebase Console
- Real Google sign-in still depends on correct SHA fingerprints in Firebase
- Real map / places / routes still depend on Google Cloud API enablement for the project key

## GitHub Publishing

The project is structured and documented to be GitHub-ready.

Publishing still requires:

- your GitHub repository
- git remote setup
- your GitHub credentials or token
