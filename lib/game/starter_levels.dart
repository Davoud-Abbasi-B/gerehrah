import 'level_repository.dart';
import 'puzzle_level.dart';

Future<List<PuzzleLevel>> loadStarterLevels({LevelRepository? repository}) {
  return (repository ?? LevelRepository()).loadLevels();
}
