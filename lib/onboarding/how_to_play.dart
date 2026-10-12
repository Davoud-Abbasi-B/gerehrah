import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/app_analytics_service.dart';

const tutorialCompletedPreferenceKey = 'how_to_play_completed';

Future<bool> isTutorialCompleted() async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(tutorialCompletedPreferenceKey) ?? false;
}

Future<void> showHowToPlay({
  required BuildContext context,
  required AppAnalyticsService analyticsService,
}) async {
  logAnalyticsSafely(analyticsService.logTutorialView);
  var completedThisDisplay = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF111D2E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          18,
          24,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          key: const Key('how-to-play-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF52647C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How to Play',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            const _TutorialRule(number: '1', text: 'Connect matching colors'),
            const _TutorialRule(number: '2', text: 'Fill the entire board'),
            const _TutorialRule(
              number: '3',
              text: "Paths can't cross or overlap",
            ),
            const SizedBox(height: 22),
            FilledButton(
              key: const Key('tutorial-got-it'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF76A9FF),
                foregroundColor: const Color(0xFF08111F),
              ),
              onPressed: () async {
                if (completedThisDisplay) return;
                completedThisDisplay = true;
                logAnalyticsSafely(analyticsService.logTutorialComplete);
                final preferences = await SharedPreferences.getInstance();
                await preferences.setBool(tutorialCompletedPreferenceKey, true);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text(
                'Got it',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TutorialRule extends StatelessWidget {
  const _TutorialRule({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1B304A),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF76A9FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
