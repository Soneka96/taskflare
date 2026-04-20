import 'dart:io';

abstract class ProgressReporter {
  void onTestStart(String name);
  void update(int passed, int failed, int skipped);
  void done();
}

class ConsoleProgressReporter implements ProgressReporter {
  ConsoleProgressReporter({StringSink? sink}) : _sink = sink ?? stdout;

  final StringSink _sink;

  @override
  void onTestStart(String name) => _sink.writeln('  ▶ $name');

  @override
  void update(int passed, int failed, int skipped) {
    _sink.writeln(
      '  passed: $passed  failed: $failed  skipped: $skipped',
    );
  }

  @override
  void done() {}
}
