import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('RunSummary', () {
    const base = RunSummary(
      outcome: TestOutcome.success,
      passed: 5,
      failed: 0,
      skipped: 1,
    );

    test('copyWith replaces outcome when provided', () {
      final result = base.copyWith(outcome: TestOutcome.failure);
      expect(result.outcome, equals(TestOutcome.failure));
    });

    test('copyWith preserves outcome when not provided', () {
      final result = base.copyWith(passed: 10);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test('copyWith replaces passed when provided', () {
      final result = base.copyWith(passed: 99);
      expect(result.passed, equals(99));
    });

    test('copyWith preserves passed when not provided', () {
      final result = base.copyWith(outcome: TestOutcome.crash);
      expect(result.passed, equals(5));
    });

    test('copyWith replaces failed when provided', () {
      final result = base.copyWith(failed: 3);
      expect(result.failed, equals(3));
    });

    test('copyWith preserves failed when not provided', () {
      final result = base.copyWith(passed: 2);
      expect(result.failed, equals(0));
    });

    test('copyWith replaces skipped when provided', () {
      final result = base.copyWith(skipped: 7);
      expect(result.skipped, equals(7));
    });

    test('copyWith preserves skipped when not provided', () {
      final result = base.copyWith(passed: 2);
      expect(result.skipped, equals(1));
    });

    test('two instances with same values are equal', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
      );
      expect(base, equals(other));
    });

    test('two instances with different outcome are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.failure,
        passed: 5,
        failed: 0,
        skipped: 1,
      );
      expect(base, isNot(equals(other)));
    });

    test('two instances with different counts are not equal', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 4,
        failed: 1,
        skipped: 1,
      );
      expect(base, isNot(equals(other)));
    });

    test('hashCode is equal for two equal instances', () {
      const other = RunSummary(
        outcome: TestOutcome.success,
        passed: 5,
        failed: 0,
        skipped: 1,
      );
      expect(base.hashCode, equals(other.hashCode));
    });

    test('toString contains all field values', () {
      final str = base.toString();
      expect(str, contains('success'));
      expect(str, contains('5'));
      expect(str, contains('0'));
      expect(str, contains('1'));
    });
  });
}
