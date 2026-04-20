import '../utils/enums.dart';

class RunSummary {
  const RunSummary({
    required this.outcome,
    required this.passed,
    required this.failed,
    required this.skipped,
  });

  final TestOutcome outcome;
  final int passed;
  final int failed;
  final int skipped;

  RunSummary copyWith({
    TestOutcome? outcome,
    int? passed,
    int? failed,
    int? skipped,
  }) {
    return RunSummary(
      outcome: outcome ?? this.outcome,
      passed: passed ?? this.passed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RunSummary &&
        other.outcome == outcome &&
        other.passed == passed &&
        other.failed == failed &&
        other.skipped == skipped;
  }

  @override
  int get hashCode => Object.hash(outcome, passed, failed, skipped);

  @override
  String toString() =>
      'RunSummary(outcome: $outcome, passed: $passed, failed: $failed, skipped: $skipped)';
}
