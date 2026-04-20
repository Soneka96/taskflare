import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/console_notifier.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  late List<String> output;
  late ConsoleNotifier notifier;

  setUp(() {
    output = [];
    notifier = ConsoleNotifier(printer: output.add);
  });

  group('Method notify() outputs the correct label', () {
    test('Method notify() prints SUCCESS label when outcome is success', () {
      notifier.notify(_summary(TestOutcome.success));
      expect(output.first, contains('[SUCCESS]'));
    });

    test('Method notify() prints FAILURE label when outcome is failure', () {
      notifier.notify(_summary(TestOutcome.failure));
      expect(output.first, contains('[FAILURE]'));
    });

    test('Method notify() prints CRASH label when outcome is crash', () {
      notifier.notify(_summary(TestOutcome.crash));
      expect(output.first, contains('[CRASH]'));
    });
  });

  group('Method notify() outputs the correct counts', () {
    test('Method notify() prints passed count', () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.success,
          passed: 42,
          failed: 0,
          skipped: 0,
        ),
      );
      expect(output.first, contains('passed: 42'));
    });

    test('Method notify() prints failed count', () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.failure,
          passed: 0,
          failed: 3,
          skipped: 0,
        ),
      );
      expect(output.first, contains('failed: 3'));
    });

    test('Method notify() prints skipped count', () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.success,
          passed: 5,
          failed: 0,
          skipped: 2,
        ),
      );
      expect(output.first, contains('skipped: 2'));
    });
  });

  group('Method notify() outputs the correct failed test names', () {
    test('Method notify() prints each failed test name on its own line', () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.failure,
          passed: 1,
          failed: 2,
          skipped: 0,
          failedTestNames: ['test A', 'test B'],
        ),
      );
      expect(output, contains('  FAILED: test A'));
      expect(output, contains('  FAILED: test B'));
    });

    test('Method notify() prints no failed names when all tests pass', () {
      notifier.notify(_summary(TestOutcome.success));
      expect(output.any((l) => l.contains('FAILED:')), isFalse);
    });

    test(
        'Method notify() prints an empty separator line before failed names',
        () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.failure,
          passed: 0,
          failed: 1,
          skipped: 0,
          failedTestNames: ['test A'],
        ),
      );
      expect(output[1], equals(''));
    });
  });

  group('Method notify() behaves correctly', () {
    test('Method notify() emits exactly one line when no tests fail', () {
      notifier.notify(_summary(TestOutcome.success));
      expect(output, hasLength(1));
    });

    test(
        'Method notify() emits summary line plus blank plus one line per failed test',
        () {
      notifier.notify(
        const RunSummary(
          outcome: TestOutcome.failure,
          passed: 0,
          failed: 3,
          skipped: 0,
          failedTestNames: ['a', 'b', 'c'],
        ),
      );
      // summary + blank + 3 failed names
      expect(output, hasLength(5));
    });
  });
}

RunSummary _summary(TestOutcome outcome) => RunSummary(
      outcome: outcome,
      passed: 0,
      failed: 0,
      skipped: 0,
    );
