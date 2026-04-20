import 'package:taskflare/src/runner/command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('CommandProcess stdout stream emits the correct lines', () {
    test('CommandProcess stdout emits the expected lines', () async {
      final process = CommandProcess(
        stdout: Stream.fromIterable(['a', 'b']),
        stderr: Stream.empty(),
        exitCode: Future.value(0),
      );
      expect(await process.stdout.toList(), equals(['a', 'b']));
    });

    test('CommandProcess stdout emits empty list when no lines provided',
        () async {
      final process = CommandProcess(
        stdout: Stream.empty(),
        stderr: Stream.empty(),
        exitCode: Future.value(0),
      );
      expect(await process.stdout.toList(), isEmpty);
    });
  });

  group('CommandProcess stderr stream emits the correct lines', () {
    test('CommandProcess stderr emits the expected lines', () async {
      final process = CommandProcess(
        stdout: Stream.empty(),
        stderr: Stream.fromIterable(['error one', 'error two']),
        exitCode: Future.value(1),
      );
      expect(await process.stderr.toList(), equals(['error one', 'error two']));
    });
  });

  group('CommandProcess exitCode resolves to the correct value', () {
    test('CommandProcess exitCode resolves to 0', () async {
      final process = CommandProcess(
        stdout: Stream.empty(),
        stderr: Stream.empty(),
        exitCode: Future.value(0),
      );
      expect(await process.exitCode, equals(0));
    });

    test('CommandProcess exitCode resolves to non-zero', () async {
      final process = CommandProcess(
        stdout: Stream.empty(),
        stderr: Stream.empty(),
        exitCode: Future.value(42),
      );
      expect(await process.exitCode, equals(42));
    });
  });
}
