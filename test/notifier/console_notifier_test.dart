import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/console_notifier.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleNotifier', () {
    late List<String> output;
    late ConsoleNotifier notifier;

    setUp(() {
      output = [];
      notifier = ConsoleNotifier(printer: output.add);
    });

    test('prints SUCCESS label when outcome is success', () {
      notifier.notify(_summary(TestOutcome.success));
      expect(output.single, contains('[SUCCESS]'));
    });

    test('prints FAILURE label when outcome is failure', () {
      notifier.notify(_summary(TestOutcome.failure));
      expect(output.single, contains('[FAILURE]'));
    });

    test('prints CRASH label when outcome is crash', () {
      notifier.notify(_summary(TestOutcome.crash));
      expect(output.single, contains('[CRASH]'));
    });

    test('prints passed count', () {
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

    test('prints failed count', () {
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

    test('prints skipped count', () {
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

    test('emits exactly one line per notify call', () {
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
