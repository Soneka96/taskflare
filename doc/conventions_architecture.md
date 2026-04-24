# Architecture Conventions

## Folder Layout

```text
lib/src/
├── cli/                # Entry-point commands: menu, help, run, config
│   ├── profile/        # CommandProfile abstractions and concrete impls (TestProfile, …)
│   ├── command_registry.dart   # Central list of all runnable commands
│   ├── menu_command.dart       # Main interactive menu (bare `taskflare`)
│   ├── help_command.dart       # Help screen and per-command help
│   ├── run_command.dart        # "Run command" submenu
│   ├── config_command.dart     # Config menu
│   └── test_command.dart       # Wires Taskflare for the `test` command
├── entities/     # Pure data classes — no I/O, no business logic
├── utils/        # Shared utilities: enums, constants, helpers
├── parser/       # Transforms raw output into domain types
├── runner/       # Launches subprocesses, exposes output as streams
├── notifier/     # Delivers results to the user (console, OS, webhook)
└── taskflare.dart  # Orchestrator — wires all layers together
```

## Layer Rules

| Layer        | Allowed dependencies | Forbidden                        |
| ------------ | -------------------- | -------------------------------- |
| `entities`   | `utils`              | everything else                  |
| `utils`      | nothing              | everything                       |
| `parser`     | `entities`, `utils`  | `runner`, `notifier`             |
| `runner`     | `utils`              | `parser`, `notifier`, `entities` |
| `notifier`   | `entities`, `utils`  | `runner`, `parser`               |
| orchestrator | all layers           | —                                |

## Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Abstracts / interfaces: plain name (`Notifier`, `CommandRunner`) — no `I` prefix, no `Abstract` prefix
- Enums: `PascalCase` type, `camelCase` values
- Constants: `kName` prefix only for package-level registries; otherwise plain `const`

## Abstract vs Concrete

- Every layer that touches I/O (runner, notifier) has an **abstract base class**
- Concrete implementations live in the same folder, named `{Adjective}{BaseName}` (e.g. `ConsoleNotifier`, `DartTestRunner`)
- The orchestrator depends **only on abstractions**, never on concrete types

## Entities

- Immutable (`final` fields)
- Provide `copyWith` when the entity has more than one field
- Override `==` and `hashCode` (or use `package:equatable` if added)
- No methods that perform I/O or computation beyond value transformation

## Adding a New Command

1. Create `lib/src/cli/profile/{name}_profile.dart` extending `CommandProfile`
   — implement `name`, `description`, `helpText`, `commandLabel`, and `buildRunner`
2. Add an entry to `commandRegistry` in `lib/src/cli/command_registry.dart`
   — the menu, help screen, and run submenu all derive from this list automatically
3. If the command needs its own wiring (e.g. custom notifier or config), create
   `lib/src/cli/{name}_command.dart` and reference it from the registry entry

## Adding a New Runner

1. Create `lib/src/runner/{name}_runner.dart` extending `CommandRunner`
2. Add corresponding test in `test/runner/{name}_runner_test.dart`
3. Wire it in `bin/taskflare.dart` or a factory

## Adding a New Notifier

1. Create `lib/src/notifier/{name}_notifier.dart` implementing `Notifier`
2. Add corresponding test in `test/notifier/{name}_notifier_test.dart`
3. Pass it to `Taskflare` constructor
