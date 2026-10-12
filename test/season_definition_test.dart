import 'package:flutter_test/flutter_test.dart';
import 'package:pathly/game/level_repository.dart';
import 'package:pathly/home/season_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds five playable seasons and one placeholder', () async {
    final levels = await LevelRepository().loadLevels();
    final seasons = buildPathlySeasons(levels);

    expect(seasons, hasLength(6));
    for (var seasonIndex = 0; seasonIndex < 5; seasonIndex++) {
      final season = seasons[seasonIndex];
      expect(season.title, 'Season ${seasonIndex + 1}');
      expect(season.slots, hasLength(20));
      expect(season.slots.every((slot) => slot.isPlayable), isTrue);
      expect(
        season.slots.map((slot) => slot.level!.id),
        levels.skip(seasonIndex * 20).take(20).map((level) => level.id),
      );
      if (seasonIndex > 0) {
        expect(season.lockedMessage, 'Complete Season $seasonIndex to unlock');
      }
    }
    expect(seasons[5].title, 'Season 6');
    expect(seasons[5].slots, hasLength(20));
    expect(seasons[5].slots.every((slot) => !slot.isPlayable), isTrue);
    expect(seasons[5].lockedMessage, 'Complete Season 5 to unlock');
  });
}
