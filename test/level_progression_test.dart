import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/grid_cell.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/level_progression.dart';
import 'package:pathly/game/path_board.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/progress/progress_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> starterLevels;

  setUpAll(() async {
    starterLevels = await LevelRepository().loadLevels();
  });

  test('Next is locked until solved and level changes clear state', () {
    final progression = LevelProgression(starterLevels);

    expect(progression.canGoNext, isFalse);
    expect(progression.goNext(), isFalse);
    _solveCurrentLevel(progression.board);
    expect(progression.canGoNext, isTrue);

    expect(progression.goNext(), isTrue);
    expect(progression.levelIndex, 1);
    expect(progression.board.moveCount, 0);
    expect(progression.board.canUndo, isFalse);
    expect(progression.board.isSolved, isFalse);
    expect(progression.canGoPrevious, isTrue);
  });

  test('undoing or resetting a solution locks Next again', () {
    final progression = LevelProgression(starterLevels);
    _solveCurrentLevel(progression.board);
    expect(progression.canGoNext, isTrue);

    progression.board.undo();
    expect(progression.board.isSolved, isFalse);
    expect(progression.canGoNext, isFalse);

    _drawPath(progression.board, _fourByFourSolution.last);
    expect(progression.board.isSolved, isTrue);
    expect(progression.canGoNext, isTrue);
    progression.board.reset();
    expect(progression.canGoNext, isFalse);
  });

  test('Next remains disabled on the solved final level', () async {
    final progression = LevelProgression(starterLevels);
    for (var index = 0; index < starterLevels.length; index++) {
      _solveCurrentLevel(progression.board);
      await progression.recordCurrentCompletion();
      if (index < starterLevels.length - 1) {
        expect(progression.goNext(), isTrue);
      }
    }

    expect(progression.levelIndex, starterLevels.length - 1);
    expect(progression.board.isSolved, isTrue);
    expect(progression.canGoNext, isFalse);
    expect(progression.goNext(), isFalse);
  });

  test('completing Season 1 unlocks only Season 2 level 1', () async {
    final progression = LevelProgression(starterLevels);

    for (var index = 0; index < 20; index++) {
      _solveCurrentLevel(progression.board);
      await progression.recordCurrentCompletion();
      if (index < 19) {
        expect(progression.isLevelUnlocked(index + 1), isTrue);
        expect(progression.goNext(), isTrue);
      }
    }

    expect(progression.levelIndex, 19);
    expect(progression.level.id, 'master-route-6');
    expect(progression.isLevelUnlocked(20), isTrue);
    expect(progression.isLevelUnlocked(21), isFalse);
    expect(progression.goNext(), isTrue);
    expect(progression.level.id, 'season-2-01');
  });

  test(
    'Season 2 stays locked unless every Season 1 level is complete',
    () async {
      final progression = LevelProgression(starterLevels);

      for (var index = 0; index < 19; index++) {
        expect(progression.goToLevel(index), isTrue);
        _solveCurrentLevel(progression.board);
        await progression.recordCurrentCompletion();
      }

      expect(progression.isLevelUnlocked(20), isFalse);
      expect(progression.goToLevel(20), isFalse);
    },
  );

  for (final season in [3, 4, 5]) {
    test(
      'Season $season requires every Season ${season - 1} completion',
      () async {
        final seasonStart = (season - 1) * 20;
        final completed = <String, LevelBestResult>{
          for (final level in starterLevels.take(seasonStart - 1))
            level.id: const LevelBestResult(bestMoves: 10, bestTimeSeconds: 60),
        };
        final repository = _MemoryProgressRepository(completed);
        final progression = LevelProgression(
          starterLevels,
          repository: repository,
        );
        await progression.loadProgress();

        expect(progression.isLevelUnlocked(seasonStart), isFalse);
        completed[starterLevels[seasonStart - 1].id] = const LevelBestResult(
          bestMoves: 10,
          bestTimeSeconds: 60,
        );
        await progression.loadProgress();

        expect(progression.isLevelUnlocked(seasonStart), isTrue);
        expect(progression.isLevelUnlocked(seasonStart + 1), isFalse);
        expect(progression.goToLevel(seasonStart), isTrue);
        _solveCurrentLevel(progression.board);
        await progression.recordCurrentCompletion();
        expect(progression.isLevelUnlocked(seasonStart + 1), isTrue);
      },
    );
  }
}

void _solveCurrentLevel(PathBoard board) {
  for (final path in board.level.primarySolution.paths) {
    _drawPath(board, path.cells);
  }
  expect(board.isSolved, isTrue);
}

void _drawPath(PathBoard board, List<GridCell> cells) {
  expect(board.begin(cells.first), isTrue);
  for (final cell in cells.skip(1)) {
    expect(board.moveTo(cell), isTrue);
  }
  expect(board.end(), isTrue);
}

const _fourByFourSolution = [
  [
    GridCell(0, 0),
    GridCell(0, 1),
    GridCell(1, 1),
    GridCell(1, 0),
    GridCell(2, 0),
    GridCell(2, 1),
    GridCell(3, 1),
    GridCell(3, 0),
  ],
  [
    GridCell(0, 3),
    GridCell(0, 2),
    GridCell(1, 2),
    GridCell(1, 3),
    GridCell(2, 3),
    GridCell(2, 2),
    GridCell(3, 2),
    GridCell(3, 3),
  ],
];

class _MemoryProgressRepository implements ProgressRepository {
  _MemoryProgressRepository(this.completedLevels);

  final Map<String, LevelBestResult> completedLevels;

  @override
  Future<PlayerProgress> load() async => PlayerProgress(completedLevels);

  @override
  Future<LevelBestResult> saveCompletedLevel({
    required String levelId,
    required int moves,
    required int timeSeconds,
  }) async {
    final result = LevelBestResult(
      bestMoves: moves,
      bestTimeSeconds: timeSeconds,
    );
    completedLevels[levelId] = result;
    return result;
  }
}
