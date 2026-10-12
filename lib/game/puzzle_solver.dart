import 'grid_cell.dart';
import 'puzzle_level.dart';
import 'puzzle_solution_validator.dart';

class PuzzleSolveResult {
  const PuzzleSolveResult({
    required this.solutions,
    required this.searchCompleted,
    required this.nodesVisited,
    required this.elapsed,
  });

  final List<PuzzleSolution> solutions;
  final bool searchCompleted;
  final int nodesVisited;
  final Duration elapsed;

  int get solutionCount => solutions.length;
  bool get isSolvable => solutions.isNotEmpty;
  bool get isUnique => searchCompleted && solutionCount == 1;
}

class PuzzleSolver {
  const PuzzleSolver();

  PuzzleSolveResult solve(PuzzleLevel level, {int maximumSolutionCount = 2}) {
    if (maximumSolutionCount <= 0) {
      throw ArgumentError.value(
        maximumSolutionCount,
        'maximumSolutionCount',
        'must be greater than zero',
      );
    }

    final stopwatch = Stopwatch()..start();
    final search = _PuzzleSearch(level, maximumSolutionCount);
    search.run();
    stopwatch.stop();
    return PuzzleSolveResult(
      solutions: List.unmodifiable(search.solutions),
      searchCompleted: !search.limitReached,
      nodesVisited: search.nodesVisited,
      elapsed: stopwatch.elapsed,
    );
  }
}

class _PuzzleSearch {
  _PuzzleSearch(this.level, this.maximumSolutionCount)
    : endpointOwners = <GridCell, PathColor>{};

  static const _directions = <(int, int)>[(-1, 0), (0, -1), (0, 1), (1, 0)];

  final PuzzleLevel level;
  final int maximumSolutionCount;
  final Map<GridCell, PathColor> endpointOwners;
  final Set<GridCell> occupied = {};
  final Map<PathColor, List<GridCell>> paths = {};
  final List<PuzzleSolution> solutions = [];
  int nodesVisited = 0;
  bool limitReached = false;
  bool _wellFormed = true;

  void run() {
    final colors = <PathColor>{};
    for (final pair in level.endpointPairs) {
      if (!colors.add(pair.color) ||
          !_isOnBoard(pair.first) ||
          !_isOnBoard(pair.second) ||
          pair.first == pair.second) {
        _wellFormed = false;
        return;
      }
      for (final cell in pair.positions) {
        if (endpointOwners.containsKey(cell)) {
          _wellFormed = false;
          return;
        }
        endpointOwners[cell] = pair.color;
        occupied.add(cell);
      }
    }
    if (level.endpointPairs.isEmpty) return;
    _searchPair(0);
  }

  void _searchPair(int pairIndex) {
    if (limitReached || !_wellFormed) return;
    nodesVisited++;
    if (pairIndex == level.endpointPairs.length) {
      if (occupied.length != level.rows * level.columns) return;
      final solution = PuzzleSolution(
        paths: [
          for (final pair in level.endpointPairs)
            SolutionPath(
              color: pair.color,
              cells: List.unmodifiable(paths[pair.color]!),
            ),
        ],
      );
      if (const PuzzleSolutionValidator().isValid(level, solution)) {
        solutions.add(solution);
        if (solutions.length >= maximumSolutionCount) limitReached = true;
      }
      return;
    }

    final pair = level.endpointPairs[pairIndex];
    final path = <GridCell>[pair.first];
    paths[pair.color] = path;
    _extendPath(pairIndex, pair, path);
    paths.remove(pair.color);
  }

  void _extendPath(int pairIndex, EndpointPair pair, List<GridCell> path) {
    if (limitReached) return;
    nodesVisited++;
    final head = path.last;
    if (head == pair.second) {
      if (_remainingPairsAreReachable(pairIndex + 1) &&
          !_hasStrandedEmptyRegion(pairIndex + 1)) {
        _searchPair(pairIndex + 1);
      }
      return;
    }

    for (final (rowDelta, columnDelta) in _directions) {
      final next = GridCell(head.row + rowDelta, head.column + columnDelta);
      if (!_isOnBoard(next)) continue;
      if (next == pair.second) {
        path.add(next);
        _extendPath(pairIndex, pair, path);
        path.removeLast();
        if (limitReached) return;
        continue;
      }
      if (occupied.contains(next) || endpointOwners.containsKey(next)) {
        continue;
      }

      occupied.add(next);
      path.add(next);
      if (_canReach(head: next, target: pair.second) &&
          _remainingPairsAreReachable(pairIndex + 1) &&
          !_hasImpossibleEmptyCell(pairIndex, next)) {
        _extendPath(pairIndex, pair, path);
      }
      path.removeLast();
      occupied.remove(next);
      if (limitReached) return;
    }
  }

  bool _remainingPairsAreReachable(int firstPairIndex) {
    for (
      var index = firstPairIndex;
      index < level.endpointPairs.length;
      index++
    ) {
      final pair = level.endpointPairs[index];
      if (!_canReach(head: pair.first, target: pair.second)) return false;
    }
    return true;
  }

  bool _canReach({required GridCell head, required GridCell target}) {
    final pending = <GridCell>[head];
    final visited = <GridCell>{head};
    while (pending.isNotEmpty) {
      final cell = pending.removeLast();
      for (final neighbor in _neighbors(cell)) {
        if (neighbor == target) return true;
        if (occupied.contains(neighbor) ||
            endpointOwners.containsKey(neighbor) ||
            !visited.add(neighbor)) {
          continue;
        }
        pending.add(neighbor);
      }
    }
    return false;
  }

  bool _hasImpossibleEmptyCell(int activePairIndex, GridCell activeHead) {
    for (var row = 0; row < level.rows; row++) {
      for (var column = 0; column < level.columns; column++) {
        final cell = GridCell(row, column);
        if (occupied.contains(cell)) continue;
        var availableNeighbors = 0;
        for (final neighbor in _neighbors(cell)) {
          if (!occupied.contains(neighbor) ||
              neighbor == activeHead ||
              _isEndpointOfUnfinishedPair(neighbor, activePairIndex)) {
            availableNeighbors++;
          }
        }
        if (availableNeighbors < 2) return true;
      }
    }
    return false;
  }

  bool _hasStrandedEmptyRegion(int firstPairIndex) {
    final unvisited = <GridCell>{};
    for (var row = 0; row < level.rows; row++) {
      for (var column = 0; column < level.columns; column++) {
        final cell = GridCell(row, column);
        if (!occupied.contains(cell)) unvisited.add(cell);
      }
    }
    while (unvisited.isNotEmpty) {
      final pending = <GridCell>[unvisited.first];
      unvisited.remove(pending.first);
      var touchesUnfinishedEndpoint = false;
      while (pending.isNotEmpty) {
        final cell = pending.removeLast();
        for (final neighbor in _neighbors(cell)) {
          if (_isEndpointOfUnfinishedPair(neighbor, firstPairIndex)) {
            touchesUnfinishedEndpoint = true;
          }
          if (unvisited.remove(neighbor)) pending.add(neighbor);
        }
      }
      if (!touchesUnfinishedEndpoint) return true;
    }
    return false;
  }

  bool _isEndpointOfUnfinishedPair(GridCell cell, int firstPairIndex) {
    for (
      var index = firstPairIndex;
      index < level.endpointPairs.length;
      index++
    ) {
      if (level.endpointPairs[index].positions.contains(cell)) return true;
    }
    return false;
  }

  Iterable<GridCell> _neighbors(GridCell cell) sync* {
    for (final (rowDelta, columnDelta) in _directions) {
      final neighbor = GridCell(cell.row + rowDelta, cell.column + columnDelta);
      if (_isOnBoard(neighbor)) yield neighbor;
    }
  }

  bool _isOnBoard(GridCell cell) =>
      cell.row >= 0 &&
      cell.row < level.rows &&
      cell.column >= 0 &&
      cell.column < level.columns;
}
