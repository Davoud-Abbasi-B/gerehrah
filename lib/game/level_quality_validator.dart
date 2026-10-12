import 'grid_cell.dart';
import 'puzzle_level.dart';
import 'puzzle_solution_validator.dart';
import 'puzzle_solver.dart';

enum LevelValidationSeverity { error, warning }

enum LevelValidationIssueCode {
  duplicateEndpointCell,
  endpointSharedBetweenColors,
  duplicatePairColor,
  invalidStoredSolution,
  unsolvable,
  multipleSolutions,
  noStoredSolutionMatchesSolver,
}

class LevelValidationIssue {
  const LevelValidationIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.storedSolutionIndex,
    this.solutionIssueCode,
  });

  final LevelValidationIssueCode code;
  final LevelValidationSeverity severity;
  final String message;
  final int? storedSolutionIndex;
  final PuzzleSolutionIssueCode? solutionIssueCode;
}

class LevelQualityReport {
  const LevelQualityReport({
    required this.level,
    required this.solveResult,
    required this.issues,
    required this.storedSolutionsValid,
    required this.hasStoredSolutionMatch,
  });

  final PuzzleLevel level;
  final PuzzleSolveResult solveResult;
  final List<LevelValidationIssue> issues;
  final List<bool> storedSolutionsValid;
  final bool hasStoredSolutionMatch;

  bool get hasErrors =>
      issues.any((issue) => issue.severity == LevelValidationSeverity.error);
  bool get hasWarnings =>
      issues.any((issue) => issue.severity == LevelValidationSeverity.warning);
  bool get isUnsolvable =>
      solveResult.searchCompleted && !solveResult.isSolvable;
  bool get isUniquelySolvable => solveResult.isUnique;
  bool get hasMultipleSolutions => solveResult.solutionCount > 1;

  String get summary {
    final classification = isUnsolvable
        ? 'unsolvable'
        : isUniquelySolvable
        ? 'unique'
        : hasMultipleSolutions
        ? 'multiple solutions'
        : 'at least one solution';
    final countSuffix = solveResult.searchCompleted
        ? '${solveResult.solutionCount}'
        : '${solveResult.solutionCount}+ (search cap reached)';
    return '${level.id}: $classification; solutions=$countSuffix; '
        'stored=${storedSolutionsValid.where((valid) => valid).length}/'
        '${storedSolutionsValid.length} valid; nodes=${solveResult.nodesVisited}';
  }
}

class LevelQualityValidator {
  const LevelQualityValidator({
    this.solver = const PuzzleSolver(),
    this.solutionValidator = const PuzzleSolutionValidator(),
  });

  final PuzzleSolver solver;
  final PuzzleSolutionValidator solutionValidator;

  LevelQualityReport validate(
    PuzzleLevel level, {
    int maximumSolutionCount = 2,
  }) {
    final issues = <LevelValidationIssue>[];
    final endpointOwners = <GridCell, PathColor>{};
    final colors = <PathColor>{};
    for (final pair in level.endpointPairs) {
      if (!colors.add(pair.color)) {
        issues.add(
          LevelValidationIssue(
            code: LevelValidationIssueCode.duplicatePairColor,
            severity: LevelValidationSeverity.error,
            message: '${pair.color.name}: more than one endpoint pair',
          ),
        );
      }
      for (final cell in pair.positions) {
        final previous = endpointOwners[cell];
        if (previous == pair.color) {
          issues.add(
            LevelValidationIssue(
              code: LevelValidationIssueCode.duplicateEndpointCell,
              severity: LevelValidationSeverity.error,
              message:
                  '${pair.color.name}: duplicate endpoint at '
                  '(${cell.row}, ${cell.column})',
            ),
          );
        } else if (previous != null) {
          issues.add(
            LevelValidationIssue(
              code: LevelValidationIssueCode.endpointSharedBetweenColors,
              severity: LevelValidationSeverity.error,
              message:
                  '${pair.color.name} and ${previous.name} share endpoint '
                  '(${cell.row}, ${cell.column})',
            ),
          );
        }
        endpointOwners[cell] = pair.color;
      }
    }

    final storedSolutionsValid = <bool>[];
    for (var index = 0; index < level.solutions.length; index++) {
      final solutionIssues = solutionValidator.validateDetailed(
        level,
        level.solutions[index],
      );
      storedSolutionsValid.add(solutionIssues.isEmpty);
      for (final solutionIssue in solutionIssues) {
        issues.add(
          LevelValidationIssue(
            code: LevelValidationIssueCode.invalidStoredSolution,
            severity: LevelValidationSeverity.error,
            message: 'stored solution ${index + 1}: ${solutionIssue.message}',
            storedSolutionIndex: index,
            solutionIssueCode: solutionIssue.code,
          ),
        );
      }
    }

    final solveResult = solver.solve(
      level,
      maximumSolutionCount: maximumSolutionCount,
    );
    if (!solveResult.isSolvable && solveResult.searchCompleted) {
      issues.add(
        const LevelValidationIssue(
          code: LevelValidationIssueCode.unsolvable,
          severity: LevelValidationSeverity.error,
          message: 'level has no valid solution',
        ),
      );
    } else if (solveResult.solutionCount > 1) {
      issues.add(
        LevelValidationIssue(
          code: LevelValidationIssueCode.multipleSolutions,
          severity: LevelValidationSeverity.warning,
          message:
              'level has at least ${solveResult.solutionCount} valid solutions',
        ),
      );
    }

    final hasStoredSolutionMatch = level.solutions.any(
      (stored) => solveResult.solutions.any(
        (solved) => _solutionsMatch(level, stored, solved),
      ),
    );
    if (level.solutions.isNotEmpty &&
        solveResult.isSolvable &&
        !hasStoredSolutionMatch) {
      issues.add(
        const LevelValidationIssue(
          code: LevelValidationIssueCode.noStoredSolutionMatchesSolver,
          severity: LevelValidationSeverity.warning,
          message:
              'no stored solution appears among the solver results before '
              'the configured cap',
        ),
      );
    }

    return LevelQualityReport(
      level: level,
      solveResult: solveResult,
      issues: List.unmodifiable(issues),
      storedSolutionsValid: List.unmodifiable(storedSolutionsValid),
      hasStoredSolutionMatch: hasStoredSolutionMatch,
    );
  }

  bool _solutionsMatch(
    PuzzleLevel level,
    PuzzleSolution first,
    PuzzleSolution second,
  ) {
    for (final pair in level.endpointPairs) {
      final firstPaths = first.paths.where((path) => path.color == pair.color);
      final secondPaths = second.paths.where(
        (path) => path.color == pair.color,
      );
      if (firstPaths.length != 1 || secondPaths.length != 1) return false;
      if (!_pathsMatch(firstPaths.single.cells, secondPaths.single.cells)) {
        return false;
      }
    }
    return true;
  }

  bool _pathsMatch(List<GridCell> first, List<GridCell> second) {
    if (first.length != second.length) return false;
    final forward = Iterable<int>.generate(
      first.length,
    ).every((index) => first[index] == second[index]);
    if (forward) return true;
    return Iterable<int>.generate(
      first.length,
    ).every((index) => first[index] == second[first.length - index - 1]);
  }
}
