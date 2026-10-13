import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/game/level_progression.dart';
import 'package:gerehrah/game/level_timer.dart';
import 'package:gerehrah/game/path_board.dart';
import 'package:gerehrah/game/puzzle_level.dart';

late List<PuzzleLevel> starterLevels;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    starterLevels = await LevelRepository().loadLevels();
  });

  test('timer stays at zero before the first meaningful move', () {
    final source = FakeTimeSource();
    final board = _boardWith(source);
    source.advance(const Duration(seconds: 20));

    board.begin(const GridCell(0, 0));
    expect(board.end(), isFalse);
    source.advance(const Duration(seconds: 5));

    expect(board.timer.formatted, '00:00');
    expect(board.timer.hasStarted, isFalse);
    expect(board.timer.isRunning, isFalse);
  });

  test('timer starts after one meaningful drag', () {
    final source = FakeTimeSource();
    final board = _boardWith(source);

    _drawPath(board, const [GridCell(0, 0), GridCell(0, 1)]);
    source.advance(const Duration(seconds: 65));

    expect(board.timer.hasStarted, isTrue);
    expect(board.timer.isRunning, isTrue);
    expect(board.timer.formatted, '01:05');
  });

  test('timer locks when the puzzle is solved', () {
    final source = FakeTimeSource();
    final board = _boardWith(source);
    _drawPath(board, _solution.first);
    source.advance(const Duration(seconds: 12));
    _drawPath(board, _solution.last);

    expect(board.isSolved, isTrue);
    expect(board.timer.isRunning, isFalse);
    expect(board.timer.elapsed, const Duration(seconds: 12));

    source.advance(const Duration(seconds: 30));
    expect(board.timer.elapsed, const Duration(seconds: 12));
  });

  test('reset clears the timer', () {
    final source = FakeTimeSource();
    final board = _boardWith(source);
    _drawPath(board, const [GridCell(0, 0), GridCell(0, 1)]);
    source.advance(const Duration(seconds: 8));

    board.reset();

    expect(board.timer.formatted, '00:00');
    expect(board.timer.hasStarted, isFalse);
    expect(board.timer.isRunning, isFalse);
  });

  test('changing levels creates a cleared timer', () {
    final source = FakeTimeSource();
    final progression = LevelProgression(
      starterLevels,
      boardFactory: (level) =>
          PathBoard(level, timer: LevelTimer(source: source)),
    );
    _drawPath(progression.board, _solution.first);
    source.advance(const Duration(seconds: 9));
    _drawPath(progression.board, _solution.last);

    expect(progression.goNext(), isTrue);
    expect(progression.board.timer.formatted, '00:00');
    expect(progression.board.timer.hasStarted, isFalse);
  });

  test('undoing a solution resumes from the locked elapsed time', () {
    final source = FakeTimeSource();
    final board = _boardWith(source);
    _drawPath(board, _solution.first);
    source.advance(const Duration(seconds: 14));
    _drawPath(board, _solution.last);
    final solvedElapsed = board.timer.elapsed;

    source.advance(const Duration(seconds: 20));
    expect(board.undo(), isTrue);
    expect(board.isSolved, isFalse);
    expect(board.timer.isRunning, isTrue);
    expect(board.timer.elapsed, solvedElapsed);

    source.advance(const Duration(seconds: 6));
    expect(board.timer.elapsed, solvedElapsed + const Duration(seconds: 6));
  });
}

PathBoard _boardWith(FakeTimeSource source) =>
    PathBoard(starterLevels.first, timer: LevelTimer(source: source));

void _drawPath(PathBoard board, List<GridCell> cells) {
  expect(board.begin(cells.first), isTrue);
  for (final cell in cells.skip(1)) {
    expect(board.moveTo(cell), isTrue);
  }
  expect(board.end(), isTrue);
}

class FakeTimeSource implements ElapsedTimeSource {
  Duration _now = Duration.zero;

  @override
  Duration get now => _now;

  void advance(Duration duration) => _now += duration;
}

const _solution = [
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
