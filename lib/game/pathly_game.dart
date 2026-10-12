import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'grid_cell.dart';
import 'path_board.dart';
import 'puzzle_level.dart';

class PathlyGame extends FlameGame with DragCallbacks {
  PathlyGame({
    required this.board,
    required this.onStateChanged,
    required this.onInvalidMove,
  }) {
    _lastNotifiedState = _observableState;
  }

  static const double gridPadding = 28;

  final void Function() onStateChanged;
  final void Function() onInvalidMove;
  final PathBoard board;
  GridCell? _lastDragCell;
  bool _invalidReportedForGesture = false;

  PuzzleLevel get level => board.level;
  bool get isSolved => board.isSolved;
  int get moveCount => board.moveCount;
  bool get canUndo => board.canUndo;
  String get elapsedTime => board.timer.formatted;
  late _ObservableGameState _lastNotifiedState;

  _ObservableGameState get _observableState => (
    moveCount: board.moveCount,
    elapsedSeconds: board.timer.elapsed.inSeconds,
    solved: board.isSolved,
    canUndo: board.canUndo,
    dragActive: board.isDragActive,
  );

  Rect get _gridRect {
    final availableCellWidth = (size.x - gridPadding * 2) / level.columns;
    final availableCellHeight = (size.y - gridPadding * 2) / level.rows;
    final cellSize =
        (availableCellWidth < availableCellHeight
                ? availableCellWidth
                : availableCellHeight)
            .clamp(1.0, 110.0);
    final boardWidth = cellSize * level.columns;
    final boardHeight = cellSize * level.rows;
    return Rect.fromLTWH(
      (size.x - boardWidth) / 2,
      (size.y - boardHeight) / 2,
      boardWidth,
      boardHeight,
    );
  }

  double get _cellSize => _gridRect.width / level.columns;

  @override
  Color backgroundColor() => const Color(0xFF08111F);

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void update(double dt) {
    super.update(dt);
    _notifyIfStateChanged();
  }

  @override
  void onRemove() {
    board.timer.pause();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = _gridRect;
    final gridPaint = Paint()
      ..color = const Color(0xFF343945)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var index = 0; index <= level.columns; index++) {
      final offset = index * _cellSize;
      canvas.drawLine(
        Offset(rect.left + offset, rect.top),
        Offset(rect.left + offset, rect.bottom),
        gridPaint,
      );
    }

    for (var index = 0; index <= level.rows; index++) {
      final offset = index * _cellSize;
      canvas.drawLine(
        Offset(rect.left, rect.top + offset),
        Offset(rect.right, rect.top + offset),
        gridPaint,
      );
    }

    for (final pair in level.endpointPairs) {
      _drawPath(canvas, pair.color);
    }
    for (final pair in level.endpointPairs) {
      for (final cell in pair.positions) {
        canvas.drawCircle(
          _centerOf(cell),
          _cellSize * 0.18,
          Paint()..color = _paintColor(pair.color),
        );
      }
    }
  }

  void _drawPath(Canvas canvas, PathColor color) {
    final pathCells = board.pathFor(color);
    if (pathCells.length < 2) return;

    final path = Path()
      ..moveTo(_centerOf(pathCells.first).dx, _centerOf(pathCells.first).dy);
    for (final cell in pathCells.skip(1)) {
      final center = _centerOf(cell);
      path.lineTo(center.dx, center.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _paintColor(color).withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cellSize * 0.22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final cell = _cellAt(event.localPosition);
    if (cell == null) return;
    _lastDragCell = cell;
    _invalidReportedForGesture = false;
    if (board.begin(cell)) {
      _notifyIfStateChanged();
    } else {
      _reportInvalidMove();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final cell = _cellAt(event.localEndPosition);
    if (cell == null || cell == _lastDragCell) return;
    _lastDragCell = cell;
    if (!board.moveTo(cell)) _reportInvalidMove();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    board.end();
    _lastDragCell = null;
    _notifyIfStateChanged();
  }

  void _reportInvalidMove() {
    if (_invalidReportedForGesture) return;
    _invalidReportedForGesture = true;
    onInvalidMove();
  }

  void reset() {
    board.reset();
    _notifyIfStateChanged();
  }

  void undo() {
    if (board.undo()) _notifyIfStateChanged();
  }

  void _notifyIfStateChanged() {
    final currentState = _observableState;
    if (currentState == _lastNotifiedState) return;
    _lastNotifiedState = currentState;
    onStateChanged();
  }

  GridCell? _cellAt(Vector2 point) {
    final rect = _gridRect;
    if (!rect.contains(Offset(point.x, point.y))) return null;
    final column = ((point.x - rect.left) / _cellSize).floor().clamp(
      0,
      level.columns - 1,
    );
    final row = ((point.y - rect.top) / _cellSize).floor().clamp(
      0,
      level.rows - 1,
    );
    return GridCell(row, column);
  }

  Offset _centerOf(GridCell cell) {
    return Offset(
      _gridRect.left + (cell.column + 0.5) * _cellSize,
      _gridRect.top + (cell.row + 0.5) * _cellSize,
    );
  }

  Color _paintColor(PathColor color) {
    return switch (color) {
      PathColor.blue => const Color(0xFF3B82F6),
      PathColor.red => const Color(0xFFEF4444),
      PathColor.green => const Color(0xFF22C55E),
      PathColor.yellow => const Color(0xFFFACC15),
    };
  }
}

typedef _ObservableGameState = ({
  int moveCount,
  int elapsedSeconds,
  bool solved,
  bool canUndo,
  bool dragActive,
});
