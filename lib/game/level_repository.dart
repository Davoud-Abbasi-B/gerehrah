import 'dart:convert';

import 'package:flutter/services.dart';

import 'grid_cell.dart';
import 'puzzle_level.dart';

class LevelRepository {
  LevelRepository({
    AssetBundle? assetBundle,
    this.assetPath = 'assets/levels/levels.json',
  }) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  final String assetPath;

  Future<List<PuzzleLevel>> loadLevels() async {
    final source = await _assetBundle.loadString(assetPath);
    return parseLevels(source);
  }

  List<PuzzleLevel> parseLevels(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid levels JSON: ${error.message}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid levels JSON: the root must be an object.',
      );
    }
    final rawLevels = decoded['levels'];
    if (rawLevels is! List<dynamic>) {
      throw const FormatException(
        'Invalid levels JSON: "levels" must be an array.',
      );
    }

    final levels = <PuzzleLevel>[];
    final ids = <String>{};
    for (var index = 0; index < rawLevels.length; index++) {
      final rawLevel = rawLevels[index];
      if (rawLevel is! Map<String, dynamic>) {
        throw FormatException('Level at index $index must be an object.');
      }
      final PuzzleLevel level;
      try {
        level = PuzzleLevel.fromJson(rawLevel);
      } on FormatException catch (error) {
        throw FormatException('Level at index $index: ${error.message}');
      }
      if (!ids.add(level.id)) {
        throw FormatException('Duplicate level ID "${level.id}".');
      }
      _validateLevel(level);
      levels.add(level);
    }
    return List<PuzzleLevel>.unmodifiable(levels);
  }

  void _validateLevel(PuzzleLevel level) {
    if (level.rows <= 0 || level.columns <= 0) {
      throw FormatException(
        'Level "${level.id}" has invalid board dimensions '
        '${level.rows}x${level.columns}.',
      );
    }
    if (level.endpointPairs.isEmpty) {
      throw FormatException('Level "${level.id}" must contain a pair.');
    }
    for (final pair in level.endpointPairs) {
      _validateCell(level, pair.first, 'pair start');
      _validateCell(level, pair.second, 'pair end');
      if (pair.first == pair.second) {
        throw FormatException(
          'Level "${level.id}" has a ${pair.color.name} pair with identical '
          'start and end cells.',
        );
      }
    }
    if (level.solutions.isEmpty) {
      throw FormatException('Level "${level.id}" must contain a solution.');
    }
    for (final solution in level.solutions) {
      if (solution.paths.isEmpty) {
        throw FormatException(
          'Level "${level.id}" contains a solution with no paths.',
        );
      }
      for (final path in solution.paths) {
        if (path.cells.isEmpty) {
          throw FormatException(
            'Level "${level.id}" contains an empty ${path.color.name} path.',
          );
        }
        for (final cell in path.cells) {
          _validateCell(level, cell, 'solution cell');
        }
      }
    }
  }

  void _validateCell(PuzzleLevel level, GridCell cell, String description) {
    if (cell.row < 0 ||
        cell.row >= level.rows ||
        cell.column < 0 ||
        cell.column >= level.columns) {
      throw FormatException(
        'Level "${level.id}" has an out-of-range $description '
        '(${cell.row}, ${cell.column}).',
      );
    }
  }
}
