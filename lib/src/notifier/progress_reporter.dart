import 'dart:io';

abstract class ProgressReporter {
  void onTestStart(String name, Duration elapsed);
  void update(int passed, int failed, int skipped);
  void done();
}

class ConsoleProgressReporter implements ProgressReporter {
  ConsoleProgressReporter({StringSink? sink}) : _sink = sink ?? stdout;

  final StringSink _sink;
  int _lastLength = 0;

  @override
  void onTestStart(String name, Duration elapsed) {
    final seconds = (elapsed.inMilliseconds / 1000).toStringAsFixed(1);
    final line = '  ($seconds s)  ▶ $name';
    _sink.write('\r${line.padRight(_lastLength)}');
    _lastLength = line.length;
  }

  @override
  void update(int passed, int failed, int skipped) {}

  @override
  void done() {
    _sink.writeln();
    _lastLength = 0;
  }
}
