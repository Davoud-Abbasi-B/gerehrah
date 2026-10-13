import '../localization/persian.dart';

import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../analytics/app_analytics_service.dart';
import '../home/season_definition.dart';
import '../progress/progress_repository.dart';
import 'level_progression.dart';
import 'path_board.dart';
import 'gerehrah_game.dart';
import 'puzzle_level.dart';

class GerehrahScreen extends StatefulWidget {
  const GerehrahScreen({
    super.key,
    this.levels,
    this.progressRepository,
    this.boardFactory,
    this.progression,
    this.analyticsService,
  }) : assert(levels != null || progression != null);

  final List<PuzzleLevel>? levels;
  final ProgressRepository? progressRepository;
  final PathBoard Function(PuzzleLevel level)? boardFactory;
  final LevelProgression? progression;
  final AppAnalyticsService? analyticsService;

  @override
  State<GerehrahScreen> createState() => _GerehrahScreenState();
}

class _GerehrahScreenState extends State<GerehrahScreen>
    with SingleTickerProviderStateMixin {
  late final LevelProgression _progression;
  late GerehrahGame _game;
  late final AppAnalyticsService _analyticsService;
  bool _stateRefreshScheduled = false;
  bool _completionHandledForCurrentSolve = false;
  late final AnimationController _invalidMoveController;

  @override
  void initState() {
    super.initState();
    final suppliedProgression = widget.progression;
    if (suppliedProgression == null) {
      _progression = LevelProgression(
        widget.levels!,
        boardFactory: widget.boardFactory,
        repository:
            widget.progressRepository ?? SharedPreferencesProgressRepository(),
      );
      unawaited(_loadProgress());
    } else {
      _progression = suppliedProgression;
    }
    _analyticsService =
        widget.analyticsService ?? FirebaseAppAnalyticsService();
    _invalidMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _game = _createGame();
  }

  @override
  void dispose() {
    _invalidMoveController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    await _progression.loadProgress();
    _scheduleStateRefresh();
  }

  GerehrahGame _createGame() => GerehrahGame(
    board: _progression.board,
    onStateChanged: _onGameStateChanged,
    onInvalidMove: _onInvalidMove,
  );

  void _onInvalidMove() {
    logAnalyticsSafely(_analyticsService.logInvalidMove);
    _invalidMoveController.forward(from: 0);
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    _scheduleStateRefresh();
    if (!_game.isSolved) {
      _completionHandledForCurrentSolve = false;
      return;
    }
    if (_completionHandledForCurrentSolve) return;
    _completionHandledForCurrentSolve = true;
    final levelIndex = _progression.levelIndex;
    logAnalyticsSafely(
      () => _analyticsService.logLevelComplete(
        levelId: _progression.level.id,
        seasonNumber: levelIndex ~/ levelsPerSeason + 1,
        levelNumber: levelIndex % levelsPerSeason + 1,
        moves: _game.moveCount,
        completionTimeSeconds: _progression.board.timer.elapsed.inSeconds,
      ),
    );
    unawaited(_recordCompletion());
  }

  Future<void> _recordCompletion() async {
    await _progression.recordCurrentCompletion();
    _scheduleStateRefresh();
  }

  void _scheduleStateRefresh() {
    if (!mounted || _stateRefreshScheduled) return;
    _stateRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stateRefreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _changeLevel({required bool next}) {
    final changed = next ? _progression.goNext() : _progression.goPrevious();
    if (changed) _replaceGame();
  }

  void _selectLevel(int index) {
    if (_progression.goToLevel(index)) _replaceGame();
  }

  void _replaceGame() {
    if (!mounted) return;
    _completionHandledForCurrentSolve = false;
    setState(() => _game = _createGame());
  }

  @override
  Widget build(BuildContext context) {
    final level = _progression.level;
    final best = _progression.resultFor(level.id);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final contentWidth = viewport.maxWidth.clamp(0.0, 720.0);
            final boardWidth = (contentWidth - 16).clamp(0.0, 704.0);
            final heightBasedSize = (viewport.maxHeight - 230).clamp(
              260.0,
              704.0,
            );
            final boardSize = boardWidth < heightBasedSize
                ? boardWidth
                : heightBasedSize;
            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Column(
                      children: [
                        _GameTopBar(
                          levelNumber: _progression.levelIndex + 1,
                          title: level.title,
                          solved: _game.isSolved,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        _LevelStrip(
                          progression: _progression,
                          onSelected: _selectLevel,
                        ),
                        _StatusPanel(
                          moves: _game.moveCount,
                          time: _game.elapsedTime,
                          bestMoves: best?.bestMoves,
                          bestTime: best == null
                              ? null
                              : _formatSeconds(best.bestTimeSeconds),
                        ),
                        AnimatedBuilder(
                          animation: _invalidMoveController,
                          builder: (context, child) {
                            final progress = _invalidMoveController.value;
                            final shake = progress == 0
                                ? 0.0
                                : (progress < 0.25
                                      ? -5.0
                                      : progress < 0.5
                                      ? 5.0
                                      : progress < 0.75
                                      ? -3.0
                                      : 0.0);
                            return Transform.translate(
                              offset: Offset(shake, 0),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GameWidget(
                                  key: ValueKey(level.id),
                                  game: _game,
                                ),
                                IgnorePointer(
                                  child: FadeTransition(
                                    key: const Key('invalid-move-feedback'),
                                    opacity: TweenSequence<double>([
                                      TweenSequenceItem(
                                        tween: Tween(begin: 0, end: 0.18),
                                        weight: 35,
                                      ),
                                      TweenSequenceItem(
                                        tween: Tween(begin: 0.18, end: 0),
                                        weight: 65,
                                      ),
                                    ]).animate(_invalidMoveController),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    switchInCurve: Curves.easeOutBack,
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                          scale: animation,
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        ),
                                    child: _game.isSolved
                                        ? const _SuccessBadge()
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _GameControls(
                          canGoPrevious: _progression.canGoPrevious,
                          canUndo: _game.canUndo,
                          canGoNext: _progression.canGoNext,
                          onPrevious: () => _changeLevel(next: false),
                          onUndo: _game.undo,
                          onReset: _game.reset,
                          onNext: () => _changeLevel(next: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({
    required this.levelNumber,
    required this.title,
    required this.solved,
    required this.onBack,
  });

  final int levelNumber;
  final String title;
  final bool solved;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          IconButton.filledTonal(
            key: const Key('back-to-levels'),
            onPressed: onBack,
            tooltip: 'بازگشت به مرحله‌ها',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF172A45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'مرحله ${persianDigits(levelNumber)}',
              style: const TextStyle(
                color: Color(0xFF76A9FF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'مرحله ${persianDigits(levelNumber)} • $title',
              key: const Key('level-title'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: solved
                ? const Icon(
                    Icons.check_circle_rounded,
                    key: Key('title-solved-indicator'),
                    color: Color(0xFF5ED6A8),
                    size: 22,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LevelStrip extends StatelessWidget {
  const _LevelStrip({required this.progression, required this.onSelected});

  final LevelProgression progression;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        scrollDirection: Axis.horizontal,
        itemCount: progression.levels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final selected = index == progression.levelIndex;
          final unlocked = progression.isLevelUnlocked(index);
          final completed = progression.isCompleted(
            progression.levels[index].id,
          );
          return TextButton(
            key: Key('level-${index + 1}'),
            onPressed: unlocked ? () => onSelected(index) : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: selected
                  ? const Color(0xFFF4F8FF)
                  : const Color(0xFF9CAABD),
              backgroundColor: selected
                  ? const Color(0xFF24466D)
                  : const Color(0xFF101C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF4779AE)
                      : const Color(0xFF24364C),
                ),
              ),
            ),
            child: Text('${persianDigits(index + 1)}${completed ? ' ✓' : ''}'),
          );
        },
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.moves,
    required this.time,
    required this.bestMoves,
    required this.bestTime,
  });

  final int moves;
  final String time;
  final int? bestMoves;
  final String? bestTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 4),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    icon: Icons.gesture_rounded,
                    label: 'حرکت',
                    value: persianDigits(moves),
                    key: const Key('move-count'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.schedule_rounded,
                    label: 'زمان',
                    value: persianDigits(time),
                    key: const Key('level-time'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 22,
            child: bestMoves == null || bestTime == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'کمترین حرکت: ${persianDigits(bestMoves!)}  •  بهترین زمان: $bestTime',
                      key: const Key('best-result'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8FA0B6),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101D2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF243851)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF76A9FF)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$label: $value',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('success-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xEE10291F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4FC794)),
        boxShadow: const [
          BoxShadow(color: Color(0x335ED6A8), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 21),
          SizedBox(width: 8),
          Text(
            'مرحله کامل شد!',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _GameControls extends StatelessWidget {
  const _GameControls({
    required this.canGoPrevious,
    required this.canUndo,
    required this.canGoNext,
    required this.onPrevious,
    required this.onUndo,
    required this.onReset,
    required this.onNext,
  });

  final bool canGoPrevious;
  final bool canUndo;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(13)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 7,
        children: [
          OutlinedButton.icon(
            key: const Key('previous-level'),
            onPressed: canGoPrevious ? onPrevious : null,
            style: OutlinedButton.styleFrom(
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            label: const Text('قبلی'),
          ),
          OutlinedButton.icon(
            key: const Key('undo'),
            onPressed: canUndo ? onUndo : null,
            style: OutlinedButton.styleFrom(
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('بازگشت'),
          ),
          OutlinedButton.icon(
            key: const Key('reset'),
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('شروع دوباره'),
          ),
          FilledButton.icon(
            key: const Key('next-level'),
            onPressed: canGoNext ? onNext : null,
            style: FilledButton.styleFrom(
              shape: shape,
              minimumSize: const Size(0, 44),
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 19),
            label: const Text('بعدی'),
          ),
        ],
      ),
    );
  }
}

String _formatSeconds(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return persianDigits('$minutes:$seconds');
}
