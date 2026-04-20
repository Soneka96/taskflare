import 'package:taskflare/src/runner/command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('CommandResult stores the correct values', () {
    test('CommandResult stores stdout lines', () {
      const result =
          CommandResult(lines: ['a', 'b'], stderrLines: [], exitCode: 0);
      expect(result.lines, equals(['a', 'b']));
    });

    test('CommandResult stores stderr lines', () {
      const result = CommandResult(
        lines: [],
        stderrLines: ['error one', 'error two'],
        exitCode: 1,
      );
      expect(result.stderrLines, equals(['error one', 'error two']));
    });

    test('CommandResult stores exit code', () {
      const result =
          CommandResult(lines: [], stderrLines: [], exitCode: 42);
      expect(result.exitCode, equals(42));
    });

    test('CommandResult initializes with empty lines when empty list provided',
        () {
      const result =
          CommandResult(lines: [], stderrLines: [], exitCode: 0);
      expect(result.lines, isEmpty);
    });

    test(
        'CommandResult initializes with empty stderrLines when empty list provided',
        () {
      const result =
          CommandResult(lines: [], stderrLines: [], exitCode: 0);
      expect(result.stderrLines, isEmpty);
    });
  });
}
