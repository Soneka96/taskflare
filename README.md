# taskflare

A Dart CLI tool that wraps `dart test` and observes the process externally — parsing its JSON output to determine a single, unambiguous result and notify you when it's done.

## Outcomes

Every run ends with exactly one of three outcomes:

| Outcome | Meaning |
|---------|---------|
| `[SUCCESS]` | All tests passed |
| `[FAILURE]` | At least one test failed |
| `[CRASH]` | Tests did not run or the process crashed before completing |

## Usage

Run it from the root of any Dart project:

```sh
dart run taskflare
```

Pass any arguments you would normally pass to `dart test`:

```sh
dart run taskflare --name "my test"
dart run taskflare test/parser/
```

Example output:

```
[SUCCESS]  passed: 42  failed: 0  skipped: 2
[FAILURE]  passed: 10  failed: 3  skipped: 0
[CRASH]    passed: 0   failed: 0  skipped: 0
```

## Requirements

- Dart SDK `>=3.0.0 <4.0.0`

## Architecture

taskflare follows a clean, layered architecture. Each layer has a single responsibility and depends only on the layers below it.

```
bin/
└── taskflare.dart          Entry point — wires dependencies and calls the orchestrator

lib/src/
├── utils/
│   └── enums.dart          TestOutcome enum (success, failure, crash)
├── entities/
│   └── run_summary.dart    Immutable value object carrying the run result and counts
├── parser/
│   └── json_event_parser.dart  Reads dart test JSON lines → produces a RunSummary
├── runner/
│   ├── command_runner.dart      Abstract base: launches a process, exposes its output
│   └── dart_test_runner.dart    Concrete: runs dart test --reporter=json
├── notifier/
│   ├── notifier.dart            Abstract interface: receives a RunSummary and reports it
│   └── console_notifier.dart    Concrete: prints the result to stdout
└── taskflare.dart          Orchestrator: runner → parser → notifier
```

### Layer rules

```
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

**Add a new notifier** (e.g. desktop notification, webhook):

1. Create `lib/src/notifier/desktop_notifier.dart` implementing `Notifier`
2. Implement `notify(RunSummary summary)`
3. Add tests in `test/notifier/desktop_notifier_test.dart`
4. Pass it to `Taskflare(notifier: DesktopNotifier(), ...)`

## Running tests

```sh
dart test
```

The integration tests in `test/runner/` spin up real subprocesses using the fixture projects under `test/fixtures/`. They take a few seconds — all other tests are pure unit tests and run instantly.

## Project conventions

| Document | Contents |
|----------|----------|
| [`docs/conventions_testing.md`](docs/conventions_testing.md) | Test structure, group/test naming rules, what must be covered |
| [`docs/conventions_architecture.md`](docs/conventions_architecture.md) | Folder layout, layer dependency rules, naming patterns |
