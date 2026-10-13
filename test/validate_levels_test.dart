import 'package:gerehrah/localization/persian.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerehrah/game/level_quality_validator.dart';
import 'package:gerehrah/game/level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('validate all JSON levels', () async {
    final levels = await LevelRepository().loadLevels();
    const validator = LevelQualityValidator();
    final reportsBySeason = <int, List<LevelQualityReport>>{};

    expect(levels, hasLength(100));
    expect(levels.map((level) => level.id).toSet(), hasLength(100));

    for (var index = 0; index < levels.length; index++) {
      final level = levels[index];
      final report = validator.validate(level, maximumSolutionCount: 2);
      reportsBySeason
          .putIfAbsent(index ~/ 20 + 1, () => <LevelQualityReport>[])
          .add(report);
      // This output is the development command's readable per-level summary.
      // ignore: avoid_print
      print(
        '${level.id} | ${level.title} | ${level.rows}x${level.columns} | '
        '${level.endpointPairs.length} colors | ${_difficultyFor(index)} | '
        '${report.solveResult.isUnique ? 'unique' : 'multiple'} | '
        '${report.solveResult.nodesVisited} nodes | '
        '${report.storedSolutionsValid.where((valid) => valid).length}/'
        '${report.storedSolutionsValid.length} stored valid',
      );
      for (final issue in report.issues) {
        // ignore: avoid_print
        print('  ${issue.severity.name}: ${issue.code.name}: ${issue.message}');
      }
      expect(
        report.hasErrors,
        isFalse,
        reason: report.issues.map((issue) => issue.message).join('\n'),
      );
      expect(report.solveResult.isSolvable, isTrue);
      expect(report.storedSolutionsValid, everyElement(isTrue));
    }
    const uniqueTargets = {2: 5, 3: 5, 4: 6, 5: 8};
    for (final season in uniqueTargets.keys) {
      final reports = reportsBySeason[season]!;
      final uniqueCount = reports
          .where((report) => report.solveResult.isUnique)
          .length;
      final slowest = reports.reduce(
        (a, b) =>
            a.solveResult.nodesVisited > b.solveResult.nodesVisited ? a : b,
      );
      final average =
          reports.fold<int>(
            0,
            (sum, report) => sum + report.solveResult.nodesVisited,
          ) /
          reports.length;
      // ignore: avoid_print
      print(
        'فصل ${persianDigits(season)} summary | $uniqueCount unique | '
        '${reports.length - uniqueCount} multiple | slowest '
        '${slowest.level.id} ${slowest.solveResult.nodesVisited} nodes | '
        'average ${average.toStringAsFixed(1)} nodes',
      );
      expect(reports, hasLength(20));
      expect(uniqueCount, greaterThanOrEqualTo(uniqueTargets[season]!));
      expect(
        reports.map((report) => report.solveResult.nodesVisited),
        everyElement(lessThan(10000)),
      );
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}

String _difficultyFor(int index) {
  if (index >= 80) return 'grandmaster';
  if (index >= 60) return 'master';
  if (index >= 40) return 'expert';
  if (index >= 35) return 'master';
  if (index >= 30) return 'expert';
  if (index >= 25) return 'advanced+';
  if (index >= 20) return 'advanced';
  if (index < 5) return 'easy';
  if (index < 10) return 'medium';
  if (index < 15) return 'hard';
  return 'challenge';
}
