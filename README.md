# Gerehrah / گره‌راه

**A Persian RTL path-puzzle game built with Flutter + Flame.**

Gerehrah is a mobile puzzle game with 100 playable levels, structured progression, local save state, Persian UX, and optional product analytics.

## Highlights

- 100 puzzle levels
- Persian-first RTL interface
- Flutter + Flame gameplay layer
- Level selection and progression
- Local progress persistence
- Tutorial / onboarding flow
- Puzzle validation and solver logic
- Optional Firebase Analytics
- Optional Firebase Crashlytics
- Vazirmatn Persian typography

## Tech stack

- Flutter / Dart
- Flame
- SharedPreferences
- Firebase Analytics
- Firebase Crashlytics
- Material 3
- Vazirmatn
- JSON/assets-based level catalog

Android package:

com.modastudio.gerehrah

Initial app version:

1.0.0+1

## Run locally

flutter pub get
flutter run

Useful commands:

flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release

## Firebase configuration

Firebase is disabled by default.

Firebase credentials and signing secrets are not stored in Git.

Register the Android app in Firebase with package:

com.modastudio.gerehrah

Put google-services.json here:

android/app/google-services.json

To enable Firebase, set:

enableFirebase=true

in:

~/.gradle/gradle.properties

and run/build with:

--dart-define=ENABLE_FIREBASE=true

Both settings are required.

Gradle validates that the Firebase configuration contains a client for com.modastudio.gerehrah.

Advertising ID collection is disabled.

## Release signing

Production signing secrets are not stored in the repository.

Use the ignored file:

android/key.properties

with:

storeFile=
storePassword=
keyAlias=
keyPassword=

Back up the production signing key securely and keep using the same key for future updates.

## Branding

Android launcher icons and the home header use:

assets/gerehrah_icon.png

## Typography

The Persian UI uses Vazirmatn.

License:

assets/fonts/OFL.txt

---

Built by Davoud Abbasi
