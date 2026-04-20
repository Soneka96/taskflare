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
      expect(output.single, contains('[SUCCESS]'));
    });

    test('Method notify() prints FAILURE label when outcome is failure', () {
      notifier.notify(_summary(TestOutcome.failure));
      expect(output.single, contains('[FAILURE]'));
    });

    test('Method notify() prints CRASH label when outcome is crash', () {
      notifier.notify(_summary(TestOutcome.crash));
      expect(output.single, contains('[CRASH]'));
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
      expect(output.single, contains('passed: 42'));
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
      expect(output.single, contains('failed: 3'));
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
      expect(output.single, contains('skipped: 2'));
    });
  });

  group('Method notify() behaves correctly', () {
    test('Method notify() emits exactly one line per call', () {
      notifier.notify(_summary(TestOutcome.success));
      expect(output, hasLength(1));
    });
  });
}

RunSummary _summary(TestOutcome outcome) => RunSummary(
      outcome: outcome,
      passed: 0,
      failed: 0,
      skipped: 0,
    );
