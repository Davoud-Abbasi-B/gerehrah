import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gerehrah/game/grid_cell.dart';
import 'package:gerehrah/game/puzzle_level.dart';
import 'package:gerehrah/game/puzzle_solution_validator.dart';
import 'package:gerehrah/game/puzzle_solver.dart';

const _colors = PathColor.values;
const _titles = [
  'Tangled Trail',
  'Four Corners',
  'Hidden Passage',
  'Switching Yard',
  'Braided River',
  'Pinch Point',
  'Crossed Signals',
  'Narrow Escape',
  'Turning Tides',
  'Crowded Junction',
  'Long Detour',
  'Locked Steps',
  'Winding Order',
  'Threaded Maze',
  'Expert Crossing',
  'Master Circuit',
  'Tight Alliance',
  'Deep Weave',
  'Final Tangle',
  'Summit Route',
];

void main() {
  final random = Random(20260729);
  final accepted = <Map<String, dynamic>>[];
  final signatures = <String>{};
  var attempts = 0;

  while (accepted.length < 20 && attempts < 500) {
    attempts++;
    final size = accepted.length < 3 && attempts.isOdd ? 5 : 6;
    final path = _hamiltonianPath(size, random);
    if (path == null) continue;
    final cuts = _randomCuts(path.length, random);
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
    if (!signatures.add('$size:$signature')) continue;

    final number = accepted.length + 1;
    final level = PuzzleLevel(
      id: 'season-2-${number.toString().padLeft(2, '0')}',
      title: _titles[number - 1],
      rows: size,
      columns: size,
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
    if (!const PuzzleSolutionValidator().isValid(
      level,
      level.primarySolution,
    )) {
      continue;
    }
    final result = const PuzzleSolver().solve(level, maximumSolutionCount: 2);
    if (!result.isSolvable || result.nodesVisited >= 10000) continue;
    final uniqueCount = accepted
        .where((level) => level['unique'] == true)
        .length;
    if (uniqueCount < 5 && !result.isUnique) continue;

    accepted.add({..._toJson(level), 'unique': result.isUnique});
    stdout.writeln(
      '${level.id} | ${level.title} | ${size}x$size | '
      '${result.isUnique ? 'unique' : 'multiple'} | '
      '${result.nodesVisited} nodes',
    );
  }

  if (accepted.length != 20) {
    stderr.writeln(
      'Only found ${accepted.length} levels in $attempts attempts.',
    );
    exitCode = 1;
    return;
  }
  Directory('build').createSync(recursive: true);
  File('build/season2_candidates.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'levels': [for (final level in accepted) Map.of(level)..remove('unique')],
    }),
  );
}

List<int> _randomCuts(int length, Random random) {
  final cuts = <int>{};
  while (cuts.length < 3) {
    cuts.add(4 + random.nextInt(length - 8));
  }
  final sorted = cuts.toList()..sort();
  if (sorted.first < 4 ||
      sorted[1] - sorted[0] < 4 ||
      sorted[2] - sorted[1] < 4 ||
      length - sorted.last < 4) {
    return _randomCuts(length, random);
  }
  return sorted;
}

List<GridCell>? _hamiltonianPath(int size, Random random) {
  final start = GridCell(random.nextInt(size), random.nextInt(size));
  final path = <GridCell>[start];
  final used = <GridCell>{start};

  bool visit() {
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
