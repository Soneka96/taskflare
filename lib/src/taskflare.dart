import 'dart:io';

import 'entities/test_event.dart';
import 'notifier/notifier.dart';
import 'notifier/progress_reporter.dart';
import 'parser/json_event_parser.dart';
import 'reporter/report_writer.dart';
import 'reporter/test_record.dart';
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
    this.reportWriter,
    this.command,
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

  /// Writes a persistent markdown report after the run. Optional — omit to skip.
  final ReportWriter? reportWriter;

  /// The command string shown in the report header (e.g. `'dart test'`).
  /// Defaults to `'dart test'` when omitted.
  final String? command;

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
    final directory = Directory.current.path;

    await Future.wait([
      process.stdout.forEach((line) {
        state.lines.add(line);
        final event = TestEvent.tryDecode(line);
        if (event == null) {
          return;
        }

        switch (event) {
          case ErrorEvent e:
            state.recordError(e);

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
            final elapsed = state.testElapsed(e.testId);
            final resultKind = state.recordTestDone(e);

            if (reportWriter != null) {
              reportWriter!.recordTest(
                TestRecord(
                  leafName: state.leafName(e.testId),
                  groupName: state.outerGroupName(e.testId),
                  result: resultKind,
                  fileRef: state.fileRef(e.testId),
                  duration: elapsed,
                ),
              );
            }

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

    if (reportWriter != null) {
      await reportWriter!.finish(
        summary: summary,
        command: command ?? 'dart test',
        directory: directory,
        startedAt: startTime,
      );
    }

    await notifier.notify(summary);
  }
}
