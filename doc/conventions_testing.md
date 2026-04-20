# Testing Conventions

## Structure

Tests are organized to mirror `lib/src/`:

```text
test/
├── entities/
├── parser/
├── notifier/
├── runner/
└── taskflare_test.dart
```

## File Naming

- Test files are named `{source_name}_test.dart`
- One test file per source file

## Test Hierarchy

Tests follow exactly **three levels** — no deeper nesting:

```dart
void main() {                               // level 1 — always main()
  group('Method foo() returns X', () {      // level 2 — aspect under test
    test('Method foo() returns Y when Z',   // level 3 — single scenario
        () { ... });
  });
}
```

**Never nest a `group` inside a `group`.**

## Group Naming

A group describes the **aspect or category** being tested — not a class name alone.

| Layer        | Group pattern                                           | Example                                                      |
| ------------ | ------------------------------------------------------- | ------------------------------------------------------------ |
| Entities     | `'ClassName\'s methodName() returns the correct value'` | `'RunSummary\'s copyWith() returns the correct value'`       |
| Entities     | `'ClassName\'s equality behaves correctly'`             | `'RunSummary\'s equality behaves correctly'`                 |
| Entities     | `'ClassName\'s hashCode behaves correctly'`             | `'RunSummary\'s hashCode behaves correctly'`                 |
| Parser       | `'Method methodName() returns the correct outcome'`     | `'Method parse() returns the correct outcome'`               |
| Parser       | `'Method methodName() returns the correct counts'`      | `'Method parse() returns the correct counts'`                |
| Notifier     | `'Method methodName() outputs the correct label'`       | `'Method notify() outputs the correct label'`                |
| Notifier     | `'Method methodName() outputs the correct counts'`      | `'Method notify() outputs the correct counts'`               |
| Runner       | `'ClassName stores the correct values'`                 | `'CommandResult stores the correct values'`                  |
| Runner       | `'Method methodName() returns the correct exit code'`   | `'Method run() returns the correct exit code'`               |
| Orchestrator | `'Method methodName() calls X with the correct Y'`      | `'Method run() calls the notifier with the correct outcome'` |

## Test Naming

Tests describe the **specific scenario and expected result**, always including the method name:

```text
'Method methodName() returns X when Y'
'Method methodName() does X when Y'
```

| Bad                | Good                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------- |
| `'copyWith works'` | `'Method copyWith() returns a new instance with outcome replaced'`                        |
| `'parse test'`     | `'Method parse() returns failure when done reports failure and failed count is positive'` |
| `'notifier test'`  | `'Method notify() prints SUCCESS label when outcome is success'`                          |

## What Must Be Tested

- Every public method on every class
- `copyWith` on all entities — field-by-field: each field replaced, each field preserved when not provided
- Equality (`==`) and `hashCode` on all entities that override them
- `toString()` on entities that override it
- Edge cases: empty input, missing fields, boundary values

## Setup

- `setUp()` must be defined **per group** or in `main()` if there is only one group and the setup is always the same
- Use `async` and `await` only when necessary
- Do not create tests outside of groups — even a single test must live inside a group

## Fakes Over Mocks

Prefer hand-written fakes (implementing the abstract interface) over generated mocks.
Fakes live in the same test file unless reused — then extract to `test/fakes/`.

## Assertions

- One logical assertion per test where practical
- Use `expect` with explicit matchers (`equals`, `isA`, `throwsA`, `contains`, `isEmpty`, `isTrue`)
- Never use `print` in tests; capture output via constructor-injected callbacks

## By Layer

### Entities

1. One group for each method (`copyWith`, etc.), named `'ClassName\'s methodName() returns the correct value'`
2. One group for equality, named `'ClassName\'s equality behaves correctly'`
3. One group for hashCode, named `'ClassName\'s hashCode behaves correctly'`
4. One group for `toString()`, named `'ClassName\'s toString() returns the correct value'`

### Parser

1. One group per logical aspect of the method (outcome, counts), named `'Method parse() returns the correct outcome'`

### Notifier

1. One group for label output: `'Method notify() outputs the correct label'`
2. One group for count output: `'Method notify() outputs the correct counts'`
3. One group for general behavior: `'Method notify() behaves correctly'`

### Runner

1. One group for value-object fields: `'ClassName stores the correct values'`
2. One group per behavior aspect: `'Method run() returns the correct exit code'`, `'Method run() returns the correct output'`

### Orchestrator

1. One group per observable outcome the method produces, named `'Method run() calls the notifier with the correct outcome'`
