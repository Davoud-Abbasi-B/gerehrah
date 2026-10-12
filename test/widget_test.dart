import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/analytics/app_analytics_service.dart';
import 'package:pathly/game/grid_cell.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/level_timer.dart';
import 'package:pathly/game/path_board.dart';
import 'package:pathly/game/pathly_game.dart';
import 'package:pathly/game/pathly_screen.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/progress/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> levels;

  setUpAll(() async {
    levels = await LevelRepository().loadLevels();
  });

  testWidgets('shows move controls with progression initially locked', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(home: PathlyScreen(levels: levels)));

    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Moves: 0'), findsOneWidget);
    expect(find.text('Time: 00:00'), findsOneWidget);
    expect(find.textContaining('Hints:'), findsNothing);
    expect(find.byKey(const Key('hint')), findsNothing);
    expect(find.text('Connected!'), findsNothing);
    expect(find.text('Level 1 • Crossroads'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('undo'))).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next-level')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'saved completion marks level number but not unsolved current title',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferencesProgressRepository().saveCompletedLevel(
        levelId: 'crossroads-4',
        moves: 7,
        timeSeconds: 65,
      );

      await tester.pumpWidget(MaterialApp(home: PathlyScreen(levels: levels)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Level 1 • Crossroads'), findsOneWidget);
      expect(find.text('1 ✓'), findsOneWidget);
      expect(find.byKey(const Key('title-solved-indicator')), findsNothing);
      expect(find.text('Best Moves: 7  •  Best Time: 01:05'), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byKey(const Key('level-2'))).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('title solved indicator follows solve, undo, and reset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late PathBoard board;
    await tester.pumpWidget(
      MaterialApp(
        home: PathlyScreen(
          levels: levels,
          boardFactory: (level) {
            board = PathBoard(level);
            return board;
          },
        ),
      ),
    );

    _drawPath(board, _solution.first);
    _drawPath(board, _solution.last);
    await _pumpGameState(tester);
    expect(find.byKey(const Key('title-solved-indicator')), findsOneWidget);

    await tester.tap(find.byKey(const Key('undo')));
    await _pumpGameState(tester);
    expect(find.byKey(const Key('title-solved-indicator')), findsNothing);

    _drawPath(board, _solution.last);
    await _pumpGameState(tester);
    expect(find.byKey(const Key('title-solved-indicator')), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await _pumpGameState(tester);
    expect(find.byKey(const Key('title-solved-indicator')), findsNothing);
  });

  testWidgets('game update notification during a frame is lifecycle-safe', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final source = _FakeTimeSource();
    late PathBoard board;
    await tester.pumpWidget(
      MaterialApp(
        home: PathlyScreen(
          levels: levels,
          boardFactory: (level) {
            board = PathBoard(level, timer: LevelTimer(source: source));
            return board;
          },
        ),
      ),
    );

    board.begin(const GridCell(0, 0));
    board.moveTo(const GridCell(0, 1));
    board.end();
    source.advance(const Duration(seconds: 1));

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Time: 00:01'), findsOneWidget);
  });

  testWidgets(
    'completion logs once with gameplay metrics and replay logs again',
    (tester) async {
      final source = _FakeTimeSource();
      final analytics = _FakeAnalyticsService();
      final repository = _MemoryProgressRepository();
      late PathBoard board;
      await tester.pumpWidget(
        MaterialApp(
          home: PathlyScreen(
            levels: levels,
            progressRepository: repository,
            analyticsService: analytics,
            boardFactory: (level) {
              board = PathBoard(level, timer: LevelTimer(source: source));
              return board;
            },
          ),
        ),
      );
      await tester.pump();

      expect(analytics.completions, isEmpty);
      await tester.tap(find.text('Reset'));
      await _pumpGameState(tester);
      expect(analytics.completions, isEmpty);

      _drawPath(board, _solution.first);
      source.advance(const Duration(seconds: 42));
      _drawPath(board, _solution.last);
      await _pumpGameState(tester);

      expect(analytics.completions, [
        (
          levelId: 'crossroads-4',
          seasonNumber: 1,
          levelNumber: 1,
          moves: 2,
          completionTimeSeconds: 42,
        ),
      ]);
      expect(repository.completedLevels, contains('crossroads-4'));

      await tester.pump();
      expect(analytics.completions, hasLength(1));

      await tester.tap(find.byKey(const Key('undo')));
      await _pumpGameState(tester);
      _drawPath(board, _solution.last);
      await _pumpGameState(tester);
      expect(analytics.completions, hasLength(2));
    },
  );

  testWidgets('analytics failure does not interrupt completion saving', (
    tester,
  ) async {
    final analytics = _FakeAnalyticsService(error: StateError('offline'));
    final repository = _MemoryProgressRepository();
    late PathBoard board;
    await tester.pumpWidget(
      MaterialApp(
        home: PathlyScreen(
          levels: levels,
          progressRepository: repository,
          analyticsService: analytics,
          boardFactory: (level) {
            board = PathBoard(level);
            return board;
          },
        ),
      ),
    );

    _drawPath(board, _solution.first);
    _drawPath(board, _solution.last);
    await _pumpGameState(tester);

    expect(analytics.completionCalls, 1);
    expect(repository.completedLevels, contains('crossroads-4'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid drag keeps board state and move count and logs once per gesture',
    (tester) async {
      final analytics = _FakeAnalyticsService();
      late PathBoard board;
      await tester.pumpWidget(
        MaterialApp(
          home: PathlyScreen(
            levels: levels,
            analyticsService: analytics,
            boardFactory: (level) {
              board = PathBoard(level);
              return board;
            },
          ),
        ),
      );
      await tester.pump();

      final gameRect = tester.getRect(
        find.byKey(const ValueKey('crossroads-4')),
      );
      final cellSize = (gameRect.width - PathlyGame.gridPadding * 2) / 4;
      Offset center(int row, int column) => Offset(
        gameRect.left + PathlyGame.gridPadding + (column + 0.5) * cellSize,
        gameRect.top + PathlyGame.gridPadding + (row + 0.5) * cellSize,
      );
      final gesture = await tester.startGesture(center(0, 0));
      await gesture.moveTo(center(1, 1));
      await gesture.moveTo(center(2, 2));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 20));

      expect(board.moveCount, 0);
      expect(board.pathFor(PathColor.blue), isEmpty);
      expect(analytics.invalidMoveCalls, 1);
      expect(find.byKey(const Key('invalid-move-feedback')), findsOneWidget);
    },
  );
}

class _FakeTimeSource implements ElapsedTimeSource {
  Duration _now = Duration.zero;

  @override
  Duration get now => _now;

  void advance(Duration duration) => _now += duration;
}

class _MemoryProgressRepository implements ProgressRepository {
  final Map<String, LevelBestResult> completedLevels = {};

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

class _FakeAnalyticsService implements AppAnalyticsService {
  _FakeAnalyticsService({this.error});

  final Object? error;
  int invalidMoveCalls = 0;
  int completionCalls = 0;
  final List<
    ({
      String levelId,
      int seasonNumber,
      int levelNumber,
      int moves,
      int completionTimeSeconds,
    })
  >
  completions = [];

  @override
  Future<void> logShareAppClick() async {}

  @override
  Future<void> logTutorialView() async {}

  @override
  Future<void> logTutorialComplete() async {}

  @override
  Future<void> logInvalidMove() async {
    invalidMoveCalls++;
    final error = this.error;
    if (error != null) throw error;
  }

  @override
  Future<void> logLevelComplete({
    required String levelId,
    required int seasonNumber,
    required int levelNumber,
    required int moves,
    required int completionTimeSeconds,
  }) async {
    completionCalls++;
    final error = this.error;
    if (error != null) throw error;
    completions.add((
      levelId: levelId,
      seasonNumber: seasonNumber,
      levelNumber: levelNumber,
      moves: moves,
      completionTimeSeconds: completionTimeSeconds,
    ));
  }
}

Future<void> _pumpGameState(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void _drawPath(PathBoard board, List<GridCell> cells) {
  board.begin(cells.first);
  for (final cell in cells.skip(1)) {
    board.moveTo(cell);
  }
  board.end();
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
