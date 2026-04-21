/// Result of a single test.
enum TestResultKind {
  // not yet determined (default)
  none,

  // result: 'success', not skipped
  passed,

  // result: 'failure' — assertion error
  failed,

  // result: 'error' — uncaught exception
  errored,

  // skipped: true
  skipped,
}

/// Overall verdict of a test run.
enum TestOutcome {
  // all tests passed (exit code 0)
  success,

  // one or more tests failed
  failure,

  // process exited before a valid done event
  crash,
}
