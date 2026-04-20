import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('Method onTestStart() renders the full progress line', () {
    test('Method onTestStart() includes the test name', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('my test name', Duration.zero);

      expect(sink.toString(), contains('my test name'));
    });

    test('Method onTestStart() includes elapsed time in seconds', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test', const Duration(milliseconds: 1500));

      expect(sink.toString(), contains('1.5'));
    });

    test('Method onTestStart() prefixes output with carriage return', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test', Duration.zero);

      expect(sink.toString(), startsWith('\r'));
    });
  });

  group('Method update() stores counts for the next onTestStart render', () {
    test('Method update() does not write to the sink immediately', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(7, 3, 1);

      expect(sink.toString(), isEmpty);
    });

    test('Method update() counts appear on next onTestStart render', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(7, 3, 1);
      reporter.onTestStart('next test', const Duration(seconds: 2));

      expect(sink.toString(), contains('passed: 7'));
      expect(sink.toString(), contains('failed: 3'));
      expect(sink.toString(), contains('skipped: 1'));
    });
  });

  group('Method done() erases the progress line', () {
    test('Method done() writes a carriage return to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.done();

      expect(sink.toString(), contains('\r'));
    });

    test('Method done() writes the ANSI erase-line sequence', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.done();

      expect(sink.toString(), contains('\x1b[K'));
    });
  });
}
