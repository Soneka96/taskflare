import 'package:taskflare/taskflare.dart';

class RunSummary {
  const RunSummary({
    required this.outcome,
    required this.passed,
    required this.failed,
    required this.skipped,
    this.failedTestNames = const [],
  });

  final TestOutcome outcome;
  final int passed;
  final int failed;
  final int skipped;
  final List<String> failedTestNames;

  RunSummary copyWith({
    TestOutcome? outcome,
    int? passed,
    int? failed,
    int? skipped,
    List<String>? failedTestNames,
  }) {
    return RunSummary(
      outcome: outcome ?? this.outcome,
      passed: passed ?? this.passed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      failedTestNames: failedTestNames ?? this.failedTestNames,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RunSummary &&
        other.outcome == outcome &&
        other.passed == passed &&
        other.failed == failed &&
        other.skipped == skipped &&
        _listEquals(other.failedTestNames, failedTestNames);
  }

  @override
  int get hashCode => Object.hash(
        outcome,
        passed,
        failed,
        skipped,
        Object.hashAll(failedTestNames),
      );

  @override
  String toString() => 'RunSummary(outcome: $outcome, passed: $passed, '
      'failed: $failed, skipped: $skipped, '
      'failedTestNames: $failedTestNames)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
