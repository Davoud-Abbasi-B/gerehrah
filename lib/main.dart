import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'game/level_repository.dart';
import 'game/puzzle_level.dart';
import 'home/level_select_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const PathlyApp());
}

class PathlyApp extends StatelessWidget {
  const PathlyApp({super.key, this.levelRepository});

  final LevelRepository? levelRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pathly',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08111F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF76A9FF),
          secondary: Color(0xFF5ED6C0),
          surface: Color(0xFF111D2E),
          onSurface: Color(0xFFF1F5FB),
          outline: Color(0xFF33445C),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: const Color(0xFFE8EEF7),
          displayColor: const Color(0xFFF7FAFF),
        ),
      ),
      home: _LevelBootstrap(
        levelRepository: levelRepository ?? LevelRepository(),
      ),
    );
  }
}

class _LevelBootstrap extends StatefulWidget {
  const _LevelBootstrap({required this.levelRepository});

  final LevelRepository levelRepository;

  @override
  State<_LevelBootstrap> createState() => _LevelBootstrapState();
}

class _LevelBootstrapState extends State<_LevelBootstrap> {
  late final Future<List<PuzzleLevel>> _levels;

  @override
  void initState() {
    super.initState();
    _levels = widget.levelRepository.loadLevels();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PuzzleLevel>>(
      future: _levels,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load levels.\n${snapshot.error}',
                    key: const Key('level-load-error'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        final levels = snapshot.data;
        if (levels == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(key: Key('level-loading')),
            ),
          );
        }
        return LevelSelectScreen(levels: levels);
      },
    );
  }
}
