import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/level_quality_validator.dart';
import 'package:gerehrah/game/puzzle_level.dart';

void main() {
  const validator = LevelQualityValidator();

  test('classifies unique, unsolvable, and multiple-solution levels', () {
    final unique = validator.validate(
      _level(
        rows: 2,
        columns: 2,
        first: const GridCell(0, 0),
        second: const GridCell(0, 1),
      ),
    );
    final unsolvable = validator.validate(
      _level(
        rows: 2,
        columns: 2,
        first: const GridCell(0, 0),
        second: const GridCell(1, 1),
      ),
    );
    final multiple = validator.validate(
      _level(
        rows: 3,
        columns: 3,
        first: const GridCell(0, 0),
        second: const GridCell(2, 0),
      ),
    );

    expect(unique.isUniquelySolvable, isTrue);
    expect(unsolvable.isUnsolvable, isTrue);
    expect(unsolvable.hasErrors, isTrue);
    expect(multiple.hasMultipleSolutions, isTrue);
    expect(multiple.hasWarnings, isTrue);
  });

  test('reports duplicate and cross-color endpoint cells', () {
    final level = PuzzleLevel(
      id: 'duplicates',
      title: 'Duplicates',
      rows: 2,
      columns: 2,
      endpointPairs: const [
        EndpointPair(
          color: PathColor.blue,
          first: GridCell(0, 0),
          second: GridCell(0, 0),
        ),
        EndpointPair(
          color: PathColor.red,
          first: GridCell(0, 0),
          second: GridCell(1, 1),
        ),
      ],
      solutions: const [],
    );

    final codes = validator
        .validate(level)
        .issues
        .map((issue) => issue.code)
        .toSet();

    expect(codes, contains(LevelValidationIssueCode.duplicateEndpointCell));
    expect(
      codes,
      contains(LevelValidationIssueCode.endpointSharedBetweenColors),
    );
  });

  test('reports a malformed stored solution without throwing', () {
    final level = PuzzleLevel(
      id: 'malformed-solution',
      title: 'Malformed Solution',
      rows: 2,
      columns: 2,
      endpointPairs: const [
        EndpointPair(
          color: PathColor.blue,
          first: GridCell(0, 0),
          second: GridCell(0, 1),
        ),
      ],
      solutions: const [PuzzleSolution(paths: [])],
    );

    final report = validator.validate(level);

    expect(report.hasErrors, isTrue);
    expect(
      report.issues.map((issue) => issue.code),
      contains(LevelValidationIssueCode.invalidStoredSolution),
    );
  });
}

PuzzleLevel _level({
  required int rows,
  required int columns,
  required GridCell first,
  required GridCell second,
}) {
  return PuzzleLevel(
    id: 'quality-test',
    title: 'Quality Test',
    rows: rows,
    columns: columns,
    endpointPairs: [
      EndpointPair(color: PathColor.blue, first: first, second: second),
    ],
    solutions: const [],
  );
}
