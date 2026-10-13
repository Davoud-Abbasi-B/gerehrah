import 'package:gerehrah/localization/persian.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/level_repository.dart';
import 'package:gerehrah/home/season_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds five playable seasons and one placeholder', () async {
    final levels = await LevelRepository().loadLevels();
    final seasons = buildGerehrahSeasons(levels);

    expect(seasons, hasLength(6));
    for (var seasonIndex = 0; seasonIndex < 5; seasonIndex++) {
      final season = seasons[seasonIndex];
      expect(season.title, 'فصل ${persianDigits(seasonIndex + 1)}');
      expect(season.slots, hasLength(20));
      expect(season.slots.every((slot) => slot.isPlayable), isTrue);
      expect(
        season.slots.map((slot) => slot.level!.id),
        levels.skip(seasonIndex * 20).take(20).map((level) => level.id),
      );
      if (seasonIndex > 0) {
        expect(
          season.lockedMessage,
          'برای باز شدن، فصل ${persianDigits(seasonIndex)} را کامل کن',
        );
      }
    }
    expect(seasons[5].title, 'فصل ۶');
    expect(seasons[5].slots, hasLength(20));
    expect(seasons[5].slots.every((slot) => !slot.isPlayable), isTrue);
    expect(seasons[5].lockedMessage, 'برای باز شدن، فصل ۵ را کامل کن');
  });
}
