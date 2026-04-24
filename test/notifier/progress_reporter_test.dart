import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:taskflare/src/utils/enums.dart';
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

  group('Method onTestDone()', () {
    test('does not write to the sink when the test passed', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my test', result: TestResultKind.passed, totalPassed: 1, totalFailed: 0, totalSkipped: 0);

      expect(sink.toString(), isEmpty);
    });

    test('counts appear on next onTestStart render after a passed test', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my test', result: TestResultKind.passed, totalPassed: 7, totalFailed: 3, totalSkipped: 1);
      reporter.onTestStart('next test', const Duration(seconds: 2));

      expect(sink.toString(), contains('passed: 7'));
      expect(sink.toString(), contains('failed: 3'));
      expect(sink.toString(), contains('skipped: 1'));
    });

    test('prints a permanent FAIL line when the test failed', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my failing test', result: TestResultKind.failed, totalPassed: 0, totalFailed: 1, totalSkipped: 0);

      expect(sink.toString(), contains('FAIL'));
      expect(sink.toString(), contains('my failing test'));
      expect(sink.toString(), contains('\n'));
    });

    test('prints a permanent THROW line when the test errored', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my error test', result: TestResultKind.errored, totalPassed: 0, totalFailed: 1, totalSkipped: 0);

      expect(sink.toString(), contains('THROW'));
      expect(sink.toString(), contains('my error test'));
      expect(sink.toString(), contains('\n'));
    });

    test('prints a permanent SKIP line when the test was skipped', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my skipped test', result: TestResultKind.skipped, totalPassed: 0, totalFailed: 0, totalSkipped: 1);

      expect(sink.toString(), contains('SKIP'));
      expect(sink.toString(), contains('my skipped test'));
      expect(sink.toString(), contains('\n'));
    });

    test('includes file reference when fileRef is provided', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(
        name: 'my failing test',
        fileRef: r'test\foo_test.dart:10',
        result: TestResultKind.failed,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
      );

      expect(sink.toString(), contains(r'test\foo_test.dart:10'));
    });

    test('omits file reference when fileRef is null', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(name: 'my failing test', result: TestResultKind.failed, totalPassed: 0, totalFailed: 1, totalSkipped: 0);

      expect(sink.toString(), isNot(contains('.dart')));
    });

    test('re-renders the progress line after a permanent FAIL line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);
      reporter.onTestStart('running test', const Duration(seconds: 1));
      sink.clear();

      reporter.onTestDone(name: 'other failing test', result: TestResultKind.failed, totalPassed: 0, totalFailed: 1, totalSkipped: 0);

      final output = sink.toString();
      expect(output, contains('FAIL'));
      expect(output, contains('other failing test\n'));
      expect(output, contains('running test'));
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
