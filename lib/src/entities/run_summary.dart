import 'package:taskflare/taskflare.dart';

class RunSummary {
  const RunSummary({
    required this.outcome,
    required this.passed,
    required this.failed,
    required this.skipped,
    this.failedTestNames = const [],
    this.crashOutput,
    this.duration,
  });

  final TestOutcome outcome;
  final int passed;
  final int failed;
  final int skipped;
  final List<String> failedTestNames;
  final String? crashOutput;

  /// Elapsed wall-clock time from process start to stream completion.
  final Duration? duration;

  RunSummary copyWith({
    TestOutcome? outcome,
    int? passed,
    int? failed,
    int? skipped,
    List<String>? failedTestNames,
    String? crashOutput,
    Duration? duration,
  }) {
    return RunSummary(
      outcome: outcome ?? this.outcome,
      passed: passed ?? this.passed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      failedTestNames: failedTestNames ?? this.failedTestNames,
      crashOutput: crashOutput ?? this.crashOutput,
      duration: duration ?? this.duration,
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
        other.crashOutput == crashOutput &&
        other.duration == duration &&
        _listEquals(other.failedTestNames, failedTestNames);
  }

  @override
  int get hashCode => Object.hash(
        outcome,
        passed,
        failed,
        skipped,
        crashOutput,
        duration,
        Object.hashAll(failedTestNames),
      );

  @override
  String toString() => 'RunSummary(outcome: $outcome, passed: $passed, '
      'failed: $failed, skipped: $skipped, '
      'failedTestNames: $failedTestNames, crashOutput: $crashOutput, '
      'duration: $duration)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
