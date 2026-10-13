import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/analytics/app_analytics_service.dart';

void main() {
  test('default analytics does not initialize or contact Firebase', () async {
    expect(firebaseEnabled, isFalse);
    final service = FirebaseAppAnalyticsService();
    await service.logShareAppClick();
    await service.logTutorialView();
    await service.logInvalidMove();
  });
  test(
    'share uses the single expected event name without parameters',
    () async {
      final client = _FakeAnalyticsEventClient();
      final service = FirebaseAppAnalyticsService(client: client);

      await service.logShareAppClick();

      expect(client.events, [(name: 'share_app_click', parameters: null)]);
    },
  );

  test('level completion uses the expected event name and payload', () async {
    final client = _FakeAnalyticsEventClient();
    final service = FirebaseAppAnalyticsService(client: client);

    await service.logLevelComplete(
      levelId: 'season-2-01',
      seasonNumber: 2,
      levelNumber: 1,
      moves: 18,
      completionTimeSeconds: 42,
    );

    expect(client.events, hasLength(1));
    expect(client.events.single.name, 'level_complete');
    expect(client.events.single.parameters, {
      'level_id': 'season-2-01',
      'season_number': 2,
      'level_number': 1,
      'moves': 18,
      'completion_time_seconds': 42,
    });
  });

  test('tutorial and invalid move events use no parameters', () async {
    final client = _FakeAnalyticsEventClient();
    final service = FirebaseAppAnalyticsService(client: client);

    await service.logTutorialView();
    await service.logTutorialComplete();
    await service.logInvalidMove();

    expect(client.events, [
      (name: 'tutorial_view', parameters: null),
      (name: 'tutorial_complete', parameters: null),
      (name: 'invalid_move', parameters: null),
    ]);
  });
}

class _FakeAnalyticsEventClient implements AnalyticsEventClient {
  final List<({String name, Map<String, Object>? parameters})> events = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add((name: name, parameters: parameters));
  }
}
