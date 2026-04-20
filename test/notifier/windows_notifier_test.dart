import 'dart:io';

import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/windows_notifier.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method notify() invokes PowerShell with the correct title', () {
    test('Method notify() uses SUCCESS title when outcome is success',
        () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.success));

      expect(calls.single.script, contains('SUCCESS'));
    });

    test('Method notify() uses FAILURE title when outcome is failure',
        () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.failure));

      expect(calls.single.script, contains('FAILURE'));
    });

    test('Method notify() uses CRASH title when outcome is crash', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.crash));

      expect(calls.single.script, contains('CRASH'));
    });
  });

  group('Method notify() invokes PowerShell with the correct body', () {
    test('Method notify() includes passed count in the body', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(
        const RunSummary(
          outcome: TestOutcome.success,
          passed: 7,
          failed: 0,
          skipped: 0,
        ),
      );

      expect(calls.single.script, contains('passed: 7'));
    });

    test('Method notify() includes failed count in the body', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(
        const RunSummary(
          outcome: TestOutcome.failure,
          passed: 0,
          failed: 3,
          skipped: 0,
        ),
      );

      expect(calls.single.script, contains('failed: 3'));
    });

    test('Method notify() includes skipped count in the body', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(
        const RunSummary(
          outcome: TestOutcome.success,
          passed: 5,
          failed: 0,
        skipped: 2,
        ),
      );

      expect(calls.single.script, contains('skipped: 2'));
    });
  });

  group('Method notify() invokes PowerShell with the correct executable', () {
    test('Method notify() calls powershell executable', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.success));

      expect(calls.single.executable, equals('powershell'));
    });

    test('Method notify() passes -NoProfile flag', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.success));

      expect(calls.single.arguments, contains('-NoProfile'));
    });
  });

  group('Method notify() uses the correct app id', () {
    test('Method notify() uses custom appId when provided', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(
        appId: 'my.app',
        processRunner: _fakeRunner(calls),
      );

      await notifier.notify(_summary(TestOutcome.success));

      expect(calls.single.script, contains('my.app'));
    });

    test('Method notify() uses taskflare as default appId', () async {
      final calls = <_Call>[];
      final notifier = WindowsNotifier(processRunner: _fakeRunner(calls));

      await notifier.notify(_summary(TestOutcome.success));

      expect(calls.single.script, contains('Taskflare.App'));
    });
  });
}

RunSummary _summary(TestOutcome outcome) => RunSummary(
      outcome: outcome,
      passed: 0,
      failed: 0,
      skipped: 0,
    );

Future<ProcessResult> Function(String, List<String>) _fakeRunner(
  List<_Call> calls,
) {
  return (executable, arguments) async {
    calls.add(_Call(executable: executable, arguments: arguments));
    return ProcessResult(0, 0, '', '');
  };
}

class _Call {
  _Call({required this.executable, required this.arguments});

  final String executable;
  final List<String> arguments;

  String get script => arguments.join(' ');
}
