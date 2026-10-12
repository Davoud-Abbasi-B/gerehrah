import 'grid_cell.dart';

enum PathColor { blue, red, green, yellow }

PathColor pathColorFromJson(Object? value) {
  if (value is! String) {
    throw const FormatException('Path colors must be strings.');
  }
  for (final color in PathColor.values) {
    if (color.name == value) return color;
  }
  throw FormatException('Unsupported path color "$value".');
}

class EndpointPair {
  const EndpointPair({
    required this.color,
    required this.first,
    required this.second,
  });

  final PathColor color;
  final GridCell first;
  final GridCell second;

  factory EndpointPair.fromJson(Map<String, dynamic> json) {
    return EndpointPair(
      color: pathColorFromJson(json['color']),
      first: GridCell.fromJson(_jsonMap(json['start'], 'pair start')),
      second: GridCell.fromJson(_jsonMap(json['end'], 'pair end')),
    );
  }

  List<GridCell> get positions => [first, second];
}

class SolutionPath {
  const SolutionPath({required this.color, required this.cells});

  final PathColor color;
  final List<GridCell> cells;

  factory SolutionPath.fromJson(Map<String, dynamic> json) {
    return SolutionPath(
      color: pathColorFromJson(json['color']),
      cells: _jsonList(json['cells'], 'solution path cells')
          .map((cell) => GridCell.fromJson(_jsonMap(cell, 'solution cell')))
          .toList(growable: false),
    );
  }
}

class PuzzleSolution {
  const PuzzleSolution({required this.paths});

  final List<SolutionPath> paths;

  factory PuzzleSolution.fromJson(Map<String, dynamic> json) {
    return PuzzleSolution(
      paths: _jsonList(json['paths'], 'solution paths')
          .map((path) => SolutionPath.fromJson(_jsonMap(path, 'solution path')))
          .toList(growable: false),
    );
  }

  List<GridCell> pathFor(PathColor color) =>
      paths.firstWhere((path) => path.color == color).cells;
}

class PuzzleLevel {
  const PuzzleLevel({
    required this.id,
    required this.title,
    required this.rows,
    required this.columns,
    required this.endpointPairs,
    required this.solutions,
  }) : assert(rows > 0),
       assert(columns > 0);

  final String id;
  final String title;
  final int rows;
  final int columns;
  final List<EndpointPair> endpointPairs;
  final List<PuzzleSolution> solutions;

  factory PuzzleLevel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final rows = json['rows'];
    final columns = json['columns'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Level "id" must be a non-empty string.');
    }
    if (title is! String || title.isEmpty) {
      throw const FormatException('Level "title" must be a non-empty string.');
    }
    if (rows is! int || columns is! int) {
      throw FormatException(
        'Level "$id" requires integer "rows" and "columns".',
      );
    }
    if (rows <= 0 || columns <= 0) {
      throw FormatException(
        'Level "$id" has invalid board dimensions ${rows}x$columns.',
      );
    }
    return PuzzleLevel(
      id: id,
      title: title,
      rows: rows,
      columns: columns,
      endpointPairs: _jsonList(json['pairs'], 'level pairs')
          .map((pair) => EndpointPair.fromJson(_jsonMap(pair, 'level pair')))
          .toList(growable: false),
      solutions: _jsonList(json['solutions'], 'level solutions')
          .map(
            (solution) =>
                PuzzleSolution.fromJson(_jsonMap(solution, 'level solution')),
          )
          .toList(growable: false),
    );
  }

  EndpointPair pairFor(PathColor color) =>
      endpointPairs.firstWhere((pair) => pair.color == color);

  PuzzleSolution get primarySolution => solutions.first;

  List<GridCell> solutionFor(PathColor color) => primarySolution.pathFor(color);
}

Map<String, dynamic> _jsonMap(Object? value, String description) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected $description to be a JSON object.');
}

List<dynamic> _jsonList(Object? value, String description) {
  if (value is List<dynamic>) return value;
  throw FormatException('Expected $description to be a JSON array.');
}
