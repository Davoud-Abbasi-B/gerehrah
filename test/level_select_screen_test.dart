import 'package:gerehrah/localization/persian.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/analytics/app_analytics_service.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/game/path_board.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/home/level_select_screen.dart';
import 'package:gerehrah/onboarding/how_to_play.dart';
import 'package:gerehrah/progress/progress_repository.dart';
import 'package:gerehrah/share/app_share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<PuzzleLevel> levels;

  setUpAll(() async {
    levels = await LevelRepository().loadLevels();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      tutorialCompletedPreferenceKey: true,
    });
  });

  testWidgets('new user sees tutorial and Got it persists completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final analytics = _FakeAnalyticsService();
    await _pumpScreen(tester, levels, analyticsService: analytics);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('how-to-play-sheet')), findsOneWidget);
    expect(find.text('نقطه‌های هم‌رنگ را به هم وصل کن'), findsOneWidget);
    expect(find.text('همهٔ خانه‌های صفحه را پر کن'), findsOneWidget);
    expect(
      find.text('مسیرها نباید همدیگر را قطع کنند یا روی هم بیفتند'),
      findsOneWidget,
    );
    expect(analytics.tutorialViewCalls, 1);

    await tester.tap(find.byKey(const Key('tutorial-got-it')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('how-to-play-sheet')), findsNothing);
    expect(analytics.tutorialCompleteCalls, 1);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        tutorialCompletedPreferenceKey,
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpScreen(tester, levels, analyticsService: analytics);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('how-to-play-sheet')), findsNothing);
  });

  testWidgets('manual How to Play opens the same tutorial', (tester) async {
    final analytics = _FakeAnalyticsService();
    await _pumpScreen(tester, levels, analyticsService: analytics);
    await tester.scrollUntilVisible(
      find.byKey(const Key('how-to-play')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('how-to-play')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('how-to-play-sheet')), findsOneWidget);
    expect(analytics.tutorialViewCalls, 1);
    final gotIt = tester.widget<FilledButton>(
      find.byKey(const Key('tutorial-got-it')),
    );
    gotIt.onPressed!();
    gotIt.onPressed!();
    await tester.pumpAndSettle();
    expect(analytics.tutorialCompleteCalls, 1);
  });

  testWidgets('فصل ۱ starts with a compact ordered ۵ by ۴ grid', (
    tester,
  ) async {
    await _pumpScreen(tester, levels);

    expect(find.text('انتخاب مرحله'), findsOneWidget);
    expect(find.text('فصل ۱'), findsOneWidget);
    expect(find.text('پیشرفت: ۰ از ۲۰'), findsOneWidget);
    expect(find.byKey(const Key('season-1-grid')), findsOneWidget);
    for (var number = 1; number <= 20; number++) {
      expect(find.byKey(Key('season-1-slot-$number')), findsOneWidget);
    }
    expect(find.byKey(const Key('level-highlight-1')), findsOneWidget);
    expect(find.byKey(const Key('level-number-1')), findsOneWidget);
    expect(find.byKey(const Key('level-lock-2')), findsOneWidget);
    expect(find.byKey(const Key('level-number-2')), findsNothing);
    expect(find.byKey(const Key('level-card-1')), findsNothing);
    expect(find.byKey(const Key('share-app')), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);

    final gerehrahTop = tester.getTopLeft(find.text('گره‌راه')).dy;
    final selectHeading = find.byKey(const Key('select-level-heading'));
    final selectTop = tester.getTopLeft(selectHeading).dy;
    final seasonTop = tester.getTopLeft(find.text('فصل ۱')).dy;
    expect(gerehrahTop, lessThan(selectTop));
    expect(selectTop, lessThan(seasonTop));
    expect(gerehrahTop, inInclusiveRange(32, 48));
    expect(
      tester.getCenter(selectHeading).dx,
      closeTo(tester.getSize(find.byType(Scaffold)).width / 2, 0.5),
    );

    final grid = tester.widget<GridView>(
      find.byKey(const Key('season-1-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 5);

    final firstRow = [
      for (var number = 1; number <= 5; number++)
        tester.getTopLeft(find.byKey(Key('season-1-slot-$number'))),
    ];
    final secondRow = [
      for (var number = 6; number <= 10; number++)
        tester.getTopLeft(find.byKey(Key('season-1-slot-$number'))),
    ];
    expect(firstRow.map((offset) => offset.dy).toSet(), hasLength(1));
    expect(secondRow.map((offset) => offset.dy).toSet(), hasLength(1));
    expect(firstRow.map((offset) => offset.dx).toSet(), hasLength(5));
    expect(secondRow.first.dy, greaterThan(firstRow.first.dy));
    expect({
      for (var number = 1; number <= 20; number++)
        tester.getTopLeft(find.byKey(Key('season-1-slot-$number'))).dy,
    }, hasLength(4));
    expect(_iconButton(tester, 'previous-season').tooltip, 'فصل قبلی');
    expect(_iconButton(tester, 'next-season').tooltip, 'فصل بعدی');

    final highlight = tester.widget<Material>(
      find.byKey(const Key('level-highlight-1')),
    );
    final highlightShape = highlight.shape! as RoundedRectangleBorder;
    expect(highlightShape.side.color, const Color(0xFF76A9FF));
    expect(highlightShape.side.width, 2);
    final decorativeDots = find.descendant(
      of: find.byKey(const Key('season-1-slot-1')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    expect(decorativeDots, findsNothing);
  });

  testWidgets('season arrows navigate through locked Seasons 2 through 6', (
    tester,
  ) async {
    await _pumpScreen(tester, levels);

    expect(_iconButton(tester, 'previous-season').onPressed, isNull);
    expect(_iconButton(tester, 'next-season').onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('next-season')));
    await tester.pump();

    expect(find.text('فصل ۲'), findsOneWidget);
    expect(find.text('پیشرفت: ۰ از ۲۰'), findsOneWidget);
    expect(find.text('برای باز شدن، فصل ۱ را کامل کن'), findsOneWidget);
    for (var number = 1; number <= 20; number++) {
      expect(find.byKey(Key('season-2-slot-$number')), findsOneWidget);
    }
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(20));
    expect(_iconButton(tester, 'previous-season').onPressed, isNotNull);
    expect(_iconButton(tester, 'next-season').onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('season-2-slot-1')));
    await tester.longPress(find.byKey(const Key('season-2-slot-1')));
    await tester.pump();
    expect(find.byKey(const Key('move-count')), findsNothing);
    expect(find.byKey(const Key('level-details')), findsNothing);

    for (var season = 3; season <= 5; season++) {
      await tester.tap(find.byKey(const Key('next-season')));
      await tester.pump();
      expect(find.text('فصل ${persianDigits(season)}'), findsOneWidget);
      expect(
        find.text('برای باز شدن، فصل ${persianDigits(season - 1)} را کامل کن'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsNWidgets(20));
      expect(_iconButton(tester, 'previous-season').onPressed, isNotNull);
      expect(_iconButton(tester, 'next-season').onPressed, isNotNull);
    }

    await tester.tap(find.byKey(const Key('next-season')));
    await tester.pump();
    expect(find.text('فصل ۶'), findsOneWidget);
    expect(find.text('برای باز شدن، فصل ۵ را کامل کن'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(20));
    expect(_iconButton(tester, 'previous-season').onPressed, isNotNull);
    expect(_iconButton(tester, 'next-season').onPressed, isNull);
    await tester.tap(find.byKey(const Key('season-6-slot-1')));
    await tester.longPress(find.byKey(const Key('season-6-slot-1')));
    await tester.pump();
    expect(find.byKey(const Key('move-count')), findsNothing);
    expect(find.byKey(const Key('level-details')), findsNothing);

    for (var season = 5; season >= 1; season--) {
      await tester.tap(find.byKey(const Key('previous-season')));
      await tester.pump();
      expect(find.text('فصل ${persianDigits(season)}'), findsOneWidget);
    }
    expect(find.text('فصل ۱'), findsOneWidget);
  });

  testWidgets('locked and completed cells expose accessible states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await SharedPreferencesProgressRepository().saveCompletedLevel(
      levelId: 'crossroads-4',
      moves: 7,
      timeSeconds: 65,
    );
    await _pumpScreen(tester, levels, extraPumps: 2);

    expect(find.text('پیشرفت: ۱ از ۲۰'), findsOneWidget);
    expect(find.byKey(const Key('level-completed-1')), findsOneWidget);
    expect(find.byKey(const Key('level-number-2')), findsOneWidget);
    expect(find.byKey(const Key('level-highlight-2')), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('season-1-slot-1'))).label,
      'فصل ۱، مرحله ۱، کامل‌شده',
    );
    expect(
      tester.getSemantics(find.byKey(const Key('season-1-slot-3'))).label,
      'فصل ۱، مرحله ۳، قفل',
    );
    semantics.dispose();
  });

  testWidgets('Share App is accessible and calls the injected service', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final shareService = _FakeShareService();
    final analyticsService = _FakeAnalyticsService();
    await _pumpScreen(
      tester,
      levels,
      shareService: shareService,
      analyticsService: analyticsService,
    );

    expect(
      tester.getSemantics(find.byKey(const Key('share-app'))).label,
      'اشتراک‌گذاری گره‌راه',
    );
    expect(
      tester.getSemantics(find.byKey(const Key('season-1-slot-1'))).label,
      'فصل ۱، مرحله ۱، مرحلهٔ فعلی',
    );
    expect(
      tester
          .widget<Tooltip>(
            find.ancestor(
              of: find.byKey(const Key('share-app')),
              matching: find.byType(Tooltip),
            ),
          )
          .message,
      'اشتراک‌گذاری گره‌راه',
    );

    await _tapShare(tester);
    await tester.pump();

    expect(shareService.calls, 1);
    expect(analyticsService.shareCalls, 1);
    expect(shareService.lastSharePositionOrigin, isNotNull);
    expect(find.byKey(const Key('share-error-snackbar')), findsNothing);
    semantics.dispose();
  });

  testWidgets('analytics failure does not prevent native sharing', (
    tester,
  ) async {
    final shareService = _FakeShareService();
    final analyticsService = _FakeAnalyticsService(
      error: StateError('analytics unavailable'),
    );
    await _pumpScreen(
      tester,
      levels,
      shareService: shareService,
      analyticsService: analyticsService,
    );

    await _tapShare(tester);
    await tester.pump();

    expect(analyticsService.shareCalls, 1);
    expect(shareService.calls, 1);
    expect(find.byKey(const Key('share-error-snackbar')), findsNothing);
  });

  testWidgets('share failure shows a compact error SnackBar', (tester) async {
    final shareService = _FakeShareService(error: StateError('unavailable'));
    await _pumpScreen(tester, levels, shareService: shareService);

    await _tapShare(tester);
    await tester.pump();

    expect(find.byKey(const Key('share-error-snackbar')), findsOneWidget);
    expect(find.text('فعلاً امکان اشتراک‌گذاری بازی نیست.'), findsOneWidget);
  });

  testWidgets('share cancellation does not show an error', (tester) async {
    final shareService = _FakeShareService();
    await _pumpScreen(tester, levels, shareService: shareService);

    await _tapShare(tester);
    await tester.pump();

    expect(shareService.calls, 1);
    expect(find.byKey(const Key('share-error-snackbar')), findsNothing);
  });

  test('share copy is centralized and contains the permanent store link', () {
    expect(
      gerehrahShareMessage,
      'گره‌راه رو امتحان کن؛ نقطه‌های هم‌رنگ رو وصل کن و همهٔ صفحه رو پر کن!\n\n'
      'https://cafebazaar.ir/app/com.damostudio.gerehrah',
    );
    expect(
      gerehrahShareMessage,
      contains(
        'گره‌راه رو امتحان کن؛ نقطه‌های هم‌رنگ رو وصل کن و همهٔ صفحه رو پر کن!',
      ),
    );
    expect(
      gerehrahShareMessage,
      contains('https://cafebazaar.ir/app/com.damostudio.gerehrah'),
    );
  });

  testWidgets('tap plays immediately and locked levels do nothing', (
    tester,
  ) async {
    await _pumpScreen(tester, levels);

    await tester.tap(find.byKey(const Key('season-1-slot-2')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('move-count')), findsNothing);

    await tester.tap(find.byKey(const Key('season-1-slot-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('چهارراه'), findsOneWidget);
    expect(find.text('حرکت: ۰'), findsOneWidget);
  });

  testWidgets('long press exposes records but locked cells expose no details', (
    tester,
  ) async {
    await SharedPreferencesProgressRepository().saveCompletedLevel(
      levelId: 'crossroads-4',
      moves: 7,
      timeSeconds: 65,
    );
    await _pumpScreen(tester, levels, extraPumps: 2);

    await tester.longPress(find.byKey(const Key('season-1-slot-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('level-details')), findsOneWidget);
    expect(find.text('مرحله ۱ · چهارراه'), findsOneWidget);
    expect(find.text('صفحه: ۴×۴'), findsOneWidget);
    expect(find.text('کمترین حرکت: ۷'), findsOneWidget);
    expect(find.text('بهترین زمان: ۰۱:۰۵'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('season-1-slot-2')));
    await tester.pumpAndSettle();
    expect(find.text('مرحله ۲ · سه مسیر'), findsOneWidget);
    expect(find.text('صفحه: ۵×۵'), findsOneWidget);
    expect(find.text('کمترین حرکت: —'), findsOneWidget);
    expect(find.text('بهترین زمان: —'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('season-1-slot-3')));
    await tester.pump();
    expect(find.byKey(const Key('level-details')), findsNothing);
  });

  testWidgets('returning after completion refreshes progress and unlocking', (
    tester,
  ) async {
    late PathBoard board;
    final repository = _MemoryProgressRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LevelSelectScreen(
          levels: levels,
          progressRepository: repository,
          boardFactory: (level) {
            board = PathBoard(level);
            return board;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('season-1-slot-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    _solve(board);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    await tester.tap(find.byKey(const Key('back-to-levels')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('پیشرفت: ۱ از ۲۰'), findsOneWidget);
    expect(find.byKey(const Key('level-completed-1')), findsOneWidget);
    expect(find.byKey(const Key('level-number-2')), findsOneWidget);
    expect(repository.completedLevels, contains('crossroads-4'));
  });

  testWidgets('فصل ۲ unlocks sequentially with independent progress', (
    tester,
  ) async {
    await _completeSeasonOne(levels);
    await _pumpScreen(tester, levels, extraPumps: 2);

    await tester.tap(find.byKey(const Key('next-season')));
    await tester.pump();

    expect(find.text('فصل ۲'), findsOneWidget);
    expect(find.text('برای باز شدن، فصل ۱ را کامل کن'), findsNothing);
    expect(find.text('پیشرفت: ۰ از ۲۰'), findsOneWidget);
    expect(find.byKey(const Key('level-number-1')), findsOneWidget);
    expect(find.byKey(const Key('level-lock-2')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(19));

    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byKey(const Key('season-2-slot-1'))).label,
      'فصل ۲، مرحله ۱، مرحلهٔ فعلی',
    );
    expect(
      tester.getSemantics(find.byKey(const Key('season-2-slot-2'))).label,
      'فصل ۲، مرحله ۲، قفل',
    );
    semantics.dispose();
  });

  testWidgets('فصل ۲ records open only for unlocked cells', (tester) async {
    await _completeSeasonOne(levels);
    await SharedPreferencesProgressRepository().saveCompletedLevel(
      levelId: levels[20].id,
      moves: 14,
      timeSeconds: 95,
    );
    await _pumpScreen(tester, levels, extraPumps: 2);
    await tester.tap(find.byKey(const Key('next-season')));
    await tester.pump();

    expect(find.text('پیشرفت: ۱ از ۲۰'), findsOneWidget);
    await tester.longPress(find.byKey(const Key('season-2-slot-1')));
    await tester.pumpAndSettle();
    expect(find.text('مرحله ۱ · راه پرگره'), findsOneWidget);
    expect(find.text('صفحه: ۵×۵'), findsOneWidget);
    expect(find.text('کمترین حرکت: ۱۴'), findsOneWidget);
    expect(find.text('بهترین زمان: ۰۱:۳۵'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('season-2-slot-3')));
    await tester.pump();
    expect(find.byKey(const Key('level-details')), findsNothing);
  });

  testWidgets('فصل ۵ starts with only its local مرحله ۱ available', (
    tester,
  ) async {
    await _completeLevels(levels.take(80));
    await _pumpScreen(tester, levels, extraPumps: 2);
    for (var season = 2; season <= 5; season++) {
      await tester.tap(find.byKey(const Key('next-season')));
      await tester.pump();
    }

    expect(find.text('فصل ۵'), findsOneWidget);
    expect(find.text('برای باز شدن، فصل ۴ را کامل کن'), findsNothing);
    expect(find.text('پیشرفت: ۰ از ۲۰'), findsOneWidget);
    expect(find.byKey(const Key('level-number-1')), findsOneWidget);
    expect(find.byKey(const Key('level-lock-2')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(19));

    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byKey(const Key('season-5-slot-1'))).label,
      'فصل ۵، مرحله ۱، مرحلهٔ فعلی',
    );
    semantics.dispose();
  });

  testWidgets('Seasons 3 through 5 expose persisted records', (tester) async {
    await _completeLevels(levels.take(81));
    await _pumpScreen(tester, levels, extraPumps: 2);
    const expectedTitles = {3: 'گذر منظم', 4: 'ورودی استاد', 5: 'ورودی بزرگ'};

    for (var season = 2; season <= 5; season++) {
      await tester.tap(find.byKey(const Key('next-season')));
      await tester.pump();
      if (season < 3) continue;
      await tester.longPress(find.byKey(Key('season-$season-slot-1')));
      await tester.pumpAndSettle();
      expect(find.text('مرحله ۱ · ${expectedTitles[season]}'), findsOneWidget);
      expect(find.text('صفحه: ۶×۶'), findsOneWidget);
      expect(find.text('کمترین حرکت: ۱۰'), findsOneWidget);
      expect(find.text('بهترین زمان: ۰۱:۰۰'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  });
}

IconButton _iconButton(WidgetTester tester, String key) {
  return tester.widget<IconButton>(find.byKey(Key(key)));
}

Future<void> _tapShare(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('share-app')),
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const Key('share-app')));
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<PuzzleLevel> levels, {
  int extraPumps = 0,
  AppShareService? shareService,
  AppAnalyticsService? analyticsService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LevelSelectScreen(
        levels: levels,
        shareService: shareService,
        analyticsService: analyticsService,
      ),
    ),
  );
  await tester.pump();
  for (var index = 0; index < extraPumps; index++) {
    await tester.pump();
  }
}

Future<void> _completeSeasonOne(List<PuzzleLevel> levels) async {
  await _completeLevels(levels.take(20));
}

Future<void> _completeLevels(Iterable<PuzzleLevel> levels) async {
  final repository = SharedPreferencesProgressRepository();
  for (final level in levels) {
    await repository.saveCompletedLevel(
      levelId: level.id,
      moves: 10,
      timeSeconds: 60,
    );
  }
}

void _solve(PathBoard board) {
  for (final path in board.level.primarySolution.paths) {
    board.begin(path.cells.first);
    for (final cell in path.cells.skip(1)) {
      board.moveTo(cell);
    }
    board.end();
  }
}

class _MemoryProgressRepository implements ProgressRepository {
  final Map<String, LevelBestResult> completedLevels = {};

  @override
  Future<PlayerProgress> load() async => PlayerProgress(completedLevels);

  @override
  Future<LevelBestResult> saveCompletedLevel({
    required String levelId,
    required int moves,
    required int timeSeconds,
  }) async {
    final result = LevelBestResult(
      bestMoves: moves,
      bestTimeSeconds: timeSeconds,
    );
    completedLevels[levelId] = result;
    return result;
  }
}

class _FakeShareService implements AppShareService {
  _FakeShareService({this.error});

  final Object? error;
  int calls = 0;
  Rect? lastSharePositionOrigin;

  @override
  Future<void> shareApp({Rect? sharePositionOrigin}) async {
    calls++;
    lastSharePositionOrigin = sharePositionOrigin;
    final error = this.error;
    if (error != null) throw error;
  }
}

class _FakeAnalyticsService implements AppAnalyticsService {
  _FakeAnalyticsService({this.error});

  final Object? error;
  int shareCalls = 0;
  int tutorialViewCalls = 0;
  int tutorialCompleteCalls = 0;

  @override
  Future<void> logShareAppClick() async {
    shareCalls++;
    final error = this.error;
    if (error != null) throw error;
  }

  @override
  Future<void> logTutorialView() async {
    tutorialViewCalls++;
  }

  @override
  Future<void> logTutorialComplete() async {
    tutorialCompleteCalls++;
  }

  @override
  Future<void> logInvalidMove() async {}

  @override
  Future<void> logLevelComplete({
    required String levelId,
    required int seasonNumber,
    required int levelNumber,
    required int moves,
    required int completionTimeSeconds,
  }) async {}
}
