import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/grid_cell.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/path_board.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/game/puzzle_solution_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> levels;

  setUpAll(() async {
    levels = await LevelRepository().loadLevels();
  });

  test('loads 100 levels with five seasons intended progression', () {
    expect(levels, hasLength(100));
    expect(levels.map((level) => level.id).toSet(), hasLength(100));

    final seasonOne = levels.take(20).toList();
    final easy = seasonOne.sublist(0, 5);
    final medium = seasonOne.sublist(5, 10);
    final hard = seasonOne.sublist(10, 15);
    final challenge = seasonOne.sublist(15, 20);

    expect(easy.where((level) => level.rows == 4), hasLength(3));
    expect(
      medium.every(
        (level) =>
            level.rows == 5 &&
            level.columns == 5 &&
            level.endpointPairs.length >= 3 &&
            level.endpointPairs.length <= 4,
      ),
      isTrue,
    );
    expect(
      hard.every(
        (level) =>
            (level.rows == 5 || level.rows == 6) &&
            level.rows == level.columns &&
            level.endpointPairs.length == 4,
      ),
      isTrue,
    );
    expect(
      challenge.every(
        (level) =>
            level.rows == 6 &&
            level.columns == 6 &&
            level.endpointPairs.length == 4,
      ),
      isTrue,
    );
    final seasonTwo = levels.sublist(20, 40);
    expect(seasonTwo, hasLength(20));
    expect(
      seasonTwo.every(
        (level) =>
            (level.rows == 5 || level.rows == 6) &&
            level.rows == level.columns &&
            level.endpointPairs.length == 4,
      ),
      isTrue,
    );
    expect(seasonTwo.where((level) => level.rows == 6), hasLength(17));
    final expertThroughGrandmaster = levels.skip(40);
    expect(
      expertThroughGrandmaster.every(
        (level) =>
            level.rows == 6 &&
            level.columns == 6 &&
            level.endpointPairs.length == 4,
      ),
      isTrue,
    );
  });

  test(
    'every stored solution connects pairs without crossing and covers board',
    () {
      for (final level in levels) {
        expect(level.solutions, isNotEmpty);
        for (final solution in level.solutions) {
          final errors = const PuzzleSolutionValidator().validate(
            level,
            solution,
          );
          expect(errors, isEmpty, reason: '${level.id}: $errors');
          final board = PathBoard(level);
          for (final path in solution.paths) {
            _drawPath(board, path.cells);
          }
          expect(board.isBoardFullyCovered, isTrue, reason: level.id);
          expect(board.isSolved, isTrue, reason: level.id);
        }
      }
    },
  );
}

void _drawPath(PathBoard board, List<GridCell> cells) {
  expect(board.begin(cells.first), isTrue);
  for (final cell in cells.skip(1)) {
    expect(board.moveTo(cell), isTrue);
  }
  expect(board.end(), isTrue);
}
