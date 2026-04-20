import 'dart:io';

import 'package:taskflare/src/runner/dart_test_runner.dart';
import 'package:test/test.dart';

void main() {
  group('Method start() returns the correct exit code', () {
    test(
      'Method start() returns exit code 0 for a passing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('passing_project'),
        );
        final process = await runner.start();
        await process.stdout.drain<void>();
        expect(await process.exitCode, equals(0));
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'Method start() returns non-zero exit code for a failing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('failing_project'),
        );
        final process = await runner.start();
        await process.stdout.drain<void>();
        expect(await process.exitCode, isNot(equals(0)));
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });

  group('Method start() returns the correct output', () {
    test(
      'Method start() stdout contains a JSON done event for a passing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('passing_project'),
        );
        final process = await runner.start();
        final lines = await process.stdout.toList();
        final hasDone = lines.any((l) => l.contains('"type":"done"'));
        expect(hasDone, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'Method start() stdout contains a JSON done event for a failing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('failing_project'),
        );
        final process = await runner.start();
        final lines = await process.stdout.toList();
        final hasDone = lines.any((l) => l.contains('"type":"done"'));
        expect(hasDone, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

String _fixtureDir(String name) =>
    Directory('test/fixtures/$name').absolute.path;
