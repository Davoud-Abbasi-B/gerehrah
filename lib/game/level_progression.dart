import '../progress/progress_repository.dart';
import '../home/season_definition.dart';
import 'path_board.dart';
import 'puzzle_level.dart';

typedef BoardFactory = PathBoard Function(PuzzleLevel level);

class LevelProgression {
  LevelProgression(this.levels, {BoardFactory? boardFactory, this.repository})
    : assert(levels.isNotEmpty),
      _boardFactory = boardFactory ?? PathBoard.new {
    board = _boardFactory(levels.first);
  }

  final List<PuzzleLevel> levels;
  final BoardFactory _boardFactory;
  final ProgressRepository? repository;
  final Map<String, LevelBestResult> _completedLevels = {};
  int levelIndex = 0;
  late PathBoard board;

  PuzzleLevel get level => levels[levelIndex];
  bool get canGoPrevious => levelIndex > 0;
  bool get canGoNext =>
      levelIndex < levels.length - 1 && board.isSolved && !board.isDragActive;

  LevelBestResult? resultFor(String levelId) => _completedLevels[levelId];
  bool isCompleted(String levelId) => _completedLevels.containsKey(levelId);

  bool isLevelUnlocked(int index) {
    if (index < 0 || index >= levels.length) return false;
    final seasonStart = (index ~/ levelsPerSeason) * levelsPerSeason;
    if (seasonStart > 0) {
      final previousSeasonComplete = levels
          .sublist(seasonStart - levelsPerSeason, seasonStart)
          .every((level) => isCompleted(level.id));
      if (!previousSeasonComplete) return false;
    }
    if (index == seasonStart) return true;
    return isCompleted(levels[index - 1].id);
  }

  Future<void> loadProgress() async {
    final repository = this.repository;
    if (repository == null) return;
    final progress = await repository.load();
    _completedLevels
      ..clear()
      ..addAll(progress.completedLevels);
  }

  Future<void> recordCurrentCompletion() async {
    if (!board.isSolved) return;
    final completedLevel = level;
    final moves = board.moveCount;
    final seconds = board.timer.elapsed.inSeconds;
    final previous = _completedLevels[completedLevel.id];
    final repository = this.repository;
    final localResult =
        previous?.improvedWith(moves: moves, timeSeconds: seconds) ??
        LevelBestResult(bestMoves: moves, bestTimeSeconds: seconds);
    _completedLevels[completedLevel.id] = localResult;
    var result = localResult;
    if (repository != null) {
      try {
        result = await repository.saveCompletedLevel(
          levelId: completedLevel.id,
          moves: moves,
          timeSeconds: seconds,
        );
      } on Object {
        result = localResult;
      }
    }
    _completedLevels[completedLevel.id] = result;
  }

  bool goToLevel(int index) {
    if (index < 0 || index >= levels.length || !isLevelUnlocked(index)) {
      return false;
    }
    levelIndex = index;
    board = _boardFactory(levels[index]);
    return true;
  }

  bool goPrevious() {
    if (!canGoPrevious) return false;
    return goToLevel(levelIndex - 1);
  }

  bool goNext() {
    if (!canGoNext) return false;
    if ((levelIndex + 1) % 20 == 0 && !isLevelUnlocked(levelIndex + 1)) {
      return false;
    }
    levelIndex++;
    board = _boardFactory(levels[levelIndex]);
    return true;
  }
}
