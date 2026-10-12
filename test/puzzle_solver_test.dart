import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/grid_cell.dart';
import 'package:pathly/game/puzzle_level.dart';
import 'package:pathly/game/puzzle_solution_validator.dart';
import 'package:pathly/game/puzzle_solver.dart';

void main() {
  const solver = PuzzleSolver();
  const validator = PuzzleSolutionValidator();

  test('finds the only full-board orthogonal solution', () {
    final result = solver.solve(_singlePairLevel(2, 2));

    expect(result.solutionCount, 1);
    expect(result.isSolvable, isTrue);
    expect(result.isUnique, isTrue);
    expect(result.searchCompleted, isTrue);
    expect(
      validator.isValid(_singlePairLevel(2, 2), result.solutions.single),
      isTrue,
    );
    expect(result.solutions.single.pathFor(PathColor.blue), const [
      GridCell(0, 0),
      GridCell(1, 0),
      GridCell(1, 1),
      GridCell(0, 1),
    ]);
  });

  test('reports an unsolvable board', () {
    final level = _level(
      rows: 2,
      columns: 2,
      pairs: const [
        EndpointPair(
          color: PathColor.blue,
          first: GridCell(0, 0),
          second: GridCell(1, 1),
        ),
      ],
    );

    final result = solver.solve(level);

    expect(result.solutions, isEmpty);
    expect(result.isSolvable, isFalse);
    expect(result.searchCompleted, isTrue);
  });

  test('finds multiple solutions and stops at the configured maximum', () {
    final level = _level(
      rows: 3,
      columns: 3,
      pairs: const [
        EndpointPair(
          color: PathColor.blue,
          first: GridCell(0, 0),
          second: GridCell(2, 0),
        ),
      ],
    );

    final twoSolutions = solver.solve(level, maximumSolutionCount: 2);
    final oneSolution = solver.solve(level, maximumSolutionCount: 1);

    expect(twoSolutions.solutionCount, 2);
    expect(twoSolutions.searchCompleted, isFalse);
    expect(twoSolutions.isUnique, isFalse);
    expect(oneSolution.solutionCount, 1);
    expect(oneSolution.searchCompleted, isFalse);
  });

  test(
    'solutions are orthogonal, disjoint, non-crossing, and cover the board',
    () {
      final level = _twoColorLevel();
      final result = solver.solve(level, maximumSolutionCount: 2);

      expect(result.isSolvable, isTrue);
      for (final solution in result.solutions) {
        expect(validator.validate(level, solution), isEmpty);
        final occupied = <GridCell>{};
        for (final path in solution.paths) {
          for (var index = 1; index < path.cells.length; index++) {
            expect(
              path.cells[index - 1].isAdjacentTo(path.cells[index]),
              isTrue,
            );
          }
          for (final cell in path.cells) {
            expect(occupied.add(cell), isTrue, reason: 'shared cell $cell');
            for (final pair in level.endpointPairs) {
              if (pair.color != path.color) {
                expect(pair.positions, isNot(contains(cell)));
              }
            }
          }
        }
        expect(occupied, hasLength(level.rows * level.columns));
      }
    },
  );

  test('is deterministic and does not mutate the input level', () {
    final level = _twoColorLevel();
    final originalPairs = List<EndpointPair>.of(level.endpointPairs);
    final originalSolutions = List<PuzzleSolution>.of(level.solutions);

    final first = solver.solve(level, maximumSolutionCount: 2);
    final second = solver.solve(level, maximumSolutionCount: 2);

    expect(_solutionCells(first.solutions), _solutionCells(second.solutions));
    expect(level.endpointPairs, orderedEquals(originalPairs));
    expect(level.solutions, orderedEquals(originalSolutions));
  });

  test('rejects a non-positive solution limit', () {
    expect(
      () => solver.solve(_singlePairLevel(2, 2), maximumSolutionCount: 0),
      throwsArgumentError,
    );
  });
}

PuzzleLevel _singlePairLevel(int rows, int columns) {
  return _level(
    rows: rows,
    columns: columns,
    pairs: [
      EndpointPair(
        color: PathColor.blue,
        first: const GridCell(0, 0),
        second: GridCell(0, columns - 1),
      ),
    ],
  );
}

PuzzleLevel _twoColorLevel() {
  return _level(
    rows: 3,
    columns: 3,
    pairs: const [
      EndpointPair(
        color: PathColor.blue,
        first: GridCell(0, 0),
        second: GridCell(0, 2),
      ),
      EndpointPair(
        color: PathColor.red,
        first: GridCell(1, 0),
        second: GridCell(2, 0),
      ),
    ],
  );
}

PuzzleLevel _level({
  required int rows,
  required int columns,
  required List<EndpointPair> pairs,
  List<PuzzleSolution> solutions = const [],
}) {
  return PuzzleLevel(
    id: 'test',
    title: 'Test',
    rows: rows,
    columns: columns,
    endpointPairs: pairs,
    solutions: solutions,
  );
}

List<List<List<GridCell>>> _solutionCells(List<PuzzleSolution> solutions) {
  return [
    for (final solution in solutions)
      [for (final path in solution.paths) List<GridCell>.of(path.cells)],
  ];
}
