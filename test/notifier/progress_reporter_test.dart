import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('Method onTestStart() overwrites the current line with time and name',
      () {
    test('Method onTestStart() writes the test name to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('my test name', const Duration(seconds: 2));

      expect(sink.toString(), contains('my test name'));
    });

    test('Method onTestStart() writes the elapsed time to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test', const Duration(milliseconds: 1500));

      expect(sink.toString(), contains('1.5'));
    });

    test('Method onTestStart() prefixes output with a carriage return', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test', Duration.zero);

      expect(sink.toString(), startsWith('\r'));
    });

    test('Method onTestStart() pads output to clear previous longer line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart(
        'a very long test name that takes lots of space',
        Duration.zero,
      );
      reporter.onTestStart('short', Duration.zero);

      final output = sink.toString();
      final secondWrite = output.substring(output.indexOf('\r', 1));
      expect(secondWrite.length, greaterThan('  (0.0 s)  ▶ short'.length));
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
