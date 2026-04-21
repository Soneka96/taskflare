import 'dart:io';

import '../utils/enums.dart';

abstract class ProgressReporter {
  void onTestStart(String name, Duration elapsed);
  void onTestDone(
    String name,
    String? fileRef,
    TestResultKind result,
    int totalPassed,
    int totalFailed,
    int totalSkipped,
  );
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
    _currentName = _normalize(name);
    _lastElapsed = elapsed;
    _render();
  }

  @override
  void onTestDone(
    String name,
    String? fileRef,
    TestResultKind result,
    int totalPassed,
    int totalFailed,
    int totalSkipped,
  ) {
    _passed = totalPassed;
    _failed = totalFailed;
    _skipped = totalSkipped;

    final label = switch (result) {
      TestResultKind.none || TestResultKind.passed => null,
      TestResultKind.failed => 'FAIL ',
      TestResultKind.errored => 'THROW',
      TestResultKind.skipped => 'SKIP ',
    };

    if (label == null) return;

    final filePart = fileRef != null ? '  $fileRef' : '';
    _sink.write('\r\x1b[K  $label ▶ $name$filePart\n');
    if (_currentName.isNotEmpty) _render();
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

  String _normalize(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
