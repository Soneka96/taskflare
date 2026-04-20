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

  group('Method update() re-renders the progress line with new counts', () {
    test('Method update() includes the passed count', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(7, 0, 0);

      expect(sink.toString(), contains('passed: 7'));
    });

    test('Method update() includes the failed count', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(0, 3, 0);

      expect(sink.toString(), contains('failed: 3'));
    });

    test('Method update() includes the skipped count', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(0, 0, 2);

      expect(sink.toString(), contains('skipped: 2'));
    });

    test('Method update() retains the current test name', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('running test', const Duration(seconds: 1));
      reporter.update(1, 0, 0);

      expect(sink.toString(), contains('running test'));
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
