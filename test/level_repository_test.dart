import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/grid_cell.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LevelRepository', () {
    test('loads all 100 asset levels in stable order', () async {
      final levels = await LevelRepository().loadLevels();

      expect(levels, hasLength(100));
      expect(levels.take(40).map((level) => level.id), [
        'crossroads-4',
        'three-lanes-5',
        'four-bands-6',
        'corner-turn-4',
        'woven-square-4',
        'riverbend-5',
        'switchback-5',
        'courtyard-5',
        'roundabout-5',
        'zigzag-5',
        'tight-turns-5',
        'knotwork-5',
        'divided-paths-6',
        'inner-loop-6',
        'narrow-gates-6',
        'grand-tour-6',
        'spiral-lock-6',
        'cross-current-6',
        'final-weave-6',
        'master-route-6',
        'season-2-01',
        'season-2-02',
        'season-2-03',
        'season-2-04',
        'season-2-05',
        'season-2-06',
        'season-2-07',
        'season-2-08',
        'season-2-09',
        'season-2-10',
        'season-2-11',
        'season-2-12',
        'season-2-13',
        'season-2-14',
        'season-2-15',
        'season-2-16',
        'season-2-17',
        'season-2-18',
        'season-2-19',
        'season-2-20',
      ]);
      for (var season = 3; season <= 5; season++) {
        expect(
          levels.skip((season - 1) * 20).take(20).map((level) => level.id),
          [
            for (var number = 1; number <= 20; number++)
              'season-$season-${number.toString().padLeft(2, '0')}',
          ],
        );
      }
      expect(levels.take(3).map((level) => (level.rows, level.columns)), [
        (4, 4),
        (5, 5),
        (6, 6),
      ]);
      expect(
        levels.first.endpointPairs.map(
          (pair) => (pair.color, pair.first, pair.second),
        ),
        [
          (PathColor.blue, const GridCell(0, 0), const GridCell(3, 0)),
          (PathColor.red, const GridCell(0, 3), const GridCell(3, 3)),
        ],
      );
      expect(
        levels[1].endpointPairs.map(
          (pair) => (pair.color, pair.first, pair.second),
        ),
        [
          (PathColor.blue, const GridCell(0, 0), const GridCell(0, 4)),
          (PathColor.red, const GridCell(1, 0), const GridCell(2, 0)),
          (PathColor.green, const GridCell(3, 0), const GridCell(4, 0)),
        ],
      );
      expect(
        levels[2].endpointPairs.map(
          (pair) => (pair.color, pair.first, pair.second),
        ),
        [
          (PathColor.blue, const GridCell(0, 0), const GridCell(0, 5)),
          (PathColor.red, const GridCell(1, 0), const GridCell(2, 0)),
          (PathColor.green, const GridCell(3, 0), const GridCell(3, 5)),
          (PathColor.yellow, const GridCell(4, 0), const GridCell(5, 0)),
        ],
      );
      expect(levels.map((level) => level.id).toSet(), hasLength(100));
    });

    test('preserves the original three levels exactly', () async {
      final levels = (await LevelRepository().loadLevels()).take(3).toList();

      expect(levels.map((level) => level.title), [
        'Crossroads',
        'Three Lanes',
        'Four Bands',
      ]);
      expect(_encodedSolutions(levels[0]), const [
        'blue:0,0|0,1|1,1|1,0|2,0|2,1|3,1|3,0;'
            'red:0,3|0,2|1,2|1,3|2,3|2,2|3,2|3,3',
        'blue:0,0|1,0|2,0|3,0;'
            'red:0,3|0,2|0,1|1,1|1,2|1,3|2,3|2,2|2,1|3,1|3,2|3,3',
      ]);
      expect(_encodedSolutions(levels[1]), const [
        'blue:0,0|0,1|0,2|0,3|0,4;'
            'red:1,0|1,1|1,2|1,3|1,4|2,4|2,3|2,2|2,1|2,0;'
            'green:3,0|3,1|3,2|3,3|3,4|4,4|4,3|4,2|4,1|4,0',
      ]);
      expect(_encodedSolutions(levels[2]), const [
        'blue:0,0|0,1|0,2|0,3|0,4|0,5;'
            'red:1,0|1,1|1,2|1,3|1,4|1,5|2,5|2,4|2,3|2,2|2,1|2,0;'
            'green:3,0|3,1|3,2|3,3|3,4|3,5;'
            'yellow:4,0|4,1|4,2|4,3|4,4|4,5|5,5|5,4|5,3|5,2|5,1|5,0',
      ]);
    });

    test('rejects invalid JSON', () {
      expect(
        () => LevelRepository().parseLevels('{not valid JSON'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate level IDs', () {
      expect(
        () => _parse([_validLevel(), _validLevel()]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Duplicate level ID'),
          ),
        ),
      );
    });

    test('rejects invalid board dimensions', () {
      final level = _validLevel()..['rows'] = 0;

      expect(
        () => _parse([level]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('invalid board dimensions'),
          ),
        ),
      );
    });

    test('rejects out-of-range endpoint cells', () {
      final level = _validLevel();
      final pairs = level['pairs']! as List<dynamic>;
      final pair = pairs.first as Map<String, dynamic>;
      pair['end'] = {'row': 2, 'column': 0};

      expect(
        () => _parse([level]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('out-of-range pair end'),
          ),
        ),
      );
    });

    test('rejects identical pair endpoints', () {
      final level = _validLevel();
      final pairs = level['pairs']! as List<dynamic>;
      final pair = pairs.first as Map<String, dynamic>;
      pair['end'] = {'row': 0, 'column': 0};

      expect(
        () => _parse([level]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('identical start and end'),
          ),
        ),
      );
    });

    test('rejects unsupported colors', () {
      final level = _validLevel();
      final pairs = level['pairs']! as List<dynamic>;
      final pair = pairs.first as Map<String, dynamic>;
      pair['color'] = 'purple';

      expect(
        () => _parse([level]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported path color'),
          ),
        ),
      );
    });
  });

  group('application level loading', () {
    testWidgets('shows a loading state until levels are available', (
      tester,
    ) async {
      final completer = Completer<List<PuzzleLevel>>();
      await tester.pumpWidget(
        PathlyApp(levelRepository: _TestLevelRepository(completer.future)),
      );

      expect(find.byKey(const Key('level-loading')), findsOneWidget);
      expect(find.text('Select a Level'), findsNothing);

      completer.complete(
        List<PuzzleLevel>.generate(
          20,
          (index) => PuzzleLevel(
            id: 'test-level-$index',
            title: 'Test Level $index',
            rows: 2,
            columns: 2,
            endpointPairs: const [
              EndpointPair(
                color: PathColor.blue,
                first: GridCell(0, 0),
                second: GridCell(1, 1),
              ),
            ],
            solutions: const [
              PuzzleSolution(
                paths: [
                  SolutionPath(
                    color: PathColor.blue,
                    cells: [GridCell(0, 0), GridCell(0, 1), GridCell(1, 1)],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('level-loading')), findsNothing);
      expect(find.text('Select a Level'), findsOneWidget);
    });

    testWidgets('shows a readable error when level loading fails', (
      tester,
    ) async {
      final completer = Completer<List<PuzzleLevel>>();
      await tester.pumpWidget(
        PathlyApp(levelRepository: _TestLevelRepository(completer.future)),
      );

      completer.completeError(const FormatException('Broken level data.'));
      await tester.pump();

      expect(find.byKey(const Key('level-load-error')), findsOneWidget);
      expect(find.textContaining('Unable to load levels'), findsOneWidget);
      expect(find.textContaining('Broken level data'), findsOneWidget);
    });
  });
}

List<String> _encodedSolutions(PuzzleLevel level) {
  return [
    for (final solution in level.solutions)
      solution.paths
          .map(
            (path) =>
                '${path.color.name}:'
                '${path.cells.map((cell) => '${cell.row},${cell.column}').join('|')}',
          )
          .join(';'),
  ];
}

List<PuzzleLevel> _parse(List<Map<String, dynamic>> levels) {
  return LevelRepository().parseLevels(jsonEncode({'levels': levels}));
}

Map<String, dynamic> _validLevel() {
  return {
    'id': 'test-level',
    'title': 'Test Level',
    'rows': 2,
    'columns': 2,
    'pairs': [
      {
        'color': 'blue',
        'start': {'row': 0, 'column': 0},
        'end': {'row': 1, 'column': 1},
      },
    ],
    'solutions': [
      {
        'paths': [
          {
            'color': 'blue',
            'cells': [
              {'row': 0, 'column': 0},
              {'row': 0, 'column': 1},
              {'row': 1, 'column': 1},
            ],
          },
        ],
      },
    ],
  };
}

class _TestLevelRepository extends LevelRepository {
  _TestLevelRepository(this.result);

  final Future<List<PuzzleLevel>> result;

  @override
  Future<List<PuzzleLevel>> loadLevels() => result;
}
