import 'entities/test_event.dart';
import 'notifier/notifier.dart';
import 'notifier/progress_reporter.dart';
import 'parser/json_event_parser.dart';
import 'runner/command_runner.dart';
import 'runner/run_state.dart';
import 'utils/enums.dart';

/// Orchestrates a complete test run: starts the process via [CommandRunner],
/// parses JSON events, reports live progress via [ProgressReporter],
/// fires per-test notifications, and delivers the final [RunSummary] to [Notifier].
class Taskflare {
  /// Creates a [Taskflare].
  Taskflare({
    required this.runner,
    required this.parser,
    required this.notifier,
    this.progressReporter,
    this.onTestFailed,
  });

  /// Starts the test process and provides its stdout and stderr streams.
  final CommandRunner runner;

  /// Parses the raw stdout lines into a [RunSummary].
  final JsonEventParser parser;

  /// Receives the final [RunSummary] when the run completes.
  final Notifier notifier;

  /// Displays live test progress in the terminal. Optional — omit to suppress output.
  final ProgressReporter? progressReporter;

  /// Called immediately when a test fails, before the run completes.
  ///
  /// Receives the stripped test name (no group prefix, no file paths).
  /// Used to trigger per-failure desktop notifications via [WindowsNotifier.notifyTestFailed].
  final Future<void> Function(String testName)? onTestFailed;

  /// Runs the test process to completion, dispatches events to [progressReporter]
  /// and [onTestFailed], then delivers the final [RunSummary] to [notifier].
  Future<void> run() async {
    final process = await runner.start();
    final state = RunState();
    final startTime = DateTime.now();

    await Future.wait([
      process.stdout.forEach((line) {
        state.lines.add(line);
        final event = TestEvent.tryDecode(line);
        if (event == null) {
          return;
        }

        switch (event) {
          case GroupEvent e:
            state.recordGroup(e);

          case TestStartEvent e:
            state.recordTestStart(e);
            if (state.isUserTest(e.id)) {
              progressReporter?.onTestStart(
                state.leafName(e.id),
                DateTime.now().difference(startTime),
              );
            }

          case TestDoneEvent e:
            if (e.hidden) {
              return;
            }
            final resultKind = state.recordTestDone(e);

            if ((resultKind == TestResultKind.failed ||
                    resultKind == TestResultKind.errored) &&
                onTestFailed != null) {
              state.pendingNotifications
                  .add(onTestFailed!(state.leafNameStripped(e.testId)));
            }

            if (progressReporter != null &&
                (state.isUserTest(e.testId) ||
                    resultKind != TestResultKind.passed)) {
              progressReporter!.onTestDone(
                name: state.leafName(e.testId),
                fileRef: state.fileRef(e.testId),
                result: resultKind,
                totalPassed: state.passed,
                totalFailed: state.failed,
                totalSkipped: state.skipped,
              );
            }

          case DoneEvent():
        }
      }),
      process.stderr.forEach(state.stderrLines.add),
    ]);

    progressReporter?.done();
    await Future.wait(state.pendingNotifications);

    final elapsed = DateTime.now().difference(startTime);
    final exitCode = await process.exitCode;
    var summary = parser.parse(state.lines, exitCode);
    summary = summary.copyWith(duration: elapsed);

    if (summary.outcome == TestOutcome.crash && state.stderrLines.isNotEmpty) {
      summary = summary.copyWith(crashOutput: state.stderrLines.join('\n'));
    }

    await notifier.notify(summary);
  }
}
