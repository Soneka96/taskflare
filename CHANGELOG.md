# Changelog

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
