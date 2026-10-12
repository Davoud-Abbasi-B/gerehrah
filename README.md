# pathly

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Validate puzzle levels

Run the development-only validation test before adding or changing levels:

```sh
flutter test test/validate_levels_test.dart --reporter expanded
```

It loads `assets/levels/levels.json`, checks every stored solution, solves each
level up to two solutions, and prints one summary per level. Invalid or
unsolvable levels fail the command; multiple solutions are reported as warnings.
