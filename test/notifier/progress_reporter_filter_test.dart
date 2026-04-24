import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleProgressReporter filter flags', () {
    test('showFailed: false suppresses the FAIL permanent line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(
        showFailed: false,
        sink: sink,
      );

      reporter.onTestDone(
        name: 'my test',
        result: TestResultKind.failed,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
      );

      expect(sink.toString(), isNot(contains('FAIL')));
    });

    test('showErrored: false suppresses the THROW permanent line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(
        showErrored: false,
        sink: sink,
      );

      reporter.onTestDone(
        name: 'my test',
        result: TestResultKind.errored,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
      );

      expect(sink.toString(), isNot(contains('THROW')));
    });

    test('showSkipped: false suppresses the SKIP permanent line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(
        showSkipped: false,
        sink: sink,
      );

      reporter.onTestDone(
        name: 'my test',
        result: TestResultKind.skipped,
        totalPassed: 0,
        totalFailed: 0,
        totalSkipped: 1,
      );

      expect(sink.toString(), isNot(contains('SKIP')));
    });

    test('showFailed: true still prints the FAIL line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(
        name: 'my test',
        result: TestResultKind.failed,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
      );

      expect(sink.toString(), contains('FAIL'));
    });

    test('showSkipped: true still prints the SKIP line', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestDone(
        name: 'skipped test',
        result: TestResultKind.skipped,
        totalPassed: 0,
        totalFailed: 0,
        totalSkipped: 1,
      );

      expect(sink.toString(), contains('SKIP'));
    });
  });
}
