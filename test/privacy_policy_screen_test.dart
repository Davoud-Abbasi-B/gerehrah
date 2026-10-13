import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/home/level_select_screen.dart';
import 'package:gerehrah/onboarding/how_to_play.dart';
import 'package:gerehrah/privacy/privacy_policy_screen.dart';
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

  testWidgets('Privacy Policy action is accessible and opens the policy', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(home: LevelSelectScreen(levels: levels)),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('privacy-policy')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    final action = find.byKey(const Key('privacy-policy'));
    expect(action, findsOneWidget);
    expect(tester.getSemantics(action).label, 'حریم خصوصی');
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'حریم خصوصی'), findsOneWidget);
    expect(find.textContaining('شناسهٔ مرحله‌های کامل‌شده'), findsOneWidget);
    expect(
      find.textContaining('در این نسخه ارسال آمار و گزارش خطا'),
      findsOneWidget,
    );
    expect(find.textContaining('Firebase Analytics'), findsWidgets);
    expect(find.textContaining('Firebase Crashlytics'), findsWidgets);
    expect(find.textContaining('AD_ID'), findsOneWidget);
    expect(find.textContaining('share_app_click'), findsOneWidget);
    expect(find.textContaining('level_complete'), findsOneWidget);
    expect(find.textContaining('اطلاعات شخصی را نمی‌فروشند'), findsOneWidget);
    expect(find.byKey(const Key('privacy-policy-scroll')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('privacy-policy-contact')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('privacy-policy-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.textContaining('سازنده: DaMo Studio'), findsOneWidget);
    expect(find.textContaining('https://damo-studio.com'), findsOneWidget);
    expect(find.textContaining('info@damo-studio.com'), findsOneWidget);
    final retiredContactMarker = ['TO', 'BE', 'ADDED'].join(' ');
    expect(find.textContaining(retiredContactMarker), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LevelSelectScreen), findsOneWidget);
    semantics.dispose();
  });

  for (final size in const <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets(
      'Privacy Policy has no overflow at ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
        await tester.pump();

        expect(find.byKey(const Key('privacy-policy-scroll')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
