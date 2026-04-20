import 'dart:io';

abstract class ProgressReporter {
  void update(int passed, int failed, int skipped);
  void done();
}

class ConsoleProgressReporter implements ProgressReporter {
  ConsoleProgressReporter({StringSink? sink}) : _sink = sink ?? stdout;

  final StringSink _sink;

  @override
  void update(int passed, int failed, int skipped) {
    _sink.write(
      '\r  Running... passed: $passed  failed: $failed  skipped: $skipped   ',
    );
  }

  @override
  void done() {
    _sink.writeln();
  }
}
