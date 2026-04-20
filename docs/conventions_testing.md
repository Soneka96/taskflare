# Testing Conventions

## Structure

Tests are organized to mirror `lib/src/`:

```
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
void main() {           // level 1 — always main()
  group('ClassName', () {  // level 2 — class or feature under test
    test('does something specific', () { // level 3 — single behaviour
      ...
    });
  });
}
```

**Never nest a `group` inside a `group`.**

## What Must Be Tested

- Every public method on every class
- `copyWith` on all entities that have it — field-by-field: each field replaced, each field preserved when null
- Factory constructors and named constructors
- Edge cases: empty input, null-equivalent defaults, boundary values

## Naming

Test names describe **observable behaviour**, not implementation:

| Bad | Good |
|-----|------|
| `'copyWith works'` | `'copyWith replaces outcome when provided'` |
| `'parse test'` | `'returns failure when at least one test fails'` |
| `'notifier test'` | `'prints SUCCESS label to console on success outcome'` |

## Fakes Over Mocks

Prefer hand-written fakes (implementing the abstract interface) over generated mocks.
Fakes live in the same test file unless reused — then extract to `test/fakes/`.

## Assertions

- One logical assertion per test where practical
- Use `expect` with explicit matchers (`equals`, `isA`, `throwsA`, `contains`)
- Avoid `print` in tests; capture output via `IOOverrides` or constructor injection
