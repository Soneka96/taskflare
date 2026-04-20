# Changelog

## 0.1.9

- Fix: progress line no longer spams when many tests complete in parallel — the line only re-renders when a new test starts, counts are stored internally and shown on the next render

## 0.1.8

- Progress line now shows time + counts + current test name on one overwriting line: `(9.1s)  passed: 108  failed: 1  skipped: 0  ▶ test name`
- Progress line is erased at the end so only the final summary and failed test names remain
- Truncates to terminal width to prevent line wrapping

## 0.1.7

- Progress line now shows elapsed time before the test name: `(1.2 s)  ▶ test name`
- Add dartdoc comments to all public API symbols (`RunSummary`, `TestOutcome` and their members)
- Add `example/taskflare_example.dart` for pub.dev scoring

## 0.1.6

- Fix: progress line now overwrites in-place with `\r` — only the currently running test name is shown, previous entries no longer accumulate

## 0.1.5

- Add elapsed time to console output: `[SUCCESS]  passed: 3  failed: 0  skipped: 0  (2.4s)`
- Show currently running test name on its own line (`▶ test name`) before each progress update
- Progress output now uses separate lines instead of overwriting with `\r`
- Per-failure toast title is now the leaf test name; group prefix is stripped
- Fix: per-failure toast now uses test name as title and "Test failed" as body

## 0.1.4

- Fix: per-failure Windows toast now shows "Test failed" title with the test name in the body instead of "End of tests"

## 0.1.3

- Add live progress counter: terminal updates in-place with `\r` showing running passed/failed/skipped counts
- Send immediate Windows toast notification when each test fails (includes failed test name)
- Final Windows notification now shows "End of tests" as title with outcome and counts in body
- Add `ProgressReporter` abstraction and `ConsoleProgressReporter`
- Add `onTestFailed` callback to `Taskflare` for per-failure side-effects
- Replace batch `CommandResult` with streaming `CommandProcess` (stdout/stderr as `Stream<String>`, exitCode as `Future<int>`)

## 0.1.2

- Fix: add `runInShell: true` to `FlutterTestRunner` and `DartTestRunner` so batch/cmd wrappers are resolved on Windows

## 0.1.1

- Fix: separate stdout and stderr streams so JSON parsing is not polluted by stderr output
- Fix: auto-detect Flutter projects and use `flutter test --machine` instead of `dart test --reporter=json`
- Fix: on `[CRASH]`, display the captured stderr so the cause is visible in the console
- Add `crashOutput` field to `RunSummary` carrying the raw stderr on crash
- Add `FlutterTestRunner` and `ProjectDetector`

## 0.1.0

- Initial release
- Wraps `dart test --reporter=json` and observes the process externally
- Detects SUCCESS, FAILURE, and CRASH outcomes
- Reports passed, failed, and skipped counts
- Lists names of all failed tests on failure
- Console notifier prints results to stdout
- Windows toast notifier fires a native desktop notification via PowerShell
- CompositeNotifier allows multiple notifiers to run together
- Clean layered architecture: runner → parser → notifier
