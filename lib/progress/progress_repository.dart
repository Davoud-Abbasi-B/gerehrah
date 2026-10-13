import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LevelBestResult {
  const LevelBestResult({
    required this.bestMoves,
    required this.bestTimeSeconds,
  });

  final int bestMoves;
  final int bestTimeSeconds;

  LevelBestResult improvedWith({required int moves, required int timeSeconds}) {
    return LevelBestResult(
      bestMoves: moves < bestMoves ? moves : bestMoves,
      bestTimeSeconds: timeSeconds < bestTimeSeconds
          ? timeSeconds
          : bestTimeSeconds,
    );
  }
}

class PlayerProgress {
  const PlayerProgress(this.completedLevels);

  const PlayerProgress.empty() : completedLevels = const {};

  final Map<String, LevelBestResult> completedLevels;
}

abstract interface class ProgressRepository {
  Future<PlayerProgress> load();

  Future<LevelBestResult> saveCompletedLevel({
    required String levelId,
    required int moves,
    required int timeSeconds,
  });
}

class SharedPreferencesProgressRepository implements ProgressRepository {
  static const _storageKey = 'gerehrah.player_progress.v1';

  @override
  Future<PlayerProgress> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return _decode(preferences.getString(_storageKey));
    } on Object {
      return const PlayerProgress.empty();
    }
  }

  @override
  Future<LevelBestResult> saveCompletedLevel({
    required String levelId,
    required int moves,
    required int timeSeconds,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final progress = _decode(preferences.getString(_storageKey));
    final previous = progress.completedLevels[levelId];
    final result = previous == null
        ? LevelBestResult(bestMoves: moves, bestTimeSeconds: timeSeconds)
        : previous.improvedWith(moves: moves, timeSeconds: timeSeconds);
    final updated = Map<String, LevelBestResult>.of(progress.completedLevels)
      ..[levelId] = result;
    await preferences.setString(_storageKey, _encode(PlayerProgress(updated)));
    return result;
  }

  PlayerProgress _decode(String? value) {
    if (value == null) return const PlayerProgress.empty();
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return const PlayerProgress.empty();
      }
      final rawLevels = decoded['completedLevels'];
      if (rawLevels is! Map<String, dynamic>) {
        return const PlayerProgress.empty();
      }
      final levels = <String, LevelBestResult>{};
      for (final entry in rawLevels.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final moves = value['bestMoves'];
        final seconds = value['bestTimeSeconds'];
        if (moves is int && moves > 0 && seconds is int && seconds >= 0) {
          levels[entry.key] = LevelBestResult(
            bestMoves: moves,
            bestTimeSeconds: seconds,
          );
        }
      }
      return PlayerProgress(levels);
    } on FormatException {
      return const PlayerProgress.empty();
    }
  }

  String _encode(PlayerProgress progress) => jsonEncode({
    'completedLevels': {
      for (final entry in progress.completedLevels.entries)
        entry.key: {
          'bestMoves': entry.value.bestMoves,
          'bestTimeSeconds': entry.value.bestTimeSeconds,
        },
    },
  });
}
