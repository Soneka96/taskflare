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

    test('Method run() includes non-JSON stdout lines in crashOutput', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"start","protocolVersion":"0.1.1"}',
            '{"testID":0,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
            'Dart VM out of memory',
            '#0  main (file:///project/lib/main.dart:10)',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.crashOutput, contains('Dart VM out of memory'));
      expect(notifier.received?.crashOutput, contains('#0  main'));
    });

    test('Method run() excludes valid JSON stdout lines from crashOutput', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"suite","suite":{"id":0,"platform":"vm","path":"test/foo_test.dart"}}',
            '[{"event":"test.startedProcess","params":{"vmServiceUri":null}}]',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.crashOutput, isNull);
    });

    test('Method run() populates exitCode when outcome is crash', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(lines: [], exitCode: 42),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.exitCode, equals(42));
    });

    test('Method run() does not set exitCode when outcome is success', () async {
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

      expect(notifier.received?.exitCode, isNull);
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

  group('Method run() attaches elapsed duration to the summary', () {
    test('Method run() sets a non-null duration on the summary', () async {
      final notifier = _FakeNotifier();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: ['{"type":"done","success":true}'],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
      );

      await taskflare.run();

      expect(notifier.received?.duration, isNotNull);
    });
  });

  group('Method run() strips group prefix from onTestFailed name', () {
    test('Method run() passes leaf test name without group prefix to onTestFailed',
        () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"group","group":{"id":1,"name":"My group","parentID":0}}',
            '{"type":"testStart","test":{"id":2,"name":"My group does fail","groupIDs":[0,1]}}',
            '{"testID":2,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        onTestFailed: (name) async => failedNames.add(name),
      );

      await taskflare.run();

      expect(failedNames, equals(['does fail']));
    });

    test('Method run() passes full name to onTestFailed when test has no group',
        () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"testStart","test":{"id":1,"name":"standalone failure","groupIDs":[0]}}',
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

      expect(failedNames, equals(['standalone failure']));
    });

    test(
        'Method run() strips Windows file path to basename in onTestFailed name',
        () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            r'{"type":"testStart","test":{"id":0,"name":"loading C:/BYME/SOLUTIONS/bhealthmobile/app/test/foo_test.dart","groupIDs":[0]}}',
            '{"testID":0,"result":"error","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        onTestFailed: (name) async => failedNames.add(name),
      );

      await taskflare.run();

      expect(failedNames, equals(['loading foo_test.dart']));
    });

    test('Method run() strips Unix file path to basename in onTestFailed name',
        () async {
      final notifier = _FakeNotifier();
      final failedNames = <String>[];
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"testStart","test":{"id":0,"name":"loading /home/user/project/test/bar_test.dart","groupIDs":[0]}}',
            '{"testID":0,"result":"error","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        onTestFailed: (name) async => failedNames.add(name),
      );

      await taskflare.run();

      expect(failedNames, equals(['loading bar_test.dart']));
    });
  });

  group('Method run() reports progress via progressReporter', () {
    test(
        'Method run() calls progressReporter.onTestDone for a standalone failing test (no group)',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"testStart","test":{"id":1,"name":"always fails","groupIDs":[0]}}',
            '{"testID":1,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.onTestDoneCount, equals(1));
    });

    test(
        'Method run() calls progressReporter.onTestDone for each user testDone event',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"group","group":{"id":1,"name":"My group","parentID":0}}',
            '{"type":"testStart","test":{"id":2,"name":"My group test one","groupIDs":[0,1]}}',
            '{"type":"testStart","test":{"id":3,"name":"My group test two","groupIDs":[0,1]}}',
            '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"testID":3,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.onTestDoneCount, equals(2));
    });

    test(
        'Method run() passes TestResultKind.errored for result "error" testDone',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"testStart","test":{"id":1,"name":"throws","groupIDs":[0]}}',
            '{"testID":1,"result":"error","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.doneCalls.single.result, equals(TestResultKind.errored));
    });

    test(
        'Method run() passes relative path with line to progressReporter.onTestDone',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"group","group":{"id":1,"name":"G","parentID":0}}',
            '{"type":"testStart","test":{"id":2,"name":"G fails","groupIDs":[0,1],"url":"file:///C:/project/test/foo_test.dart","line":42}}',
            '{"testID":2,"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":false}',
          ],
          exitCode: 1,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      final fileRef = reporter.doneCalls.single.fileRef;
      expect(fileRef, isNotNull);
      expect(fileRef, endsWith('foo_test.dart:42'));
    });

    test('Method run() calls progressReporter.onTestStart with leaf test name',
        () async {
      final notifier = _FakeNotifier();
      final reporter = _FakeProgressReporter();
      final taskflare = Taskflare(
        runner: _FakeRunner(
          lines: [
            '{"type":"group","group":{"id":1,"name":"My group","parentID":0}}',
            '{"type":"testStart","test":{"id":2,"name":"My group does pass","groupIDs":[0,1]}}',
            '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
            '{"type":"done","success":true}',
          ],
          exitCode: 0,
        ),
        parser: JsonEventParser(),
        notifier: notifier,
        progressReporter: reporter,
      );

      await taskflare.run();

      expect(reporter.startedNames, equals(['does pass']));
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
  int onTestDoneCount = 0;
  int doneCount = 0;
  final List<String> startedNames = [];
  final List<({String name, String? fileRef, TestResultKind result})> doneCalls = [];

  @override
  void onTestStart(String name, Duration elapsed) => startedNames.add(name);

  @override
  void onTestDone({
    required String name,
    String? fileRef,
    required TestResultKind result,
    required int totalPassed,
    required int totalFailed,
    required int totalSkipped,
  }) {
    onTestDoneCount++;
    doneCalls.add((name: name, fileRef: fileRef, result: result));
  }

  @override
  void done() => doneCount++;
}
