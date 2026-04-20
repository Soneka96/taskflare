/// The overall verdict of a test run.
enum TestOutcome {
  /// All tests passed (exit code 0, `done` event reports `success: true`).
  success,

  /// One or more tests failed (exit code non-zero, at least one `testDone`
  /// event with `result != "success"`).
  failure,

  /// The process exited before producing a valid `done` event — typically a
  /// compilation error or unhandled exception in test setup.
  crash,
}
