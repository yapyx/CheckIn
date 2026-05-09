# CheckIn Flutter App

This folder contains a Flutter implementation of the CheckIn prototype so the experience can move from the existing browser mockup toward native iOS, Android, desktop, and web targets.

## Getting started

1. Install Flutter from <https://docs.flutter.dev/get-started/install>.
2. From this directory, run `flutter pub get`.
3. Start the app with one of these commands:
   - `flutter run -d chrome` for the web version.
   - `flutter run -d windows` for the Windows desktop version.
   - `flutter run` to pick a connected device or emulator.
4. Validate changes with `flutter analyze` and `flutter test`.

If PowerShell says `flutter` is not recognized, restart your terminal after installing Flutter and make sure Flutter's `bin` folder is added to your PATH.

## What is included

- A Material 3 mobile shell that matches the current CheckIn care flow.
- Role selection for elders and caregivers.
- Caregiver inbox, family list, voice-message detail, and quick response actions.
- Elder home, recording, delivered, health-log, and settings screens.
- A widget smoke test that confirms the Flutter app renders the CheckIn welcome flow.

## Project structure

- `lib/main.dart` starts the app.
- `lib/app.dart` contains the Material app and global theme.
- `lib/screens/` contains one file per page.
- `lib/screens/onboarding/welcome_screen.dart` contains the first entry screen.
- `lib/widgets/` contains shared UI components.
- `lib/models/` contains enums and data models.
- `lib/data/` contains sample prototype data.
