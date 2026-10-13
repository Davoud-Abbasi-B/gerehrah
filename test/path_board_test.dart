import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/game/path_board.dart';
import 'package:gerehrah/game/puzzle_level.dart';

late List<PuzzleLevel> starterLevels;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    starterLevels = await LevelRepository().loadLevels();
  });

  group('PathBoard continuation', () {
    test('continues an unfinished path from its last cell', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.end();

      expect(board.begin(const GridCell(0, 1)), isTrue);
      expect(board.moveTo(const GridCell(1, 1)), isTrue);
      expect(board.pathFor(PathColor.blue), const [
        GridCell(0, 0),
        GridCell(0, 1),
        GridCell(1, 1),
      ]);
    });

    test('does not start from a middle cell', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.moveTo(const GridCell(1, 1));
      board.end();

      expect(board.begin(const GridCell(0, 1)), isFalse);
      expect(board.moveTo(const GridCell(0, 2)), isFalse);
    });

    test('starting from either endpoint restarts that color path', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.end();

      expect(board.begin(const GridCell(3, 0)), isTrue);
      expect(board.pathFor(PathColor.blue), const [GridCell(3, 0)]);
    });

    test('does not extend a completed path from its last cell', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(1, 0));
      board.moveTo(const GridCell(2, 0));
      board.moveTo(const GridCell(3, 0));
      board.end();

      expect(board.isComplete(PathColor.blue), isTrue);
      // The last cell is also an endpoint, so it restarts instead of extending.
      expect(board.begin(const GridCell(3, 0)), isTrue);
      expect(board.pathFor(PathColor.blue), const [GridCell(3, 0)]);
    });

    test(
      'preserves collision and orthogonal movement rules after resuming',
      () {
        final board = _newBoard();
        board.begin(const GridCell(0, 0));
        board.moveTo(const GridCell(0, 1));
        board.end();
        board.begin(const GridCell(0, 1));

        expect(board.moveTo(const GridCell(1, 2)), isFalse);
        expect(board.moveTo(const GridCell(0, 2)), isTrue);
        expect(board.moveTo(const GridCell(0, 3)), isFalse);
      },
    );
  });

  group('PathBoard backtracking', () {
    test('trims every cell after an earlier revisited cell', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.moveTo(const GridCell(1, 1));
      board.moveTo(const GridCell(1, 0));

      expect(board.moveTo(const GridCell(0, 0)), isTrue);
      expect(board.pathFor(PathColor.blue), const [GridCell(0, 0)]);
    });

    test('continues normally from the trimmed endpoint without a loop', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.moveTo(const GridCell(1, 1));
      board.moveTo(const GridCell(1, 0));
      board.moveTo(const GridCell(0, 0));

      expect(board.moveTo(const GridCell(1, 0)), isTrue);
      expect(board.moveTo(const GridCell(2, 0)), isTrue);
      expect(board.pathFor(PathColor.blue), const [
        GridCell(0, 0),
        GridCell(1, 0),
        GridCell(2, 0),
      ]);
    });

    test('trimming works after resuming an unfinished path', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.moveTo(const GridCell(1, 1));
      board.moveTo(const GridCell(1, 0));
      board.end();

      expect(board.begin(const GridCell(1, 0)), isTrue);
      expect(board.moveTo(const GridCell(0, 0)), isTrue);
      expect(board.pathFor(PathColor.blue), const [GridCell(0, 0)]);
    });
  });

  group('PathBoard completion', () {
    test(
      'completed path cannot extend during the same drag and records one move',
      () {
        final board = _newBoard();
        const completedPath = [
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(2, 0),
          GridCell(3, 0),
        ];

        expect(board.begin(completedPath.first), isTrue);
        for (final cell in completedPath.skip(1)) {
          expect(board.moveTo(cell), isTrue);
        }
        expect(board.isComplete(PathColor.blue), isTrue);
        expect(board.moveTo(const GridCell(3, 1)), isFalse);
        expect(board.pathFor(PathColor.blue), completedPath);
        expect(board.timer.hasStarted, isFalse);

        expect(board.end(), isTrue);
        expect(board.moveCount, 1);
        expect(board.pathFor(PathColor.blue), completedPath);
      },
    );

    test('every move after same-drag completion leaves the path unchanged', () {
      final board = _newBoard();
      const completedPath = [
        GridCell(0, 0),
        GridCell(1, 0),
        GridCell(2, 0),
        GridCell(3, 0),
      ];

      expect(board.begin(completedPath.first), isTrue);
      for (final cell in completedPath.skip(1)) {
        expect(board.moveTo(cell), isTrue);
      }
      for (final cell in const [
        GridCell(3, 1),
        GridCell(2, 0),
        GridCell(3, 1),
      ]) {
        expect(board.moveTo(cell), isFalse);
        expect(board.pathFor(PathColor.blue), completedPath);
      }

      expect(board.end(), isTrue);
      expect(board.moveCount, 1);
    });

    test('either endpoint still restarts a completed path for redrawing', () {
      for (final restart in const [GridCell(0, 0), GridCell(3, 0)]) {
        final board = _newBoard();
        _drawPath(board, const [
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(2, 0),
          GridCell(3, 0),
        ]);

        expect(board.isComplete(PathColor.blue), isTrue);
        expect(board.begin(restart), isTrue);
        expect(board.pathFor(PathColor.blue), [restart]);
      }
    });

    test(
      'backtracking still works before the matching endpoint is reached',
      () {
        final board = _newBoard();
        expect(board.begin(const GridCell(0, 0)), isTrue);
        expect(board.moveTo(const GridCell(0, 1)), isTrue);
        expect(board.moveTo(const GridCell(1, 1)), isTrue);
        expect(board.moveTo(const GridCell(1, 0)), isTrue);

        expect(board.isComplete(PathColor.blue), isFalse);
        expect(board.moveTo(const GridCell(0, 0)), isTrue);
        expect(board.pathFor(PathColor.blue), const [GridCell(0, 0)]);
      },
    );

    test('undo and reset work after rejected completed-path extensions', () {
      final board = _newBoard();
      const completedPath = [
        GridCell(0, 0),
        GridCell(1, 0),
        GridCell(2, 0),
        GridCell(3, 0),
      ];

      expect(board.begin(completedPath.first), isTrue);
      for (final cell in completedPath.skip(1)) {
        expect(board.moveTo(cell), isTrue);
      }
      expect(board.moveTo(const GridCell(3, 1)), isFalse);
      expect(board.end(), isTrue);
      expect(board.undo(), isTrue);
      expect(board.pathFor(PathColor.blue), isEmpty);
      expect(board.moveCount, 0);

      _drawPath(board, completedPath);
      expect(board.moveCount, 1);
      board.reset();
      expect(board.pathFor(PathColor.blue), isEmpty);
      expect(board.moveCount, 0);
      expect(board.canUndo, isFalse);
    });

    test('is not solved when all colors connect but cells remain empty', () {
      final board = _newBoard();
      _drawPath(board, const [
        GridCell(0, 0),
        GridCell(1, 0),
        GridCell(2, 0),
        GridCell(3, 0),
      ]);
      _drawPath(board, const [
        GridCell(0, 3),
        GridCell(1, 3),
        GridCell(2, 3),
        GridCell(3, 3),
      ]);

      expect(board.isComplete(PathColor.blue), isTrue);
      expect(board.isComplete(PathColor.red), isTrue);
      expect(board.isBoardFullyCovered, isFalse);
      expect(board.isSolved, isFalse);
    });

    test('is solved when all colors connect and every cell is covered', () {
      final board = _newBoard();
      _drawPath(board, const [
        GridCell(0, 0),
        GridCell(0, 1),
        GridCell(1, 1),
        GridCell(1, 0),
        GridCell(2, 0),
        GridCell(2, 1),
        GridCell(3, 1),
        GridCell(3, 0),
      ]);
      _drawPath(board, const [
        GridCell(0, 3),
        GridCell(0, 2),
        GridCell(1, 2),
        GridCell(1, 3),
        GridCell(2, 3),
        GridCell(2, 2),
        GridCell(3, 2),
        GridCell(3, 3),
      ]);

      expect(board.isBoardFullyCovered, isTrue);
      expect(board.isSolved, isTrue);
    });
  });

  group('PathBoard moves and undo', () {
    test('one multi-cell drag counts as one move', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      board.moveTo(const GridCell(0, 1));
      board.moveTo(const GridCell(1, 1));
      board.moveTo(const GridCell(1, 0));

      expect(board.end(), isTrue);
      expect(board.moveCount, 1);
    });

    test('a tap or no-op drag does not count or alter a path', () {
      final board = _newBoard();
      board.begin(const GridCell(0, 0));
      expect(board.end(), isFalse);
      expect(board.moveCount, 0);
      expect(board.pathFor(PathColor.blue), isEmpty);

      board.begin(const GridCell(0, 0));
      expect(board.moveTo(const GridCell(1, 1)), isFalse);
      expect(board.end(), isFalse);
      expect(board.moveCount, 0);
    });

    test(
      'undo restores the state before a continued drag and decrements moves',
      () {
        final board = _newBoard();
        _drawPath(board, const [GridCell(0, 0), GridCell(0, 1)]);
        _drawPath(board, const [GridCell(0, 1), GridCell(1, 1)]);

        expect(board.moveCount, 2);
        expect(board.undo(), isTrue);
        expect(board.moveCount, 1);
        expect(board.pathFor(PathColor.blue), const [
          GridCell(0, 0),
          GridCell(0, 1),
        ]);
      },
    );

    test('undo restores trimmed and restarted paths', () {
      final board = _newBoard();
      _drawPath(board, const [
        GridCell(0, 0),
        GridCell(0, 1),
        GridCell(1, 1),
        GridCell(1, 0),
      ]);
      _drawPath(board, const [GridCell(1, 0), GridCell(0, 0)]);
      expect(board.undo(), isTrue);
      expect(board.pathFor(PathColor.blue), const [
        GridCell(0, 0),
        GridCell(0, 1),
        GridCell(1, 1),
        GridCell(1, 0),
      ]);

      _drawPath(board, const [GridCell(3, 0), GridCell(3, 1)]);
      expect(board.undo(), isTrue);
      expect(board.pathFor(PathColor.blue), const [
        GridCell(0, 0),
        GridCell(0, 1),
        GridCell(1, 1),
        GridCell(1, 0),
      ]);
    });

    test('reset clears paths, history, and move count', () {
      final board = _newBoard();
      _drawPath(board, const [GridCell(0, 0), GridCell(0, 1)]);

      board.reset();

      expect(board.moveCount, 0);
      expect(board.canUndo, isFalse);
      expect(board.pathFor(PathColor.blue), isEmpty);
    });
  });
}

PathBoard _newBoard() => PathBoard(starterLevels.first);

void _drawPath(PathBoard board, List<GridCell> cells) {
  expect(board.begin(cells.first), isTrue);
  for (final cell in cells.skip(1)) {
    expect(board.moveTo(cell), isTrue);
  }
  board.end();
}
