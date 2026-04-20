import 'package:taskflare/src/runner/command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('CommandResult stores the correct values', () {
    test('CommandResult stores lines', () {
      const result = CommandResult(lines: ['a', 'b'], exitCode: 0);
      expect(result.lines, equals(['a', 'b']));
    });

    test('CommandResult stores exit code', () {
      const result = CommandResult(lines: [], exitCode: 42);
      expect(result.exitCode, equals(42));
    });

    test('CommandResult initializes with empty lines when empty list provided',
        () {
      const result = CommandResult(lines: [], exitCode: 0);
      expect(result.lines, isEmpty);
    });
  });
}
