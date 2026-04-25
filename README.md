# taskflare

A Dart CLI tool that runs your dev commands, parses their output to determine a single unambiguous result, and notifies you when they're done. Currently wraps `dart test` / `flutter test`; designed to grow to other commands (lint, build, codegen, …) behind a single menu-driven entry point.

## Outcomes

Every run ends with exactly one of three outcomes:

| Outcome     | Meaning                                                    |
| ----------- | ---------------------------------------------------------- |
| `[SUCCESS]` | All tests passed                                           |
| `[FAILURE]` | At least one test failed                                   |
| `[CRASH]`   | Tests did not run or the process crashed before completing |

## Usage

Run it from the root of any Dart or Flutter project.

### Interactive menu

```sh
dart run taskflare
```

Opens the main menu with options for Help, Config, and Run command. Designed for exploring taskflare for the first time.

### Run tests directly

```sh
dart run taskflare test
dart run taskflare test --name "my test"
dart run taskflare test test/parser/
```

### Help

```sh
dart run taskflare help           # Interactive command list
dart run taskflare help test      # Print test command help directly
```

### Config

```sh
dart run taskflare config         # Interactive configuration menu
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
└── taskflare.dart          Entry point — dispatches menu / help / config / commands

lib/src/
├── cli/                    CLI entry points (menu-driven)
│   ├── profile/            CommandProfile base + concrete profiles (TestProfile, …)
│   ├── command_registry.dart  Central list of runnable commands (drives menu/help/run)
│   ├── menu_command.dart      Main menu shown by bare `taskflare`
│   ├── help_command.dart      Interactive help + `help <name>` shortcut
│   ├── run_command.dart       "Run command" submenu
│   ├── config_command.dart    Interactive configuration menu
│   ├── test_command.dart      Wires Taskflare for the `test` command
│   └── terminal.dart          TerminalSession — owns the alt screen buffer, injected into all TUI screens
├── config/
│   └── taskflare_config.dart  Persisted user preferences (filter + report toggles)
├── utils/                  Shared utilities
│   ├── enums.dart          TestResultKind and TestOutcome enums
│   └── project_detector.dart  Detects Flutter vs. Dart project from pubspec.yaml
├── entities/               Immutable value objects (events, run_summary, …)
├── parser/
│   └── json_event_parser.dart  Reads test JSON lines → produces a RunSummary
├── runner/                 Abstract CommandRunner + process-based runners (dart / flutter test)
├── reporter/               Markdown run report writer (+ per-test records)
├── notifier/               Console + Windows toast notifiers, progress line, composite
└── taskflare.dart          Orchestrator: runner → parser → notifier + reporter

lib/assets/
└── icon.png                Bundled app icon (written to LocalAppData on first run)
```

### Layer rules

```text
utils      ←  no dependencies
entities   ←  utils
config     ←  no dependencies (pure persisted preferences)
parser     ←  entities, utils
runner     ←  utils
reporter   ←  entities, utils
notifier   ←  entities, utils
taskflare  ←  runner, parser, notifier, reporter, entities, utils (orchestrator only)
cli        ←  all layers (entry points that wire everything)
```

The orchestrator depends only on **abstractions** (`CommandRunner`, `Notifier`, `ReportWriter`) — never on concrete implementations. Swapping them requires no changes to `taskflare.dart`.

### Extending taskflare

**Add a new command** (e.g. `taskflare lint`):

1. Create `lib/src/cli/profile/lint_profile.dart` extending `CommandProfile` — implement `name`, `description`, `helpText`, `commandLabel`, and `buildRunner`
2. Create `lib/src/cli/lint_command.dart` wiring `Taskflare` for the new profile (notifier, reporter, progress options)
3. Add an entry to `commandRegistry` in `lib/src/cli/command_registry.dart` — menu, help, and run submenu pick it up automatically

**Add a new runner** (e.g. wrap `dart run build_runner build`):

1. Create `lib/src/runner/build_runner_runner.dart` extending `CommandRunner`
2. Override `run()` to launch the command and return a `CommandResult`
3. Add tests in `test/runner/build_runner_runner_test.dart`
4. Pass it to `Taskflare(runner: BuildRunnerRunner(), ...)` from a profile

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
