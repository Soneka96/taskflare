# Changelog

## 0.2.1

- `taskflare run [cmd]` — runs any shell command, streams its output to the terminal, fires a Windows notification when it finishes, and optionally writes a markdown report
- Config restructured into two sections: **Tests** (filter toggles + report toggle) and **Run** (report on/off). Legacy flat config files are still read correctly
- Recursion guard: if taskflare is already running, a nested `taskflare run` is rejected with a clear error rather than spawning infinitely
- Fix: Flutter widget test failures from `expect()` now classify as **FAIL** instead of **THROW**. Flutter wraps `TestFailure` through its own error handler before it reaches the JSON reporter, causing `isFailure: false` and the real exception text to appear only in a `print` event; the classification now also detects the `"Test failed. See exception logs above…"` marker string
- Fix: file references in the terminal and markdown report now resolve to the user's test file for Flutter widget tests. The JSON `testStart` event sets `url` to a `package:flutter_test/…` path and puts the actual file in `root_url`/`root_line`; taskflare now prefers the root location
- THROW results show file path without a line number; all other results show `path:line`
- Markdown report section order: Summary → Failed tests → Skipped tests → All tests. Failed and Skipped sections use the same rich per-test format as All tests (icon, label, file ref, duration)

## 0.2.0

- Interactive main menu shown when running `taskflare` with no arguments — logo, tagline, and options for Help, Config, Run command, and Quit
- `taskflare help` opens an interactive command list; `taskflare help test` prints help non-interactively
- `taskflare` with no arguments no longer auto-runs tests — use `taskflare test` or choose "Run command" from the menu
- All menu-driven screens are backed by a central command registry — adding a future command requires one entry
- Fix: interactive menus no longer leave ghost content when navigating deep (menu → help → command detail → back). All TUI flows now run inside the terminal's alternate screen buffer, which provides a stable viewport cleared on each redraw — unaffected by scroll height. On exit the original terminal contents are restored.
- `TerminalScreen` replaced by `TerminalSession` — a single injected instance that owns the alt buffer lifecycle. A SIGINT handler ensures the buffer is always restored on Ctrl-C.
- After launching a command from "Run command", the alt buffer is exited so the command's output lands in normal terminal scrollback. The menu does not loop back after a run.

## 0.1.10

- Permanent `FAIL`, `THROW`, and `SKIP` lines in the terminal — each failed or skipped test prints a labelled line that stays visible, with a clickable `path/to/file.dart:line` reference for IDE navigation
- Distinguish assertion failures (`FAIL`) from uncaught exceptions (`THROW`) using the raw JSON result field
- Windows: auto-register `Taskflare.App` on first run — creates the registry key, ICO icon, and Start Menu shortcut so the notification header icon appears correctly without any manual setup
- Bundled app icon (`lib/assets/icon.png`) written to `%LOCALAPPDATA%\Taskflare\taskflare.ico` on first run; replace it with any PNG to customise the icon
- Re-registration is triggered automatically whenever the registry key, ICO file, or Start Menu shortcut is missing

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
