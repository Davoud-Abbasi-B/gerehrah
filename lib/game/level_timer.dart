abstract interface class ElapsedTimeSource {
  Duration get now;
}

class StopwatchTimeSource implements ElapsedTimeSource {
  StopwatchTimeSource() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get now => _stopwatch.elapsed;
}

class LevelTimer {
  LevelTimer({ElapsedTimeSource? source})
    : _source = source ?? StopwatchTimeSource();

  final ElapsedTimeSource _source;
  Duration _accumulated = Duration.zero;
  Duration? _startedAt;
  bool _hasStarted = false;

  bool get hasStarted => _hasStarted;
  bool get isRunning => _startedAt != null;

  Duration get elapsed {
    final startedAt = _startedAt;
    return startedAt == null
        ? _accumulated
        : _accumulated + (_source.now - startedAt);
  }

  String get formatted {
    final totalSeconds = elapsed.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void start() {
    if (isRunning) return;
    _hasStarted = true;
    _startedAt = _source.now;
  }

  void pause() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _accumulated += _source.now - startedAt;
    _startedAt = null;
  }

  void reset() {
    _accumulated = Duration.zero;
    _startedAt = null;
    _hasStarted = false;
  }
}
