import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:test/test.dart';

void main() {
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

    test('Method update() starts the line with a carriage return', () {
      final sink = StringBuffer();
      final reporter = ConsoleProgressReporter(sink: sink);

      reporter.update(1, 0, 0);

      expect(sink.toString(), startsWith('\r'));
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
