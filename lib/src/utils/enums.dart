/// Result of a single test.
enum TestResultKind {
  none, // not yet determined (default)
  passed, // result: 'success', not skipped
  failed, // result: 'failure' — assertion error
  errored, // result: 'error' — uncaught exception
  skipped, // skipped: true
}

/// Overall verdict of a test run.
enum TestOutcome {
  success, // all tests passed (exit code 0)
  failure, // one or more tests failed
  crash, // process exited before a valid done event
}
