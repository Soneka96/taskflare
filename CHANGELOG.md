# Changelog

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
