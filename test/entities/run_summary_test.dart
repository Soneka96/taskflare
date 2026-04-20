import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  const base = RunSummary(
    outcome: TestOutcome.success,
    passed: 5,
    failed: 0,
    skipped: 1,
    failedTestNames: [],
  );

  group('RunSummary\'s copyWith() returns the correct value', () {
    test('Method copyWith() returns a new instance with outcome replaced', () {
      final result = base.copyWith(outcome: TestOutcome.failure);
      expect(result.outcome, equals(TestOutcome.failure));
    });

    test('Method copyWith() preserves outcome when not provided', () {
      final result = base.copyWith(passed: 10);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test('Method copyWith() returns a new instance with passed replaced', () {
      final result = base.copyWith(passed: 99);
      expect(result.passed, equals(99));
    });

    test('Method copyWith() preserves passed when not provided', () {
      final result = base.copyWith(outcome: TestOutcome.crash);
      expect(result.passed, equals(5));
    });

    test('Method copyWith() returns a new instance with failed replaced', () {
      final result = base.copyWith(failed: 3);
      expect(result.failed, equals(3));
    });

    test('Method copyWith() preserves failed when not provided', () {
      final result = base.copyWith(passed: 2);
      expect(result.failed, equals(0));
    });

    test('Method copyWith() returns a new instance with skipped replaced', () {
      final result = base.copyWith(skipped: 7);
      expect(result.skipped, equals(7));
    });

    test('Method copyWith() preserves skipped when not provided', () {
      final result = base.copyWith(passed: 2);
      expect(result.skipped, equals(1));
    });

    test('Method copyWith() returns a new instance with failedTestNames replaced',
        () {
      final result = base.copyWith(failedTestNames: ['test A', 'test B']);
      expect(result.failedTestNames, equals(['test A', 'test B']));
    });

    test('Method copyWith() preserves failedTestNames when not provided', () {
      const withNames = RunSummary(
        outcome: TestOutcome.failure,
        passed: 1,
        failed: 1,
        skipped: 0,
        failedTestNames: ['test A'],
      );
      final result = withNames.copyWith(passed: 2);
      expect(result.failedTestNames, equals(['test A']));
    });

    test('Method copyWith() returns a new instance with crashOutput replaced',
        () {
      final result = base.copyWith(crashOutput: 'compilation failed');
      expect(result.crashOutput, equals('compilation failed'));
    });

    test('Method copyWith() preserves crashOutput when not provided', () {
      const withCrash = RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
        crashOutput: 'error text',
      );
      final result = withCrash.copyWith(passed: 1);
      expect(result.crashOutput, equals('error text'));
    });

    test('Method copyWith() returns a new instance with duration replaced', () {
      final result = base.copyWith(duration: const Duration(seconds: 5));
      expect(result.duration, equals(const Duration(seconds: 5)));
    });

    test('Method copyWith() preserves duration when not provided', () {
      const withDuration = RunSummary(
        outcome: TestOutcome.success,
        passed: 1,
        failed: 0,
        skipped: 0,
        duration: Duration(seconds: 3),
      );
      final result = withDuration.copyWith(passed: 2);
      expect(result.duration, equals(const Duration(seconds: 3)));
    });
  });

  group('RunSummary\'s equality behaves correctly', () {
    test('Two instances with same field values are equal', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
        failedTestNames: [],
      );
      expect(base, equals(other));
    });

    test('Two instances with different outcome are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.failure,
        passed: 5,
        failed: 0,
        skipped: 1,
      );
      expect(base, isNot(equals(other)));
    });

    test('Two instances with different counts are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 4,
        failed: 1,
        skipped: 1,
      );
      expect(base, isNot(equals(other)));
    });

    test('Two instances with different failedTestNames are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
        failedTestNames: ['test A'],
      );
      expect(base, isNot(equals(other)));
    });

    test('Two instances with different duration are not equal', () {
      const withDuration = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
        duration: Duration(seconds: 2),
      );
      expect(base, isNot(equals(withDuration)));
    });

    test('Two instances with different crashOutput are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
        crashOutput: 'error',
      );
      const withoutCrash = RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
      );
      expect(other, isNot(equals(withoutCrash)));
    });
  });

  group('RunSummary\'s hashCode behaves correctly', () {
    test('Equal instances have the same hashCode', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
        failedTestNames: [],
      );
      expect(base.hashCode, equals(other.hashCode));
    });
  });

  group('RunSummary\'s toString() returns the correct value', () {
    test('Method toString() contains all field values', () {
      const withNames = RunSummary(
        outcome: TestOutcome.failure,
        passed: 1,
        failed: 1,
        skipped: 0,
        failedTestNames: ['test A'],
      );
      final str = withNames.toString();
      expect(str, contains('failure'));
      expect(str, contains('1'));
      expect(str, contains('test A'));
    });
  });
}
