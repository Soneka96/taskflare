import 'dart:io';

import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/composite_notifier.dart';
import 'package:taskflare/src/notifier/console_notifier.dart';
import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:taskflare/src/notifier/windows_notifier.dart';
import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/runner/dart_test_runner.dart';
import 'package:taskflare/src/runner/flutter_test_runner.dart';
import 'package:taskflare/src/taskflare.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:taskflare/src/utils/project_detector.dart';

Future<void> main(List<String> args) async {
  final cwd = Directory.current.path;
  final detector = const ProjectDetector();
  final isFlutter = detector.isFlutterProject(cwd);

  final runner = isFlutter
      ? FlutterTestRunner(arguments: args)
      : DartTestRunner(arguments: args);

  final liveNotifier = WindowsNotifier();

  final taskflare = Taskflare(
    runner: runner,
    parser: JsonEventParser(),
    notifier: CompositeNotifier([
      const ConsoleNotifier(),
      WindowsNotifier(),
    ]),
    progressReporter: ConsoleProgressReporter(),
    onTestFailed: (name) => liveNotifier.notify(
      RunSummary(
        outcome: TestOutcome.failure,
        passed: 0,
        failed: 1,
        skipped: 0,
        failedTestNames: [name],
      ),
    ),
  );

  await taskflare.run();
}
