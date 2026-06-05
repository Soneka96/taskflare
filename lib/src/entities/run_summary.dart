import 'package:taskflare/taskflare.dart';

/// Immutable summary of a completed test run.
///
/// Produced by [JsonEventParser] and consumed by [Notifier] implementations.
/// All counts exclude hidden (auto-generated) tests.
class RunSummary {
  /// Creates a [RunSummary].
  ///
  /// [outcome], [passed], [failed], and [skipped] are required.
  /// [failedTestNames] defaults to an empty list when omitted.
  const RunSummary({
    required this.outcome,
    required this.passed,
    required this.failed,
    required this.skipped,
    this.failedTestNames = const [],
    this.crashOutput,
    this.exitCode,
    this.duration,
  });

  /// The overall verdict of the run.
  final TestOutcome outcome;

  /// Number of tests that passed (not skipped, not failed).
  final int passed;

  /// Number of tests that failed.
  final int failed;

  /// Number of tests that were skipped.
  final int skipped;

  /// Names of all failed tests, in the order they completed.
  ///
  /// Empty when [outcome] is [TestOutcome.success] or [TestOutcome.crash].
  final List<String> failedTestNames;

  /// Stderr captured from the process when the outcome is [TestOutcome.crash].
  ///
  /// `null` for [TestOutcome.success] and [TestOutcome.failure].
  final String? crashOutput;

  /// Process exit code, populated when the outcome is [TestOutcome.crash].
  ///
  /// `null` for [TestOutcome.success] and [TestOutcome.failure].
  final int? exitCode;

  /// Elapsed wall-clock time from process start to stream completion.
  ///
  /// `null` when the summary is constructed without timing information.
  final Duration? duration;

  /// Returns a copy of this summary with the given fields replaced.
  RunSummary copyWith({
    TestOutcome? outcome,
    int? passed,
    int? failed,
    int? skipped,
    List<String>? failedTestNames,
    String? crashOutput,
    int? exitCode,
    Duration? duration,
  }) {
    return RunSummary(
      outcome: outcome ?? this.outcome,
      passed: passed ?? this.passed,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      failedTestNames: failedTestNames ?? this.failedTestNames,
      crashOutput: crashOutput ?? this.crashOutput,
      exitCode: exitCode ?? this.exitCode,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RunSummary &&
        other.outcome == outcome &&
        other.passed == passed &&
        other.failed == failed &&
        other.skipped == skipped &&
        other.crashOutput == crashOutput &&
        other.exitCode == exitCode &&
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
        exitCode,
        duration,
        Object.hashAll(failedTestNames),
      );

  @override
  String toString() => 'RunSummary(outcome: $outcome, passed: $passed, '
      'failed: $failed, skipped: $skipped, '
      'failedTestNames: $failedTestNames, crashOutput: $crashOutput, '
      'exitCode: $exitCode, duration: $duration)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
