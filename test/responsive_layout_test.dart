import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/main.dart';
import 'package:pathly/onboarding/how_to_play.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> levels;

  setUpAll(() async {
    levels = await LevelRepository().loadLevels();
  });

  const viewports = <String, Size>{
    '360x800 phone': Size(360, 800),
    '390x844 phone': Size(390, 844),
    '768x1024 tablet': Size(768, 1024),
    '1440x900 desktop': Size(1440, 900),
  };

  for (final viewport in viewports.entries) {
    testWidgets('${viewport.key} has no level or game overflow', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport.value;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({
        tutorialCompletedPreferenceKey: true,
      });

      await tester.pumpWidget(
        PathlyApp(levelRepository: _LoadedLevelRepository(levels)),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      final pathlyRect = tester.getRect(find.text('Pathly'));
      if (viewport.value == const Size(390, 844)) {
        final selectRect = tester.getRect(
          find.byKey(const Key('select-level-heading')),
        );
        final firstGridCellRect = tester.getRect(
          find.byKey(const Key('season-1-slot-1')),
        );
        expect(pathlyRect.top, closeTo(40, 0.5));
        expect(pathlyRect.top, lessThan(viewport.value.height / 4));
        expect(selectRect.top, closeTo(203.7, 0.5));
        expect(selectRect.top, greaterThan(pathlyRect.bottom + 100));
        expect(firstGridCellRect.top, closeTo(339.7, 0.5));
        expect(firstGridCellRect.top, greaterThan(viewport.value.height * 0.4));
      }
      expect(find.byKey(const Key('season-1-slot-1')), findsOneWidget);
      expect(find.byKey(const Key('season-1-slot-20')), findsOneWidget);
      final firstCell = tester.getRect(
        find.byKey(const Key('season-1-slot-1')),
      );
      final lastCell = tester.getRect(
        find.byKey(const Key('season-1-slot-20')),
      );
      expect(firstCell.left, greaterThanOrEqualTo(0));
      expect(lastCell.right, lessThanOrEqualTo(viewport.value.width));
      expect(lastCell.bottom, lessThanOrEqualTo(viewport.value.height));
      expect(find.byKey(const Key('share-app')), findsOneWidget);
      expect(find.byKey(const Key('privacy-policy')), findsOneWidget);
      final shareButton = tester.getRect(find.byKey(const Key('share-app')));
      expect(shareButton.left, greaterThanOrEqualTo(0));
      expect(shareButton.right, lessThanOrEqualTo(viewport.value.width));
      expect(shareButton.bottom, lessThanOrEqualTo(viewport.value.height));
      await tester.scrollUntilVisible(
        find.byKey(const Key('privacy-policy')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      final privacyButton = tester.getRect(
        find.byKey(const Key('privacy-policy')),
      );
      expect(privacyButton.left, greaterThanOrEqualTo(0));
      expect(privacyButton.right, lessThanOrEqualTo(viewport.value.width));
      expect(privacyButton.bottom, lessThanOrEqualTo(viewport.value.height));
      expect(
        tester.widget<Scrollable>(find.byType(Scrollable).first).axisDirection,
        AxisDirection.down,
      );
      expect(tester.takeException(), isNull);

      for (var season = 2; season <= 6; season++) {
        await tester.scrollUntilVisible(
          find.byKey(const Key('next-season')),
          -120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('next-season')));
        await tester.pump();
        expect(find.text('Season $season'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(Key('season-$season-slot-20')),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(Key('season-$season-slot-20')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      for (var season = 5; season >= 1; season--) {
        await tester.scrollUntilVisible(
          find.byKey(const Key('previous-season')),
          -120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('previous-season')));
        await tester.pump();
        expect(find.text('Season $season'), findsOneWidget);
      }
      await tester.scrollUntilVisible(
        find.byKey(const Key('season-1-slot-1')),
        -120,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const Key('season-1-slot-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      final boardSize = tester.getSize(
        find.byKey(const ValueKey('crossroads-4')),
      );
      expect(boardSize.width, closeTo(boardSize.height, 0.01));
      expect(boardSize.width, lessThanOrEqualTo(viewport.value.width));
      expect(find.byKey(const Key('previous-level')), findsOneWidget);
      expect(find.byKey(const Key('next-level')), findsOneWidget);
    });
  }
}

class _LoadedLevelRepository extends LevelRepository {
  _LoadedLevelRepository(this.levels);

  final List<PuzzleLevel> levels;

  @override
  Future<List<PuzzleLevel>> loadLevels() async => levels;
}
