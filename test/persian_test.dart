import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/localization/persian.dart';
import 'package:gerehrah/main.dart';
import 'package:gerehrah/onboarding/how_to_play.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> levels;
  setUpAll(() async {
    levels = await LevelRepository().loadLevels();
  });
  test('formats Persian digits without changing punctuation or input', () {
    expect(persianDigits(120), '۱۲۰');
    expect(persianDigits('09:42'), '۰۹:۴۲');
    expect(persianDigits('۰۱۲ —'), '۰۱۲ —');
    const count = 42;
    expect(persianDigits(count), '۴۲');
    expect(count, 42);
  });

  testWidgets('app provides Persian locale and RTL including tutorial', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      tutorialCompletedPreferenceKey: true,
    });
    await tester.pumpWidget(
      GerehrahApp(levelRepository: _LoadedRepository(levels)),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(const Key('season-title')));
    expect(Localizations.localeOf(context), const Locale('fa'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(
      tester.getCenter(find.byKey(const Key('season-1-slot-1'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const Key('season-1-slot-2'))).dx,
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('how-to-play')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('how-to-play')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('how-to-play-sheet'))),
      ),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

class _LoadedRepository extends LevelRepository {
  _LoadedRepository(this.levels);
  final List<PuzzleLevel> levels;
  @override
  Future<List<PuzzleLevel>> loadLevels() async => levels;
}
