import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/game/puzzle_solution_validator.dart';

void main() {
  const validator = PuzzleSolutionValidator();

  test('accepts a valid stored solution', () {
    expect(validator.validateDetailed(_level(), _validSolution()), isEmpty);
  });

  test('reports a disconnected path', () {
    final solution = _solution(blue: const [GridCell(0, 0), GridCell(0, 2)]);

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.disconnectedPath),
    );
  });

  test('reports a diagonal step', () {
    final solution = _solution(
      blue: const [GridCell(0, 0), GridCell(1, 1), GridCell(0, 2)],
    );

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.diagonalStep),
    );
  });

  test('reports wrong endpoints', () {
    final solution = _solution(blue: const [GridCell(0, 0), GridCell(0, 1)]);

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.wrongEndpoints),
    );
  });

  test('reports overlapping paths and crossing attempts', () {
    final solution = PuzzleSolution(
      paths: [
        const SolutionPath(
          color: PathColor.blue,
          cells: [GridCell(0, 0), GridCell(0, 1), GridCell(0, 2)],
        ),
        const SolutionPath(
          color: PathColor.red,
          cells: [
            GridCell(1, 0),
            GridCell(1, 1),
            GridCell(0, 1),
            GridCell(0, 2),
            GridCell(1, 2),
            GridCell(2, 2),
            GridCell(2, 1),
            GridCell(2, 0),
          ],
        ),
      ],
    );

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.overlappingPaths),
    );
  });

  test('reports incomplete board coverage', () {
    final solution = _solution(red: const [GridCell(1, 0), GridCell(2, 0)]);

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.incompleteBoardCoverage),
    );
  });

  test("reports a path through another color's endpoint", () {
    final solution = _solution(
      blue: const [
        GridCell(0, 0),
        GridCell(1, 0),
        GridCell(1, 1),
        GridCell(0, 1),
        GridCell(0, 2),
      ],
    );

    expect(
      _codes(validator, solution),
      contains(PuzzleSolutionIssueCode.pathThroughOtherEndpoint),
    );
  });
}

Set<PuzzleSolutionIssueCode> _codes(
  PuzzleSolutionValidator validator,
  PuzzleSolution solution,
) {
  return validator
      .validateDetailed(_level(), solution)
      .map((issue) => issue.code)
      .toSet();
}

PuzzleLevel _level() {
  return PuzzleLevel(
    id: 'validator-test',
    title: 'Validator Test',
    rows: 3,
    columns: 3,
    endpointPairs: const [
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
    solutions: const [],
  );
}

PuzzleSolution _validSolution() => _solution();

PuzzleSolution _solution({
  List<GridCell> blue = const [GridCell(0, 0), GridCell(0, 1), GridCell(0, 2)],
  List<GridCell> red = const [
    GridCell(1, 0),
    GridCell(1, 1),
    GridCell(1, 2),
    GridCell(2, 2),
    GridCell(2, 1),
    GridCell(2, 0),
  ],
}) {
  return PuzzleSolution(
    paths: [
      SolutionPath(color: PathColor.blue, cells: blue),
      SolutionPath(color: PathColor.red, cells: red),
    ],
  );
}
