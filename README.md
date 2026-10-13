# Gerehrah / گره‌راه

Persian RTL puzzle game built with Flutter + Flame for Cafe Bazaar.
Android package: `com.damostudio.gerehrah`. Initial version: `1.0.0+1`.
All 100 levels retain their original gameplay geometry and rules.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Firebase is disabled by default. Firebase credentials and signing secrets are not stored in Git.
Create a new Firebase project and register Android app `com.damostudio.gerehrah`.
Download its `google-services.json` to ignored `android/app/google-services.json`.
To enable Firebase explicitly, set `enableFirebase=true` in your local `~/.gradle/gradle.properties`
and run/build with `--dart-define=ENABLE_FIREBASE=true`. Both settings are required.
Gradle rejects Firebase clients with another package. Analytics event names remain unchanged.
Advertising ID collection stays disabled.

Generate a new Gerehrah production keystore, keep it outside Git, and create ignored
`android/key.properties` with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`.
Use an absolute `storeFile` path (relative paths resolve from `android/app/`).
Without signing properties, release APKs are unsigned and cannot be published.
Back up the new key securely and use it for future updates.
Android launcher icons and the home header use `assets/gerehrah_icon.png`.
Regenerate legacy, round, and adaptive foreground resources after replacing it:
`flutter test tool/generate_android_launcher_icons_test.dart`.
The adaptive foreground keeps the full square image inside the circular safe zone
on the matching navy background; the original image is never overwritten.

Persian UI typography uses Vazirmatn v33.003 (Regular, Medium, SemiBold, Bold),
from https://github.com/rastikerdar/vazirmatn under the SIL Open Font License 1.1.
The bundled license is `assets/fonts/OFL.txt`; Flutter includes it in its license
registry. The central theme applies the font to all Material screens and labels.

The legacy local progress key is intentionally preserved for existing installations.
The independent Android package keeps app storage separate. Tutorial persistence is unchanged.
