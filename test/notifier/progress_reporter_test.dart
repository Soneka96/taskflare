import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:test/test.dart';

void main() {
  group('Method onTestStart() writes the test name to the sink', () {
    test('Method onTestStart() writes the test name to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('my test name');

      expect(sink.toString(), contains('my test name'));
    });

    test('Method onTestStart() prefixes the name with a triangle marker', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.onTestStart('some test');

      expect(sink.toString(), contains('▶'));
    });
  });

  group('Method update() writes a progress line with the correct counts', () {
    test('Method update() writes passed count to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(3, 0, 0);

      expect(sink.toString(), contains('passed: 3'));
    });

    test('Method update() writes failed count to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(0, 2, 0);

      expect(sink.toString(), contains('failed: 2'));
    });

    test('Method update() writes skipped count to the sink', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(0, 0, 1);

      expect(sink.toString(), contains('skipped: 1'));
    });
  });
}
