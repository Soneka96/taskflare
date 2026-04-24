/// Result of a single test, determined from a `testDone` event.
enum TestResultKind {
  /// Not yet determined (default state before the test finishes).
  none,

  /// The test passed (`result: 'success'`, not skipped).
  passed,

  /// The test failed due to an assertion error (`result: 'failure'`).
  failed,

  /// The test failed due to an uncaught exception (`result: 'error'`).
  errored,

  /// The test was explicitly skipped.
  skipped,
}

/// Overall verdict of a test run.
enum TestOutcome {
  /// All tests passed.
  success,

  /// One or more tests failed or errored.
  failure,

  /// The process exited before a `done` event was received.
  crash,
}
