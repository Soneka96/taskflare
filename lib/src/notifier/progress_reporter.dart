import 'dart:io';

import '../utils/enums.dart';

/// Contract for components that display live test progress during a run.
abstract class ProgressReporter {
  /// Called when a test begins.
  ///
  /// [name] is the display name and [elapsed] is the time since the run started.
  void onTestStart(String name, Duration elapsed);

  /// Called when a test finishes.
  ///
  /// [name] is the display name, [fileRef] is the `file:line` reference (if
  /// available), [result] is the [TestResultKind], and the totals reflect
  /// all tests completed so far.
  void onTestDone({
    required String name,
    String? fileRef,
    required TestResultKind result,
    required int totalPassed,
    required int totalFailed,
    required int totalSkipped,
  });

  /// Called once after all tests finish. Used to clear the live status line.
  void done();
}

/// A [ProgressReporter] that renders a live status line in the terminal and
/// prints a permanent line for each failed or errored test.
class ConsoleProgressReporter implements ProgressReporter {
  /// Creates a [ConsoleProgressReporter].
  ///
  /// [sink] defaults to [stdout] when omitted.
  /// [showFailed], [showErrored], and [showSkipped] control which permanent
  /// result lines are printed. These flags affect only terminal output —
  /// the report file and final notification always include everything.
  ConsoleProgressReporter({
    this.showFailed = true,
    this.showErrored = true,
    this.showSkipped = true,
    StringSink? sink,
  }) : _sink = sink ?? stdout;

  /// Whether to print a permanent FAIL line when a test fails.
  final bool showFailed;

  /// Whether to print a permanent THROW line when a test errors.
  final bool showErrored;

  /// Whether to print a permanent SKIP line when a test is skipped.
  final bool showSkipped;

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
  void onTestDone({
    required String name,
    String? fileRef,
    required TestResultKind result,
    required int totalPassed,
    required int totalFailed,
    required int totalSkipped,
  }) {
    _passed = totalPassed;
    _failed = totalFailed;
    _skipped = totalSkipped;

    final label = switch (result) {
      TestResultKind.none || TestResultKind.passed => null,
      TestResultKind.failed => 'FAIL ',
      TestResultKind.errored => 'THROW',
      TestResultKind.skipped => 'SKIP ',
    };

    if (label == null) {
      return;
    }

    final visible = switch (result) {
      TestResultKind.failed => showFailed,
      TestResultKind.errored => showErrored,
      TestResultKind.skipped => showSkipped,
      _ => false,
    };

    if (!visible) {
      return;
    }

    final filePart = fileRef != null ? '  $fileRef' : '';
    _sink.write('\r\x1b[K  $label ▶ $name$filePart\n');
    if (_currentName.isNotEmpty) {
      _render();
    }
  }

  @override
  void done() {
    _sink.write('\r\x1b[K');
  }

  void _render() {
    final seconds = (_lastElapsed.inMilliseconds / 1000).toStringAsFixed(1);
    var line =
        '  (${seconds}s)  passed: $_passed  failed: $_failed  skipped: $_skipped  ▶ $_currentName';
    final width = _width;
    if (line.length > width) {
      line = line.substring(0, width);
    }
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
