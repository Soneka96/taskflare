import 'dart:io';

abstract class ProgressReporter {
  void onTestStart(String name, Duration elapsed);
  void update(int passed, int failed, int skipped);
  void done();
}

class ConsoleProgressReporter implements ProgressReporter {
  ConsoleProgressReporter({StringSink? sink}) : _sink = sink ?? stdout;

  final StringSink _sink;
  String _currentName = '';
  Duration _lastElapsed = Duration.zero;
  int _passed = 0;
  int _failed = 0;
  int _skipped = 0;

  @override
  void onTestStart(String name, Duration elapsed) {
    _currentName = name;
    _lastElapsed = elapsed;
    _render();
  }

  @override
  void update(int passed, int failed, int skipped) {
    _passed = passed;
    _failed = failed;
    _skipped = skipped;
    _render();
  }

  @override
  void done() {
    _sink.write('\r\x1b[K'); // erase the progress line; summary prints from here
  }

  void _render() {
    final seconds = (_lastElapsed.inMilliseconds / 1000).toStringAsFixed(1);
    var line =
        '  (${seconds}s)  passed: $_passed  failed: $_failed  skipped: $_skipped  ▶ $_currentName';
    final width = _width;
    if (line.length > width) line = line.substring(0, width);
    _sink.write('\r\x1b[K$line');
  }

  int get _width {
    if (_sink is Stdout) {
      try {
        return (_sink as Stdout).terminalColumns;
      } catch (_) {}
    }
    return 120;
  }
}
