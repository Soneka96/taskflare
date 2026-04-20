import 'dart:io';

import 'package:taskflare/src/runner/dart_test_runner.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() returns the correct exit code', () {
    test(
      'Method run() returns exit code 0 for a passing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('passing_project'),
        );
        final result = await runner.run();
        expect(result.exitCode, equals(0));
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'Method run() returns non-zero exit code for a failing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('failing_project'),
        );
        final result = await runner.run();
        expect(result.exitCode, isNot(equals(0)));
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });

  group('Method run() returns the correct output', () {
    test(
      'Method run() output contains a JSON done event for a passing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('passing_project'),
        );
        final result = await runner.run();
        final hasDone = result.lines.any((l) => l.contains('"type":"done"'));
        expect(hasDone, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'Method run() output contains a JSON done event for a failing project',
      () async {
        final runner = DartTestRunner(
          workingDirectory: _fixtureDir('failing_project'),
        );
        final result = await runner.run();
        final hasDone = result.lines.any((l) => l.contains('"type":"done"'));
        expect(hasDone, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

String _fixtureDir(String name) =>
    Directory('test/fixtures/$name').absolute.path;
