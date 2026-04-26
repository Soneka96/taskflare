import '../entities/test.dart';
import '../entities/test_event.dart';
import '../utils/enums.dart';

/// Mutable state accumulated during a single test run in [Taskflare.run].
///
/// Maintains a [Test] per test ID, updated as events arrive, plus aggregate
/// counters and infrastructure for notifications and crash output.
class RunState {
  /// All stdout lines received from the test process, forwarded to [JsonEventParser] after the run.
  final lines = <String>[];

  /// All stderr lines received from the test process, captured for crash output.
  final stderrLines = <String>[];

  /// In-flight per-failure notification futures, awaited after the run completes.
  final pendingNotifications = <Future<void>>[];

  final _tests = <int, Test>{};
  final _groupById = <int, String>{};

  /// Number of tests that have passed so far.
  int passed = 0;

  /// Number of tests that have failed or errored so far.
  int failed = 0;

  /// Number of tests that have been skipped so far.
  int skipped = 0;

  // ── Event handlers ────────────────────────────────────────────────────────

  /// Records a group name so it can be stripped from test display names.
  void recordGroup(GroupEvent e) {
    _groupById[e.id] = e.name;
  }

  /// Creates a [Test] from a `testStart` event and stores it by ID.
  void recordTestStart(TestStartEvent e) {
    _tests[e.id] = Test.fromStart(
      id: e.id,
      rawName: e.name,
      groupIds: e.groupIds,
      url: e.url,
      line: e.line,
      groupNames: _groupById,
    );
  }

  /// Attaches error details to the matching [Test].
  void recordError(ErrorEvent e) {
    final test = _tests[e.testId];
    if (test == null) {
      return;
    }
    test.errorMessage = e.error;
    test.isExpectFailure = e.isExpectFailure;
  }

  /// Finalises the [Test], sets result and duration, increments counters.
  ///
  /// Returns the completed [Test], or `null` when no matching test was found.
  Test? recordTestDone(TestDoneEvent e) {
    final test = _tests[e.testId];
    if (test == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(test.startedAt);
    test.duration = elapsed;
    test.hidden = e.hidden;
    test.result = _resolveResult(e, test.isExpectFailure);

    if (e.skipped) {
      skipped++;
    } else if (e.result == 'success') {
      passed++;
    } else {
      failed++;
    }

    return test;
  }

  // ── Lookups ───────────────────────────────────────────────────────────────

  /// Returns the [Test] for [testId], or `null` when not found.
  Test? get(int testId) => _tests[testId];

  // ── Private ───────────────────────────────────────────────────────────────

  static TestResultKind _resolveResult(TestDoneEvent e, bool isExpectFailure) {
    if (e.skipped) {
      return TestResultKind.skipped;
    }
    if (e.result == 'success') {
      return TestResultKind.passed;
    }
    if (e.result == 'error' && !isExpectFailure) {
      return TestResultKind.errored;
    }
    return TestResultKind.failed;
  }
}
