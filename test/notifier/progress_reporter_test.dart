import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('Method onTestStart() overwrites the current line with the test name',
      () {
    test('Method onTestStart() writes the test name to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('my test name');

      expect(sink.toString(), contains('my test name'));
    });

    test('Method onTestStart() prefixes output with a carriage return', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test');

      expect(sink.toString(), startsWith('\r'));
    });

    test('Method onTestStart() pads output to clear previous longer line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('a very long test name that takes lots of space');
      reporter.onTestStart('short');

      final output = sink.toString();
      final secondWrite = output.substring(output.indexOf('\r', 1));
      expect(secondWrite.length, greaterThan('  ▶ short'.length));
    });
  });

  group('Method done() terminates the progress line', () {
    test('Method done() writes a newline to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.done();

      expect(sink.toString(), contains('\n'));
    });
  });
}
