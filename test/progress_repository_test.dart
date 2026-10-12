import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/level_progression.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/progress/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<PuzzleLevel> starterLevels;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    starterLevels = await LevelRepository().loadLevels();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads empty progress when storage is empty', () async {
    final progress = await SharedPreferencesProgressRepository().load();

    expect(progress.completedLevels, isEmpty);
  });

  test('handles invalid saved progress safely', () async {
    SharedPreferences.setMockInitialValues({
      'pathly.player_progress.v1': '{invalid json',
    });

    final progress = await SharedPreferencesProgressRepository().load();

    expect(progress.completedLevels, isEmpty);
  });

  test('loads existing Season 1 v1 saved data unchanged', () async {
    SharedPreferences.setMockInitialValues({
      'pathly.player_progress.v1':
          '{"completedLevels":{"crossroads-4":'
          '{"bestMoves":7,"bestTimeSeconds":65}}}',
    });

    final progress = await SharedPreferencesProgressRepository().load();

    expect(progress.completedLevels['crossroads-4']!.bestMoves, 7);
    expect(progress.completedLevels['crossroads-4']!.bestTimeSeconds, 65);
  });

  test('saves a completed level with its result', () async {
    final repository = SharedPreferencesProgressRepository();

    await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 9,
      timeSeconds: 75,
    );
    final saved = await repository.load();

    expect(saved.completedLevels, contains(starterLevels.first.id));
    expect(saved.completedLevels[starterLevels.first.id]!.bestMoves, 9);
    expect(saved.completedLevels[starterLevels.first.id]!.bestTimeSeconds, 75);
  });

  test('a lower move count replaces only the move record', () async {
    final repository = SharedPreferencesProgressRepository();
    await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 10,
      timeSeconds: 60,
    );

    final result = await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 8,
      timeSeconds: 90,
    );

    expect(result.bestMoves, 8);
    expect(result.bestTimeSeconds, 60);
  });

  test('a faster time replaces only the time record', () async {
    final repository = SharedPreferencesProgressRepository();
    await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 8,
      timeSeconds: 90,
    );

    final result = await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 12,
      timeSeconds: 55,
    );

    expect(result.bestMoves, 8);
    expect(result.bestTimeSeconds, 55);
  });

  test('worse results do not replace better records', () async {
    final repository = SharedPreferencesProgressRepository();
    await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 7,
      timeSeconds: 40,
    );

    final result = await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 11,
      timeSeconds: 80,
    );

    expect(result.bestMoves, 7);
    expect(result.bestTimeSeconds, 40);
  });

  test('completing a level unlocks the next level after loading', () async {
    final repository = SharedPreferencesProgressRepository();
    await repository.saveCompletedLevel(
      levelId: starterLevels.first.id,
      moves: 8,
      timeSeconds: 50,
    );
    final progression = LevelProgression(starterLevels, repository: repository);

    await progression.loadProgress();

    expect(progression.isLevelUnlocked(0), isTrue);
    expect(progression.isLevelUnlocked(1), isTrue);
    expect(progression.isLevelUnlocked(2), isFalse);
    expect(progression.goToLevel(1), isTrue);
  });

  test(
    'progress remains after recreating the progression controller',
    () async {
      final repository = SharedPreferencesProgressRepository();
      await repository.saveCompletedLevel(
        levelId: starterLevels.first.id,
        moves: 6,
        timeSeconds: 35,
      );

      final recreated = LevelProgression(
        starterLevels,
        repository: SharedPreferencesProgressRepository(),
      );
      await recreated.loadProgress();

      expect(recreated.isCompleted(starterLevels.first.id), isTrue);
      expect(recreated.resultFor(starterLevels.first.id)!.bestMoves, 6);
      expect(recreated.resultFor(starterLevels.first.id)!.bestTimeSeconds, 35);
      expect(recreated.isLevelUnlocked(1), isTrue);
    },
  );

  test('Season 1 and Season 2 progress persist independently', () async {
    final repository = SharedPreferencesProgressRepository();
    for (final level in starterLevels.take(20)) {
      await repository.saveCompletedLevel(
        levelId: level.id,
        moves: 10,
        timeSeconds: 60,
      );
    }
    await repository.saveCompletedLevel(
      levelId: starterLevels[20].id,
      moves: 12,
      timeSeconds: 75,
    );

    final reopened = LevelProgression(
      starterLevels,
      repository: SharedPreferencesProgressRepository(),
    );
    await reopened.loadProgress();

    expect(
      starterLevels.take(20).where((level) => reopened.isCompleted(level.id)),
      hasLength(20),
    );
    expect(reopened.isCompleted(starterLevels[20].id), isTrue);
    expect(reopened.isLevelUnlocked(21), isTrue);
    expect(reopened.isLevelUnlocked(22), isFalse);
  });

  test('Season 3 through Season 5 progress survives app restart', () async {
    final repository = SharedPreferencesProgressRepository();
    for (final level in starterLevels.take(81)) {
      await repository.saveCompletedLevel(
        levelId: level.id,
        moves: 10,
        timeSeconds: 60,
      );
    }

    final reopened = LevelProgression(
      starterLevels,
      repository: SharedPreferencesProgressRepository(),
    );
    await reopened.loadProgress();

    for (final index in [40, 60, 80]) {
      expect(reopened.isCompleted(starterLevels[index].id), isTrue);
      expect(reopened.resultFor(starterLevels[index].id)!.bestMoves, 10);
      expect(reopened.resultFor(starterLevels[index].id)!.bestTimeSeconds, 60);
    }
    expect(
      starterLevels
          .sublist(40, 60)
          .where((level) => reopened.isCompleted(level.id)),
      hasLength(20),
    );
    expect(
      starterLevels
          .sublist(60, 80)
          .where((level) => reopened.isCompleted(level.id)),
      hasLength(20),
    );
    expect(reopened.isLevelUnlocked(80), isTrue);
    expect(reopened.isLevelUnlocked(81), isTrue);
    expect(reopened.isLevelUnlocked(82), isFalse);
  });
}
