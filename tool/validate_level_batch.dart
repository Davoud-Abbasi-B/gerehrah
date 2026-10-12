import 'dart:convert';
import 'dart:io';

import 'package:pathly/game/level_quality_validator.dart';
import 'package:pathly/game/puzzle_level.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/validate_level_batch.dart <json>');
    exitCode = 64;
    return;
  }
  final decoded =
      jsonDecode(File(arguments.single).readAsStringSync())
          as Map<String, dynamic>;
  final levels = (decoded['levels'] as List<dynamic>)
      .map((value) => PuzzleLevel.fromJson(value as Map<String, dynamic>))
      .toList(growable: false);
  const validator = LevelQualityValidator();
  var unique = 0;
  var maximumNodes = 0;
  var totalNodes = 0;
  var failed = false;
  String? slowestId;

  for (final level in levels) {
    final report = validator.validate(level, maximumSolutionCount: 2);
    final nodes = report.solveResult.nodesVisited;
    totalNodes += nodes;
    if (nodes > maximumNodes) {
      maximumNodes = nodes;
      slowestId = level.id;
    }
    if (report.solveResult.isUnique) unique++;
    final valid =
        !report.hasErrors &&
        report.solveResult.isSolvable &&
        report.storedSolutionsValid.every((value) => value);
    if (!valid) failed = true;
    stdout.writeln(
      '${level.id} | ${level.title} | ${level.rows}x${level.columns} | '
      '${level.endpointPairs.length} colors | '
      '${report.solveResult.isUnique ? 'unique' : 'multiple'} | '
      '$nodes nodes | ${valid ? 'stored valid' : 'INVALID'}',
    );
  }
  stdout.writeln(
    '${levels.length} levels | $unique unique | '
    '${levels.length - unique} multiple | slowest $slowestId '
    '$maximumNodes nodes | average '
    '${(totalNodes / levels.length).toStringAsFixed(1)} nodes',
  );
  if (levels.length != 20 || failed) exitCode = 1;
}
