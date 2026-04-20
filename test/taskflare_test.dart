import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/notifier.dart';
import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/runner/command_runner.dart';
import 'package:taskflare/src/taskflare.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method run() calls the notifier with the correct outcome', () {
    test('Method run() calls notifier with success when all tests pass',
        () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"start","protocolVersion":"0.1.1"}',
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":1,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.success));
    });

    test('Method run() calls notifier with failure when tests fail', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"start","protocolVersion":"0.1.1"}',
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":1,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":2,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.failure));
    });

    test('Method run() calls notifier with crash when output is empty',
        () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(lines: [], exitCode: 1),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.outcome, equals(TestOutcome.crash));
    });
  });

  group('Method run() calls the notifier with the correct counts', () {
    test('Method run() passes correct passed and skipped counts to notifier',
        () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":1,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":3,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":4,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":5,"result":"success","skipped":true,"hidden":false,"type":"testDone"}',
            '{"testID":6,"result":"success","skipped":true,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
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
  });

  group('Method run() attaches crash output from stderr', () {
    test(
        'Method run() populates crashOutput when outcome is crash and stderr is non-empty',
        () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [],
          stderrLines: ['Error: compilation failed', 'lib/main.dart:1:1'],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(
        notifier.received?.crashOutput,
        contains('Error: compilation failed'),
      );
    });

    test('Method run() does not set crashOutput when outcome is success',
        () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          stderrLines: ['some warning'],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.crashOutput, isNull);
    });
  });

  group('Method run() calls the notifier the correct number of times', () {
    test('Method run() calls notifier exactly once per execution', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
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

  group('Method run() calls onTestFailed for each failed test', () {
    test('Method run() calls onTestFailed once per failed test', () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"testStart","test":{"id":1,"name":"my failing test"}}',
            '{"testID":1,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        onTestFailed: (name) async => failedNames.add(name),
      );

      await taskflare.run();

      expect(failedNames, equals(['my failing test']));
    });

    test('Method run() does not call onTestFailed when all tests pass',
        () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        onTestFailed: (name) async => failedNames.add(name),
      );

      await taskflare.run();

      expect(failedNames, isEmpty);
    });
  });

  group('Method run() reports progress via progressReporter', () {
    test('Method run() calls progressReporter.update for each testDone event',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":1,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.updateCount, equals(2));
    });

    test('Method run() calls progressReporter.done after stream completes',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.doneCount, equals(1));
    });
  });
}

class _FakeRunner extends CommandRunner {
  _FakeRunner({
    required this.lines,
    required this.exitCode,
    this.stderrLines = const [],
  });

  final List<String> lines;
  final List<String> stderrLines;
  final int exitCode;

  @override
  Future<CommandProcess> start() async => CommandProcess(
        stdout: Stream.fromIterable(lines),
        stderr: Stream.fromIterable(stderrLines),
        exitCode: Future.value(exitCode),
      );
}

class _FakeNotifier implements Notifier {
  RunSummary? received;
  int callCount = 0;

  @override
  Future<void> notify(RunSummary summary) async {
    received = summary;
    callCount++;
  }
}

class _FakeProgressReporter implements ProgressReporter {
  int updateCount = 0;
  int doneCount = 0;

  @override
  void update(int passed, int failed, int skipped) => updateCount++;

  @override
  void done() => doneCount++;
}
