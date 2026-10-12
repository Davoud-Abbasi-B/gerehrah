import 'grid_cell.dart';
import 'level_timer.dart';
import 'puzzle_level.dart';

class PathBoard {
  PathBoard(this.level, {LevelTimer? timer})
    : timer = timer ?? LevelTimer(),
      _paths = {
        for (final pair in level.endpointPairs) pair.color: <GridCell>[],
      };

  final PuzzleLevel level;
  final LevelTimer timer;
  final Map<PathColor, List<GridCell>> _paths;
  final List<_BoardSnapshot> _undoHistory = [];
  PathColor? _activeColor;
  PathColor? _mostRecentlyModifiedColor;
  _BoardSnapshot? _dragStartSnapshot;
  bool _dragChanged = false;

  int get moveCount => _undoHistory.length;
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get isDragActive => _activeColor != null;
  PathColor? get activeColor => _activeColor;
  PathColor? get mostRecentlyModifiedColor => _mostRecentlyModifiedColor;

  List<GridCell> pathFor(PathColor color) => List.unmodifiable(_paths[color]!);

  bool get isBoardFullyCovered {
    final occupiedCells = <GridCell>{
      for (final pair in level.endpointPairs) ...pair.positions,
      for (final path in _paths.values) ...path,
    };
    return Iterable.generate(level.rows).every(
      (row) => Iterable.generate(
        level.columns,
      ).every((column) => occupiedCells.contains(GridCell(row, column))),
    );
  }

  bool get isSolved =>
      level.endpointPairs.every((pair) => isComplete(pair.color)) &&
      isBoardFullyCovered;

  bool get areAllPathsComplete =>
      level.endpointPairs.every((pair) => isComplete(pair.color));

  bool isComplete(PathColor color) {
    final path = _paths[color]!;
    final endpoints = level.pairFor(color).positions;
    return path.isNotEmpty &&
        endpoints.contains(path.first) &&
        endpoints.contains(path.last) &&
        path.first != path.last;
  }

  bool begin(GridCell cell) {
    _activeColor = null;
    _dragStartSnapshot = _snapshot();
    _dragChanged = false;

    for (final pair in level.endpointPairs) {
      if (pair.positions.contains(cell)) {
        _paths[pair.color] = [cell];
        _activeColor = pair.color;
        return true;
      }
    }

    for (final pair in level.endpointPairs) {
      final path = _paths[pair.color]!;
      if (path.isNotEmpty && path.last == cell && !isComplete(pair.color)) {
        _activeColor = pair.color;
        return true;
      }
    }
    _dragStartSnapshot = null;
    return false;
  }

  bool moveTo(GridCell cell) {
    final color = _activeColor;
    if (color == null || !_isOnBoard(cell)) return false;
    if (isComplete(color)) return false;

    final path = _paths[color]!;
    final last = path.last;
    if (cell == last || !last.isAdjacentTo(cell)) return false;

    final earlierIndex = path.indexOf(cell);
    if (earlierIndex != -1) {
      path.removeRange(earlierIndex + 1, path.length);
      _dragChanged = true;
      _mostRecentlyModifiedColor = color;
      return true;
    }
    if (isOccupiedByOtherColor(cell, color)) return false;
    path.add(cell);
    _dragChanged = true;
    _mostRecentlyModifiedColor = color;
    return true;
  }

  bool end() {
    final before = _dragStartSnapshot;
    final changed = before != null && _dragChanged && !_matchesSnapshot(before);
    if (changed) {
      _undoHistory.add(before);
      _mostRecentlyModifiedColor = _activeColor;
      timer.start();
      if (isSolved) timer.pause();
    } else if (before != null) {
      _restore(before);
    }
    _activeColor = null;
    _dragStartSnapshot = null;
    _dragChanged = false;
    return changed;
  }

  bool undo() {
    if (!canUndo) return false;
    _restore(_undoHistory.removeLast());
    _activeColor = null;
    _dragStartSnapshot = null;
    _dragChanged = false;
    if (isSolved) {
      timer.pause();
    } else {
      timer.start();
    }
    return true;
  }

  void reset() {
    for (final path in _paths.values) {
      path.clear();
    }
    _undoHistory.clear();
    _activeColor = null;
    _dragStartSnapshot = null;
    _dragChanged = false;
    _mostRecentlyModifiedColor = null;
    timer.reset();
  }

  _BoardSnapshot _snapshot() => _BoardSnapshot({
    for (final entry in _paths.entries) entry.key: List.of(entry.value),
  }, _mostRecentlyModifiedColor);

  bool _matchesSnapshot(_BoardSnapshot snapshot) {
    for (final color in _paths.keys) {
      final current = _paths[color]!;
      final previous = snapshot.paths[color]!;
      if (current.length != previous.length) return false;
      for (var index = 0; index < current.length; index++) {
        if (current[index] != previous[index]) return false;
      }
    }
    return true;
  }

  void _restore(_BoardSnapshot snapshot) {
    for (final entry in snapshot.paths.entries) {
      _paths[entry.key] = List.of(entry.value);
    }
    _mostRecentlyModifiedColor = snapshot.mostRecentlyModifiedColor;
  }

  bool _isOnBoard(GridCell cell) =>
      cell.row >= 0 &&
      cell.row < level.rows &&
      cell.column >= 0 &&
      cell.column < level.columns;

  bool isOccupiedByOtherColor(GridCell cell, PathColor color) {
    for (final pair in level.endpointPairs) {
      if (pair.color == color) continue;
      if (_paths[pair.color]!.contains(cell) || pair.positions.contains(cell)) {
        return true;
      }
    }
    return false;
  }
}

class _BoardSnapshot {
  const _BoardSnapshot(this.paths, this.mostRecentlyModifiedColor);

  final Map<PathColor, List<GridCell>> paths;
  final PathColor? mostRecentlyModifiedColor;
}
