import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/notifier.dart';
import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/runner/command_runner.dart';
import 'package:taskflare/src/taskflare.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Taskflare', () {
    test('calls notifier with success summary when all tests pass', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"start","protocolVersion":"0.1.1"}',
            '{"type":"done","success":true,"passedCount":3,"failedCount":0,"skippedCount":0}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.success));
    });

    test('calls notifier with failure summary when tests fail', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"start","protocolVersion":"0.1.1"}',
            '{"type":"done","success":false,"passedCount":1,"failedCount":2,"skippedCount":0}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.failure));
    });

    test('calls notifier with crash summary when output is empty', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(lines: [], exitCode: 1),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.crash));
    });

    test('passes correct counts to notifier', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"done","success":true,"passedCount":5,"failedCount":0,"skippedCount":2}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.passed, equals(5));
      expect(notifier.received?.skipped, equals(2));
    });

    test('notifier is called exactly once per run', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"done","success":true,"passedCount":1,"failedCount":0,"skippedCount":0}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.callCount, equals(1));
    });
  });
}

class _FakeRunner extends CommandRunner {
  _FakeRunner({required this.lines, required this.exitCode});

  final List<String> lines;
  final int exitCode;

  @override
  Future<CommandResult> run() async =>
      CommandResult(lines: lines, exitCode: exitCode);
}

class _FakeNotifier implements Notifier {
  RunSummary? received;
  int callCount = 0;

  @override
  void notify(RunSummary summary) {
    received = summary;
    callCount++;
  }
}
