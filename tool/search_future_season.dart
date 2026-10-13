import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/game/puzzle_solution_validator.dart';
import 'package:gerehrah/game/puzzle_solver.dart';

const _colors = PathColor.values;
const _uniqueTargets = {3: 5, 4: 6, 5: 8};
const _seeds = {3: 20260730, 4: 20260731, 5: 20260801};
const _poolSizes = {3: 1000, 4: 1000, 5: 2500};
const _maximumAttempts = {3: 1500, 4: 1500, 5: 3000};
const _titles = {
  3: [
    'Ordered Passage',
    'Close Quarters',
    'Hidden Turn',
    'Split Decision',
    'Woven Gates',
    'Tight Crossing',
    'Quiet Detour',
    'Threaded Hall',
    'False Opening',
    'Narrow Exchange',
    'Deep Current',
    'Turning Point',
    'Locked Corridor',
    'Braided Steps',
    'Expert Order',
    'Converging Trails',
    'Secret Channel',
    'Twisted Causeway',
    'Final Passage',
    'Expert Summit',
  ],
  4: [
    'Master Entry',
    'Guarded Bend',
    'Crossed Routes',
    'Fourfold Turn',
    'Tangled Court',
    'Sealed Channel',
    'Layered Crossing',
    'Hidden Circuit',
    'Crowded Bend',
    'Master Detour',
    'Bound Passage',
    'Interlocked Ways',
    'Narrow Circuit',
    'Braided Order',
    'Master Weave',
    'Deep Junction',
    'Closed Crossing',
    'Twisted Network',
    'Final Circuit',
    'Master Summit',
  ],
  5: [
    'Grand Entry',
    'Exacting Turn',
    'Veiled Crossing',
    'Tangled Divide',
    'Grand Passage',
    'Constrained Ways',
    'Hidden Sequence',
    'Interwoven Hall',
    'Deceptive Bend',
    'Grand Circuit',
    'Locked Network',
    'Layered Routes',
    'Narrow Alliance',
    'Braided Circuit',
    'Grandmaster Weave',
    'Deep Sequence',
    'Sealed Junction',
    'Twisted Summit',
    'Final Network',
    'Gerehrah Pinnacle',
  ],
};

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/search_future_season.dart <3|4|5>');
    exitCode = 64;
    return;
  }
  final season = int.tryParse(arguments.single);
  if (season == null || !_uniqueTargets.containsKey(season)) {
    stderr.writeln('Season must be 3, 4, or 5.');
    exitCode = 64;
    return;
  }

  final random = Random(_seeds[season]);
  final candidates = <_Candidate>[];
  final signatures = <String>{};
  final maximumAttempts = _maximumAttempts[season]!;
  final desiredPoolSize = _poolSizes[season]!;
  var attempts = 0;

  while (attempts < maximumAttempts && candidates.length < desiredPoolSize) {
    attempts++;
    final path = _hamiltonianPath(6, random);
    if (path == null) continue;
    final cuts = _randomCuts(path.length, random);
    if (cuts == null) continue;
    final segments = <List<GridCell>>[];
    var start = 0;
    for (final end in [...cuts, path.length]) {
      segments.add(path.sublist(start, end));
      start = end;
    }
    final signature = segments
        .map(
          (segment) =>
              '${segment.first.row},${segment.first.column}-'
              '${segment.last.row},${segment.last.column}',
        )
        .join(';');
    if (!signatures.add(signature)) continue;

    final level = _candidateLevel(season, segments);
    if (!const PuzzleSolutionValidator().isValid(
      level,
      level.primarySolution,
    )) {
      continue;
    }
    final result = const PuzzleSolver().solve(level, maximumSolutionCount: 2);
    if (!result.isSolvable || result.nodesVisited >= 10000) continue;
    candidates.add(
      _Candidate(
        level: level,
        unique: result.isUnique,
        nodesVisited: result.nodesVisited,
      ),
    );
  }

  final uniqueTarget = _uniqueTargets[season]!;
  final unique = candidates.where((candidate) => candidate.unique).toList()
    ..sort(_hardestFirst);
  final multiple = candidates.where((candidate) => !candidate.unique).toList()
    ..sort(_hardestFirst);
  if (unique.length < uniqueTarget || multiple.length < 20 - uniqueTarget) {
    stderr.writeln(
      'Season $season search exhausted: ${candidates.length} candidates, '
      '${unique.length} unique, ${multiple.length} multiple after '
      '$attempts/$maximumAttempts attempts.',
    );
    exitCode = 1;
    return;
  }

  final selected = <_Candidate>[
    ...unique.take(uniqueTarget),
    ...multiple.take(20 - uniqueTarget),
  ]..sort((a, b) => a.nodesVisited.compareTo(b.nodesVisited));
  final titles = _titles[season]!;
  final outputLevels = <Map<String, dynamic>>[];
  for (var index = 0; index < selected.length; index++) {
    final candidate = selected[index];
    final number = index + 1;
    final level = _rename(
      candidate.level,
      id: 'season-$season-${number.toString().padLeft(2, '0')}',
      title: titles[index],
    );
    outputLevels.add(_toJson(level));
    stdout.writeln(
      '${level.id} | ${level.title} | 6x6 | 4 colors | '
      '${candidate.unique ? 'unique' : 'multiple'} | '
      '${candidate.nodesVisited} nodes | stored valid',
    );
  }

  Directory('build').createSync(recursive: true);
  final output = File('build/season${season}_candidates.json');
  output.writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({'levels': outputLevels}),
  );
  final average =
      selected.fold<int>(0, (sum, candidate) => sum + candidate.nodesVisited) /
      selected.length;
  stdout.writeln(
    'Season $season accepted: $uniqueTarget unique, '
    '${20 - uniqueTarget} multiple; slowest '
    '${selected.last.nodesVisited} nodes; average '
    '${average.toStringAsFixed(1)} nodes; pool ${candidates.length}; '
    'attempts $attempts/$maximumAttempts.',
  );
}

int _hardestFirst(_Candidate a, _Candidate b) =>
    b.nodesVisited.compareTo(a.nodesVisited);

PuzzleLevel _candidateLevel(int season, List<List<GridCell>> segments) {
  return PuzzleLevel(
    id: 'season-$season-candidate',
    title: 'Season $season Candidate',
    rows: 6,
    columns: 6,
    endpointPairs: [
      for (var index = 0; index < 4; index++)
        EndpointPair(
          color: _colors[index],
          first: segments[index].first,
          second: segments[index].last,
        ),
    ],
    solutions: [
      PuzzleSolution(
        paths: [
          for (var index = 0; index < 4; index++)
            SolutionPath(color: _colors[index], cells: segments[index]),
        ],
      ),
    ],
  );
}

PuzzleLevel _rename(
  PuzzleLevel level, {
  required String id,
  required String title,
}) {
  return PuzzleLevel(
    id: id,
    title: title,
    rows: level.rows,
    columns: level.columns,
    endpointPairs: level.endpointPairs,
    solutions: level.solutions,
  );
}

List<int>? _randomCuts(int length, Random random) {
  for (var attempt = 0; attempt < 100; attempt++) {
    final cuts = <int>{};
    while (cuts.length < 3) {
      cuts.add(4 + random.nextInt(length - 8));
    }
    final sorted = cuts.toList()..sort();
    if (sorted.first >= 4 &&
        sorted[1] - sorted[0] >= 4 &&
        sorted[2] - sorted[1] >= 4 &&
        length - sorted.last >= 4) {
      return sorted;
    }
  }
  return null;
}

List<GridCell>? _hamiltonianPath(int size, Random random) {
  final start = GridCell(random.nextInt(size), random.nextInt(size));
  final path = <GridCell>[start];
  final used = <GridCell>{start};
  var visitedStates = 0;
  const maximumVisitedStates = 100000;

  bool visit() {
    if (++visitedStates > maximumVisitedStates) return false;
    if (path.length == size * size) return true;
    final current = path.last;
    final next =
        <GridCell>[
          GridCell(current.row - 1, current.column),
          GridCell(current.row + 1, current.column),
          GridCell(current.row, current.column - 1),
          GridCell(current.row, current.column + 1),
        ].where((cell) {
          return cell.row >= 0 &&
              cell.row < size &&
              cell.column >= 0 &&
              cell.column < size &&
              !used.contains(cell);
        }).toList();
    next.shuffle(random);
    next.sort(
      (a, b) => _degree(a, size, used).compareTo(_degree(b, size, used)),
    );
    for (final cell in next) {
      used.add(cell);
      path.add(cell);
      if (visit()) return true;
      path.removeLast();
      used.remove(cell);
    }
    return false;
  }

  return visit() ? path : null;
}

int _degree(GridCell cell, int size, Set<GridCell> used) {
  return [
    GridCell(cell.row - 1, cell.column),
    GridCell(cell.row + 1, cell.column),
    GridCell(cell.row, cell.column - 1),
    GridCell(cell.row, cell.column + 1),
  ].where((neighbor) {
    return neighbor.row >= 0 &&
        neighbor.row < size &&
        neighbor.column >= 0 &&
        neighbor.column < size &&
        !used.contains(neighbor);
  }).length;
}

Map<String, dynamic> _toJson(PuzzleLevel level) => {
  'id': level.id,
  'title': level.title,
  'rows': level.rows,
  'columns': level.columns,
  'pairs': [
    for (final pair in level.endpointPairs)
      {
        'color': pair.color.name,
        'start': _cellJson(pair.first),
        'end': _cellJson(pair.second),
      },
  ],
  'solutions': [
    for (final solution in level.solutions)
      {
        'paths': [
          for (final path in solution.paths)
            {
              'color': path.color.name,
              'cells': path.cells.map(_cellJson).toList(),
            },
        ],
      },
  ],
};

Map<String, int> _cellJson(GridCell cell) => {
  'row': cell.row,
  'column': cell.column,
};

class _Candidate {
  const _Candidate({
    required this.level,
    required this.unique,
    required this.nodesVisited,
  });

  final PuzzleLevel level;
  final bool unique;
  final int nodesVisited;
}
