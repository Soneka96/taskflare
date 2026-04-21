# taskflare

A Dart CLI tool that wraps `dart test` and observes the process externally — parsing its JSON output to determine a single, unambiguous result and notify you when it's done.

## Outcomes

Every run ends with exactly one of three outcomes:

| Outcome     | Meaning                                                    |
| ----------- | ---------------------------------------------------------- |
| `[SUCCESS]` | All tests passed                                           |
| `[FAILURE]` | At least one test failed                                   |
| `[CRASH]`   | Tests did not run or the process crashed before completing |

## Usage

Run it from the root of any Dart or Flutter project:

```sh
dart run taskflare
```

Pass any arguments you would normally pass to `dart test`:

```sh
dart run taskflare --name "my test"
dart run taskflare test/parser/
```

Example output:

```text
  FAIL  ▶ parses failure when done reports failure  test/parser/json_event_parser_test.dart:42
  THROW ▶ throws when input is malformed            test/parser/json_event_parser_test.dart:91
  SKIP  ▶ skipped scenario

[FAILURE]  passed: 108  failed: 2  skipped: 1  (14.3s)
```

- `FAIL` — assertion error (`expect` failed)
- `THROW` — uncaught exception thrown during the test
- `SKIP` — test was skipped
- File references are printed as `path/to/file.dart:line` — Ctrl+click in most terminals and IDEs to jump directly to the test

The progress line updates in-place while tests run and is erased when the run completes, leaving only the permanent failure/skip lines and the final summary.

## Windows notifications

On Windows, taskflare sends a native desktop toast notification at the end of each run and an immediate toast when a test fails.

On first run, taskflare automatically:

1. Writes the bundled app icon to `%LOCALAPPDATA%\Taskflare\taskflare.ico`
2. Registers `Taskflare.App` in `HKCU\Software\Classes\AppUserModelId\`
3. Creates a Start Menu shortcut (`Taskflare.lnk`) with the AppUserModelID set

This is what makes the Taskflare icon appear next to the app name in the notification header. No manual setup required. Re-registration happens automatically if any of the three components is missing (e.g. after a clean install or manual deletion).

To replace the icon, overwrite `%LOCALAPPDATA%\Taskflare\taskflare.ico` with any ICO file, then delete the Start Menu shortcut so it is recreated on the next run:

```powershell
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Taskflare.lnk" -Force
```

## Requirements

- Dart SDK `>=3.0.0 <4.0.0`
- Windows toast notifications require Windows 10 or later

## Architecture

taskflare follows a clean, layered architecture. Each layer has a single responsibility and depends only on the layers below it.

```text
bin/
└── taskflare.dart          Entry point — wires dependencies and calls the orchestrator

lib/src/
├── utils/
│   └── enums.dart          TestResultKind and TestOutcome enums
├── entities/
│   └── run_summary.dart    Immutable value object carrying the run result and counts
├── parser/
│   └── json_event_parser.dart  Reads dart test JSON lines → produces a RunSummary
├── runner/
│   ├── command_runner.dart      Abstract base: launches a process, exposes its output
│   ├── dart_test_runner.dart    Concrete: runs dart test --reporter=json
│   └── flutter_test_runner.dart Concrete: runs flutter test --machine
├── notifier/
│   ├── notifier.dart            Abstract interface: receives a RunSummary and reports it
│   ├── console_notifier.dart    Concrete: prints the final result to stdout
│   ├── composite_notifier.dart  Fans out to multiple notifiers
│   ├── progress_reporter.dart   Live progress line + permanent FAIL/THROW/SKIP lines
│   ├── windows_notifier.dart    Concrete: sends Windows toast notifications via PowerShell
│   └── windows_initializer.dart Registers the app and icon on first run (Windows only)
└── taskflare.dart          Orchestrator: runner → parser → notifier

lib/assets/
└── icon.png                Bundled app icon (written to LocalAppData on first run)
```

### Layer rules

```text
utils      ←  no dependencies
entities   ←  utils
parser     ←  entities, utils
runner     ←  utils
notifier   ←  entities, utils
taskflare  ←  all layers (orchestrator only)
```

The orchestrator depends only on **abstractions** (`CommandRunner`, `Notifier`) — never on concrete implementations. Swapping the notifier or runner requires no changes to `taskflare.dart`.

### Extending taskflare

**Add a new runner** (e.g. wrap `dart run build_runner build`):

1. Create `lib/src/runner/build_runner_runner.dart` extending `CommandRunner`
2. Override `run()` to launch the command and return a `CommandResult`
3. Add tests in `test/runner/build_runner_runner_test.dart`
4. Pass it to `Taskflare(runner: BuildRunnerRunner(), ...)`

**Add a new notifier** (e.g. webhook, Slack):

1. Create `lib/src/notifier/slack_notifier.dart` implementing `Notifier`
2. Implement `notify(RunSummary summary)`
3. Add tests in `test/notifier/slack_notifier_test.dart`
4. Pass it to `Taskflare(notifier: SlackNotifier(), ...)`

## Running tests

```sh
dart test
```

The integration tests in `test/runner/` spin up real subprocesses using the fixture projects under `test/fixtures/`. They take a few seconds — all other tests are pure unit tests and run instantly.

## Project conventions

| Document                                                               | Contents                                                      |
| ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| [`doc/conventions_testing.md`](doc/conventions_testing.md)           | Test structure, group/test naming rules, what must be covered |
| [`doc/conventions_architecture.md`](doc/conventions_architecture.md) | Folder layout, layer dependency rules, naming patterns        |
| [`doc/learnings.md`](doc/learnings.md)                               | Problems encountered and what we learned from them            |
