import '../localization/persian.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../analytics/app_analytics_service.dart';
import '../game/level_progression.dart';
import '../game/gerehrah_screen.dart';
import '../game/puzzle_level.dart';
import '../onboarding/how_to_play.dart';
import '../progress/progress_repository.dart';
import '../privacy/privacy_policy_screen.dart';
import '../share/app_share_service.dart';
import 'season_definition.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({
    super.key,
    required this.levels,
    this.progressRepository,
    this.boardFactory,
    this.shareService,
    this.analyticsService,
  });

  final List<PuzzleLevel> levels;
  final ProgressRepository? progressRepository;
  final BoardFactory? boardFactory;
  final AppShareService? shareService;
  final AppAnalyticsService? analyticsService;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  late final LevelProgression _progression;
  late final List<SeasonDefinition> _seasons;
  late final AppShareService _shareService;
  late final AppAnalyticsService _analyticsService;
  int _selectedSeasonIndex = 0;

  @override
  void initState() {
    super.initState();
    _progression = LevelProgression(
      widget.levels,
      boardFactory: widget.boardFactory,
      repository:
          widget.progressRepository ?? SharedPreferencesProgressRepository(),
    );
    _seasons = buildGerehrahSeasons(widget.levels);
    _shareService = widget.shareService ?? const PlatformAppShareService();
    _analyticsService =
        widget.analyticsService ?? FirebaseAppAnalyticsService();
    unawaited(_loadProgress());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTutorialForNewUser());
    });
  }

  Future<void> _showTutorialForNewUser() async {
    if (await isTutorialCompleted() || !mounted) return;
    await showHowToPlay(context: context, analyticsService: _analyticsService);
  }

  Future<void> _showTutorial() =>
      showHowToPlay(context: context, analyticsService: _analyticsService);

  Future<void> _loadProgress() async {
    await _progression.loadProgress();
    if (mounted) setState(() {});
  }

  Future<void> _openLevel(int index) async {
    if (!_progression.goToLevel(index) || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GerehrahScreen(
          progression: _progression,
          analyticsService: _analyticsService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _selectSeason(int index) {
    if (index < 0 || index >= _seasons.length) return;
    setState(() => _selectedSeasonIndex = index);
  }

  Future<void> _showLevelDetails({
    required PuzzleLevel level,
    required int levelNumber,
    required LevelBestResult? result,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111D2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _LevelDetailsSheet(
        level: level,
        levelNumber: levelNumber,
        result: result,
      ),
    );
  }

  Future<void> _shareApp(BuildContext buttonContext) async {
    logAnalyticsSafely(_analyticsService.logShareAppClick);
    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox == null || !renderBox.hasSize
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      await _shareService.shareApp(sharePositionOrigin: shareOrigin);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('share-error-snackbar'),
          content: Text('فعلاً امکان اشتراک‌گذاری بازی نیست.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final season = _seasons[_selectedSeasonIndex];
    final completedCount = season.slots.where((slot) {
      final level = slot.level;
      return level != null && _progression.isCompleted(level.id);
    }).length;
    final seasonUnlocked = _isSeasonUnlocked(season);
    final nextPlayableIndex = _findNextPlayableIndex(season);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final contentWidth = viewport.maxWidth.clamp(0.0, 560.0);
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const _LevelSelectHeader(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, sectionViewport) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: sectionViewport.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'انتخاب مرحله',
                                          key: Key('select-level-heading'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _SeasonSelector(
                                          season: season,
                                          canGoPrevious:
                                              _selectedSeasonIndex > 0,
                                          canGoNext:
                                              _selectedSeasonIndex <
                                              _seasons.length - 1,
                                          onPrevious: () => _selectSeason(
                                            _selectedSeasonIndex - 1,
                                          ),
                                          onNext: () => _selectSeason(
                                            _selectedSeasonIndex + 1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'پیشرفت: ${persianDigits(completedCount)} از '
                                          '${persianDigits(levelsPerSeason)}',
                                          key: const Key('season-progress'),
                                          style: const TextStyle(
                                            color: Color(0xFFB3C0D1),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!seasonUnlocked &&
                                            season.lockedMessage != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            season.lockedMessage!,
                                            key: const Key(
                                              'season-locked-message',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 14),
                                        _SeasonGrid(
                                          season: season,
                                          progression: _progression,
                                          nextPlayableIndex: nextPlayableIndex,
                                          onPlay: _openLevel,
                                          onDetails: _showLevelDetails,
                                        ),
                                        const SizedBox(height: 16),
                                        Builder(
                                          builder: (buttonContext) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Semantics(
                                                label: 'اشتراک‌گذاری گره‌راه',
                                                button: true,
                                                excludeSemantics: true,
                                                child: Tooltip(
                                                  message:
                                                      'اشتراک‌گذاری گره‌راه',
                                                  child: OutlinedButton.icon(
                                                    key: const Key('share-app'),
                                                    onPressed: () => _shareApp(
                                                      buttonContext,
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      minimumSize: const Size(
                                                        0,
                                                        44,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 10,
                                                          ),
                                                      foregroundColor:
                                                          const Color(
                                                            0xFFBFD4F5,
                                                          ),
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFF334B6B,
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.share_rounded,
                                                      size: 18,
                                                    ),
                                                    label: const Text(
                                                      'اشتراک‌گذاری',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton.outlined(
                                                key: const Key('how-to-play'),
                                                onPressed: _showTutorial,
                                                tooltip: 'روش بازی',
                                                style: IconButton.styleFrom(
                                                  minimumSize: const Size(
                                                    44,
                                                    44,
                                                  ),
                                                  maximumSize: const Size(
                                                    44,
                                                    44,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  foregroundColor: const Color(
                                                    0xFFBFD4F5,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF334B6B),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.help_outline_rounded,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Semantics(
                                          label: 'حریم خصوصی',
                                          button: true,
                                          excludeSemantics: true,
                                          child: TextButton(
                                            key: const Key('privacy-policy'),
                                            onPressed: () =>
                                                Navigator.of(
                                                  context,
                                                ).push<void>(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const PrivacyPolicyScreen(),
                                                  ),
                                                ),
                                            style: TextButton.styleFrom(
                                              minimumSize: const Size(48, 48),
                                              foregroundColor: const Color(
                                                0xFF9FB0C6,
                                              ),
                                            ),
                                            child: const Text('حریم خصوصی'),
                                          ),
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int? _findNextPlayableIndex(SeasonDefinition season) {
    for (final slot in season.slots) {
      final index = slot.catalogIndex;
      final level = slot.level;
      if (index != null &&
          level != null &&
          _progression.isLevelUnlocked(index) &&
          !_progression.isCompleted(level.id)) {
        return index;
      }
    }
    return null;
  }

  bool _isSeasonUnlocked(SeasonDefinition season) {
    if (!season.hasPlayableLevels) return false;
    if (season.number == 1) return true;
    final previousSeason = _seasons[season.number - 2];
    return previousSeason.slots.every((slot) {
      final level = slot.level;
      return level != null && _progression.isCompleted(level.id);
    });
  }
}

class _LevelSelectHeader extends StatelessWidget {
  const _LevelSelectHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LogoMark(),
        SizedBox(width: 11),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'گره‌راه',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/gerehrah_icon.png',
        key: const Key('gerehrah-logo'),
        width: 42,
        height: 42,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.season,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final SeasonDefinition season;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'فصل قبلی',
          button: true,
          enabled: canGoPrevious,
          child: IconButton(
            key: const Key('previous-season'),
            tooltip: 'فصل قبلی',
            onPressed: canGoPrevious ? onPrevious : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        SizedBox(
          width: 150,
          child: Text(
            season.title,
            key: const Key('season-title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        Semantics(
          label: 'فصل بعدی',
          button: true,
          enabled: canGoNext,
          child: IconButton(
            key: const Key('next-season'),
            tooltip: 'فصل بعدی',
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
          ),
        ),
      ],
    );
  }
}

class _SeasonGrid extends StatelessWidget {
  const _SeasonGrid({
    required this.season,
    required this.progression,
    required this.nextPlayableIndex,
    required this.onPlay,
    required this.onDetails,
  });

  final SeasonDefinition season;
  final LevelProgression progression;
  final int? nextPlayableIndex;
  final ValueChanged<int> onPlay;
  final Future<void> Function({
    required PuzzleLevel level,
    required int levelNumber,
    required LevelBestResult? result,
  })
  onDetails;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: Key('season-${season.number}-grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: season.slots.length,
      itemBuilder: (context, index) {
        final slot = season.slots[index];
        final catalogIndex = slot.catalogIndex;
        final level = slot.level;
        if (catalogIndex == null || level == null) {
          return _LevelGridCell.locked(
            cellKey: Key('season-${season.number}-slot-${slot.number}'),
            seasonNumber: season.number,
            levelNumber: slot.number,
          );
        }

        final result = progression.resultFor(level.id);
        final completed = result != null;
        final unlocked = progression.isLevelUnlocked(catalogIndex);
        return _LevelGridCell(
          cellKey: Key('season-${season.number}-slot-${slot.number}'),
          seasonNumber: season.number,
          levelNumber: slot.number,
          completed: completed,
          unlocked: unlocked,
          highlighted: catalogIndex == nextPlayableIndex,
          onTap: unlocked ? () => onPlay(catalogIndex) : null,
          onLongPress: unlocked
              ? () => onDetails(
                  level: level,
                  levelNumber: slot.number,
                  result: result,
                )
              : null,
        );
      },
    );
  }
}

class _LevelGridCell extends StatelessWidget {
  const _LevelGridCell({
    required this.cellKey,
    required this.seasonNumber,
    required this.levelNumber,
    required this.completed,
    required this.unlocked,
    required this.highlighted,
    required this.onTap,
    required this.onLongPress,
  });

  const _LevelGridCell.locked({
    required this.cellKey,
    required this.seasonNumber,
    required this.levelNumber,
  }) : completed = false,
       unlocked = false,
       highlighted = false,
       onTap = null,
       onLongPress = null;

  final Key cellKey;
  final int seasonNumber;
  final int levelNumber;
  final bool completed;
  final bool unlocked;
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = completed
        ? const Color(0xFF5ED6A8)
        : highlighted
        ? const Color(0xFF76A9FF)
        : unlocked
        ? const Color(0xFF9ABCF5)
        : const Color(0xFF64748B);
    final semanticState = completed
        ? 'کامل‌شده'
        : highlighted
        ? 'مرحلهٔ فعلی'
        : unlocked
        ? 'باز'
        : 'قفل';
    final fill = highlighted
        ? const Color(0xFF18304F)
        : unlocked
        ? const Color(0xFF111D2E)
        : const Color(0xFF0D1725);

    return Semantics(
      key: cellKey,
      label:
          'فصل ${persianDigits(seasonNumber)}، مرحله ${persianDigits(levelNumber)}، $semanticState',
      hint: unlocked ? 'برای بازی دو بار بزن. برای جزئیات نگه دار.' : null,
      button: true,
      enabled: unlocked,
      excludeSemantics: true,
      child: Material(
        key: highlighted ? Key('level-highlight-$levelNumber') : null,
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: highlighted ? accent : const Color(0xFF263A54),
            width: highlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (unlocked)
                Text(
                  persianDigits(levelNumber),
                  key: Key('level-number-$levelNumber'),
                  style: TextStyle(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Icon(
                  Icons.lock_rounded,
                  key: Key('level-lock-$levelNumber'),
                  color: accent,
                  size: 20,
                ),
              if (completed)
                PositionedDirectional(
                  top: 5,
                  end: 5,
                  child: Icon(
                    Icons.check_circle_rounded,
                    key: Key('level-completed-$levelNumber'),
                    color: accent,
                    size: 15,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelDetailsSheet extends StatelessWidget {
  const _LevelDetailsSheet({
    required this.level,
    required this.levelNumber,
    required this.result,
  });

  final PuzzleLevel level;
  final int levelNumber;
  final LevelBestResult? result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        key: const Key('level-details'),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحله ${persianDigits(levelNumber)} · ${level.title}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'صفحه: ${persianDigits(level.rows)}×${persianDigits(level.columns)}',
              key: const Key('level-detail-board'),
              style: const TextStyle(color: Color(0xFFB3C0D1)),
            ),
            const SizedBox(height: 6),
            Text(
              'کمترین حرکت: ${persianDigits(result?.bestMoves ?? '—')}',
              key: const Key('level-detail-moves'),
              style: const TextStyle(color: Color(0xFFB3C0D1)),
            ),
            const SizedBox(height: 6),
            Text(
              'بهترین زمان: '
              '${result == null ? '—' : _formatSeconds(result!.bestTimeSeconds)}',
              key: const Key('level-detail-time'),
              style: const TextStyle(color: Color(0xFFB3C0D1)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSeconds(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return persianDigits('$minutes:$seconds');
}
