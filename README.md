# Gerehrah / گره‌راه

**A Persian RTL path-puzzle game built with Flutter + Flame.**

Gerehrah is a mobile puzzle game with **100 playable levels**, structured progression, local save state, Persian UX, and optional product analytics. It was built as a complete mobile product rather than a one-screen prototype, including gameplay logic, onboarding, progression, analytics instrumentation, testing, and Android release preparation.

## Why I built it

I wanted to build and ship a consumer mobile product outside my core marketing work and use AI-assisted development as a practical way to move from idea to working software.

The project was developed with **OpenAI Codex + VS Code** as part of an AI-assisted workflow: defining the product and rules, implementing features, debugging, validating gameplay, instrumenting analytics, and preparing release builds.

## Highlights

- 100 puzzle levels
- Persian-first RTL interface
- Flutter + Flame gameplay layer
- Level selection and progression
- 20-level season structure
- Local progress persistence
- Tutorial / onboarding flow
- Puzzle validation and solver logic
- Level-quality validation
- Share flow
- Optional Firebase Analytics
- Optional Firebase Crashlytics
- Custom product analytics events
- Android release/signing workflow
- Vazirmatn Persian typography

## Product analytics

The game includes product events for understanding user behavior, including:

- Tutorial viewed
- Tutorial completed
- Invalid move
- Level completed
- App share click

Level-completion events include contextual properties such as:

- level ID
- season number
- level number
- move count
- completion time

This was intentional: I wanted the product to be measurable, not just playable.

## Tech stack

- **Flutter / Dart**
- **Flame**
- **SharedPreferences** for local progression
- **Firebase Analytics** — optional
- **Firebase Crashlytics** — optional
- **Material 3**
- **Vazirmatn** font
- JSON/assets-based level catalog

Android package:

```text
com.damostudio.gerehrah
```

Initial app version:

```text
1.0.0+1
```

## AI-assisted development

Gerehrah is one of my hands-on AI-native building projects.

My workflow included:

1. Defining gameplay rules and product behavior
2. Breaking the product into implementation tasks
3. Using OpenAI Codex to accelerate coding and refactoring
4. Reviewing code and debugging in VS Code
5. Building validators and tests around game behavior
6. Instrumenting analytics events
7. Preparing Android release builds and signing configuration

The purpose of the AI workflow was not to avoid engineering decisions; it was to **reduce the distance between product idea and shipped implementation**.

## Project structure

```text
lib/
├── analytics/      # Product analytics
├── game/           # Gameplay, board, solver, validation, timer
├── home/           # Level selection and season structure
├── localization/   # Persian helpers
├── onboarding/     # Tutorial / onboarding
├── privacy/        # Privacy-related UI/content
├── progress/       # Local progress state
└── share/          # Share flow
```

## Run locally

```bash
flutter pub get
flutter run
```

Useful development commands:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

## Firebase configuration

Firebase is **disabled by default**.

To enable it:

1. Create a Firebase project.
2. Register the Android package `com.damostudio.gerehrah`.
3. Put `google-services.json` in:

```text
android/app/google-services.json
```

4. Set the local Gradle property:

```text
enableFirebase=true
```

5. Run or build with:

```bash
--dart-define=ENABLE_FIREBASE=true
```

Both switches are required. Firebase credentials are intentionally excluded from Git.

## Release signing

Production signing secrets are not stored in the repository.

Create a production keystore and an ignored `android/key.properties` file containing:

```text
storeFile=
storePassword=
keyAlias=
keyPassword=
```

Without signing properties, release APKs remain unsigned.

## Typography

The Persian UI uses **Vazirmatn**. Its bundled license is stored at:

```text
assets/fonts/OFL.txt
```

## Portfolio context

Gerehrah is a strong example of how I combine **growth thinking and hands-on building**: I did not stop at the game mechanics; I also built onboarding, progression, analytics instrumentation, retention-oriented structure, and a release-ready workflow.

---

Built by **Davoud Abbasi**  
Growth marketer & AI-assisted product builder
