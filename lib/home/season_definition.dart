import '../game/puzzle_level.dart';

const levelsPerSeason = 20;

class SeasonLevelSlot {
  const SeasonLevelSlot({
    required this.number,
    required this.catalogIndex,
    required this.level,
  });

  const SeasonLevelSlot.placeholder({required this.number})
    : catalogIndex = null,
      level = null;

  final int number;
  final int? catalogIndex;
  final PuzzleLevel? level;

  bool get isPlayable => level != null && catalogIndex != null;
}

class SeasonDefinition {
  const SeasonDefinition({
    required this.number,
    required this.slots,
    this.lockedMessage,
  }) : assert(slots.length == levelsPerSeason);

  factory SeasonDefinition.playable({
    required int number,
    required List<PuzzleLevel> levels,
    int catalogOffset = 0,
  }) {
    if (levels.length != levelsPerSeason) {
      throw ArgumentError.value(
        levels.length,
        'levels',
        'a season requires exactly $levelsPerSeason levels',
      );
    }
    return SeasonDefinition(
      number: number,
      lockedMessage: number > 1
          ? 'Complete Season ${number - 1} to unlock'
          : null,
      slots: List.unmodifiable([
        for (var index = 0; index < levels.length; index++)
          SeasonLevelSlot(
            number: index + 1,
            catalogIndex: catalogOffset + index,
            level: levels[index],
          ),
      ]),
    );
  }

  factory SeasonDefinition.placeholder({
    required int number,
    required String lockedMessage,
  }) {
    return SeasonDefinition(
      number: number,
      lockedMessage: lockedMessage,
      slots: List.unmodifiable([
        for (var index = 0; index < levelsPerSeason; index++)
          SeasonLevelSlot.placeholder(number: index + 1),
      ]),
    );
  }

  final int number;
  final List<SeasonLevelSlot> slots;
  final String? lockedMessage;

  String get title => 'Season $number';
  bool get hasPlayableLevels => slots.any((slot) => slot.isPlayable);
}

List<SeasonDefinition> buildPathlySeasons(List<PuzzleLevel> catalogLevels) {
  if (catalogLevels.isEmpty || catalogLevels.length % levelsPerSeason != 0) {
    throw ArgumentError.value(
      catalogLevels.length,
      'catalogLevels',
      'the catalog must contain complete $levelsPerSeason-level seasons',
    );
  }
  final playableSeasonCount = catalogLevels.length ~/ levelsPerSeason;
  final seasons = <SeasonDefinition>[
    for (var index = 0; index < playableSeasonCount; index++)
      SeasonDefinition.playable(
        number: index + 1,
        catalogOffset: index * levelsPerSeason,
        levels: catalogLevels.sublist(
          index * levelsPerSeason,
          (index + 1) * levelsPerSeason,
        ),
      ),
    SeasonDefinition.placeholder(
      number: playableSeasonCount + 1,
      lockedMessage: 'Complete Season $playableSeasonCount to unlock',
    ),
  ];
  return List.unmodifiable(seasons);
}
