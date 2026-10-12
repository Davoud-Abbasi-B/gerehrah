import 'grid_cell.dart';
import 'puzzle_level.dart';

enum PuzzleSolutionIssueCode {
  missingOrDuplicatePath,
  unexpectedPath,
  wrongEndpoints,
  emptyPath,
  selfOverlap,
  diagonalStep,
  disconnectedPath,
  cellOutsideBoard,
  overlappingPaths,
  pathThroughOtherEndpoint,
  incompleteBoardCoverage,
  unexpectedPathCount,
}

class PuzzleSolutionIssue {
  const PuzzleSolutionIssue({
    required this.code,
    required this.message,
    this.color,
  });

  final PuzzleSolutionIssueCode code;
  final String message;
  final PathColor? color;
}

class PuzzleSolutionValidator {
  const PuzzleSolutionValidator();

  List<PuzzleSolutionIssue> validateDetailed(
    PuzzleLevel level,
    PuzzleSolution solution,
  ) {
    final issues = <PuzzleSolutionIssue>[];
    final occupied = <GridCell, PathColor>{};
    final endpointOwners = <GridCell, PathColor>{
      for (final pair in level.endpointPairs)
        for (final cell in pair.positions) cell: pair.color,
    };
    for (final pair in level.endpointPairs) {
      final matching = solution.paths.where((path) => path.color == pair.color);
      if (matching.length != 1) {
        issues.add(
          PuzzleSolutionIssue(
            code: PuzzleSolutionIssueCode.missingOrDuplicatePath,
            message: '${pair.color.name}: expected exactly one path',
            color: pair.color,
          ),
        );
        continue;
      }
      final cells = matching.single.cells;
      if (cells.isEmpty) {
        issues.add(
          PuzzleSolutionIssue(
            code: PuzzleSolutionIssueCode.emptyPath,
            message: '${pair.color.name}: path is empty',
            color: pair.color,
          ),
        );
        continue;
      }
      final forward = cells.first == pair.first && cells.last == pair.second;
      final reverse = cells.first == pair.second && cells.last == pair.first;
      if (!forward && !reverse) {
        issues.add(
          PuzzleSolutionIssue(
            code: PuzzleSolutionIssueCode.wrongEndpoints,
            message: '${pair.color.name}: endpoints do not match',
            color: pair.color,
          ),
        );
      }
      if (cells.toSet().length != cells.length) {
        issues.add(
          PuzzleSolutionIssue(
            code: PuzzleSolutionIssueCode.selfOverlap,
            message: '${pair.color.name}: path overlaps itself',
            color: pair.color,
          ),
        );
      }
      for (var index = 1; index < cells.length; index++) {
        if (!cells[index - 1].isAdjacentTo(cells[index])) {
          final rowDifference = (cells[index - 1].row - cells[index].row).abs();
          final columnDifference =
              (cells[index - 1].column - cells[index].column).abs();
          final diagonal = rowDifference == 1 && columnDifference == 1;
          issues.add(
            PuzzleSolutionIssue(
              code: diagonal
                  ? PuzzleSolutionIssueCode.diagonalStep
                  : PuzzleSolutionIssueCode.disconnectedPath,
              message: diagonal
                  ? '${pair.color.name}: path contains a diagonal step'
                  : '${pair.color.name}: path contains disconnected cells',
              color: pair.color,
            ),
          );
        }
      }
      for (final cell in cells) {
        if (cell.row < 0 ||
            cell.row >= level.rows ||
            cell.column < 0 ||
            cell.column >= level.columns) {
          issues.add(
            PuzzleSolutionIssue(
              code: PuzzleSolutionIssueCode.cellOutsideBoard,
              message: '${pair.color.name}: cell outside board',
              color: pair.color,
            ),
          );
        }
        final endpointOwner = endpointOwners[cell];
        if (endpointOwner != null && endpointOwner != pair.color) {
          issues.add(
            PuzzleSolutionIssue(
              code: PuzzleSolutionIssueCode.pathThroughOtherEndpoint,
              message:
                  '${pair.color.name}: path passes through '
                  '${endpointOwner.name} endpoint',
              color: pair.color,
            ),
          );
        }
        final previous = occupied[cell];
        if (previous != null && previous != pair.color) {
          issues.add(
            PuzzleSolutionIssue(
              code: PuzzleSolutionIssueCode.overlappingPaths,
              message: '${pair.color.name}: overlaps ${previous.name}',
              color: pair.color,
            ),
          );
        }
        occupied[cell] = pair.color;
      }
    }
    for (final path in solution.paths) {
      if (!level.endpointPairs.any((pair) => pair.color == path.color)) {
        issues.add(
          PuzzleSolutionIssue(
            code: PuzzleSolutionIssueCode.unexpectedPath,
            message: '${path.color.name}: path has no matching endpoint pair',
            color: path.color,
          ),
        );
      }
    }
    if (solution.paths.length != level.endpointPairs.length) {
      issues.add(
        const PuzzleSolutionIssue(
          code: PuzzleSolutionIssueCode.unexpectedPathCount,
          message: 'solution has an unexpected number of paths',
        ),
      );
    }
    if (occupied.length != level.rows * level.columns) {
      issues.add(
        const PuzzleSolutionIssue(
          code: PuzzleSolutionIssueCode.incompleteBoardCoverage,
          message: 'solution does not cover the full board',
        ),
      );
    }
    return List.unmodifiable(issues);
  }

  List<String> validate(PuzzleLevel level, PuzzleSolution solution) =>
      validateDetailed(
        level,
        solution,
      ).map((issue) => issue.message).toList(growable: false);

  bool isValid(PuzzleLevel level, PuzzleSolution solution) =>
      validateDetailed(level, solution).isEmpty;
}
