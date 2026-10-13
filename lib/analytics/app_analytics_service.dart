import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

const firebaseEnabled = bool.fromEnvironment('ENABLE_FIREBASE');

const shareAppClickEventName = 'share_app_click';
const levelCompleteEventName = 'level_complete';
const tutorialViewEventName = 'tutorial_view';
const tutorialCompleteEventName = 'tutorial_complete';
const invalidMoveEventName = 'invalid_move';

abstract interface class AppAnalyticsService {
  Future<void> logShareAppClick();

  Future<void> logTutorialView();

  Future<void> logTutorialComplete();

  Future<void> logInvalidMove();

  Future<void> logLevelComplete({
    required String levelId,
    required int seasonNumber,
    required int levelNumber,
    required int moves,
    required int completionTimeSeconds,
  });
}

abstract interface class AnalyticsEventClient {
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });
}

class FirebaseAppAnalyticsService implements AppAnalyticsService {
  FirebaseAppAnalyticsService({AnalyticsEventClient? client})
    : _client = client ?? _FirebaseAnalyticsEventClient();

  final AnalyticsEventClient _client;

  @override
  Future<void> logShareAppClick() {
    return _client.logEvent(name: shareAppClickEventName);
  }

  @override
  Future<void> logTutorialView() {
    return _client.logEvent(name: tutorialViewEventName);
  }

  @override
  Future<void> logTutorialComplete() {
    return _client.logEvent(name: tutorialCompleteEventName);
  }

  @override
  Future<void> logInvalidMove() {
    return _client.logEvent(name: invalidMoveEventName);
  }

  @override
  Future<void> logLevelComplete({
    required String levelId,
    required int seasonNumber,
    required int levelNumber,
    required int moves,
    required int completionTimeSeconds,
  }) {
    return _client.logEvent(
      name: levelCompleteEventName,
      parameters: {
        'level_id': levelId,
        'season_number': seasonNumber,
        'level_number': levelNumber,
        'moves': moves,
        'completion_time_seconds': completionTimeSeconds,
      },
    );
  }
}

class _FirebaseAnalyticsEventClient implements AnalyticsEventClient {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    if (!firebaseEnabled || Firebase.apps.isEmpty) return Future<void>.value();
    return FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}

void logAnalyticsSafely(Future<void> Function() logEvent) {
  unawaited(Future<void>.sync(logEvent).catchError((Object _) {}));
}
