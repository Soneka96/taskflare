import 'dart:io';

import 'package:taskflare/src/notifier/composite_notifier.dart';
import 'package:taskflare/src/notifier/console_notifier.dart';
import 'package:taskflare/src/notifier/progress_reporter.dart';
import 'package:taskflare/src/notifier/windows_notifier.dart';
import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/runner/dart_test_runner.dart';
import 'package:taskflare/src/taskflare.dart';
import 'package:taskflare/src/utils/project_detector.dart';
import 'package:taskflare/src/runner/flutter_test_runner.dart';

/// Runs the test suite in the current working directory, prints live progress,
/// and fires a Windows toast notification when a test fails and when the run
/// ends.
Future<void> main(List<String> args) async {
  final cwd = Directory.current.path;
  final isFlutter = const ProjectDetector().isFlutterProject(cwd);

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
    onTestFailed: (name) => liveNotifier.notifyTestFailed(name),
  );

  await taskflare.run();
}
