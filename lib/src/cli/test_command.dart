import 'dart:io';

import '../config/taskflare_config.dart';
import '../notifier/composite_notifier.dart';
import '../notifier/console_notifier.dart';
import '../notifier/progress_reporter.dart';
import '../notifier/windows_initializer.dart';
import '../notifier/windows_notifier.dart';
import '../parser/json_event_parser.dart';
import '../reporter/markdown_report_writer.dart';
import '../taskflare.dart';
import 'profile/test_profile.dart';

/// Runs the test command using the provided [config] and extra [arguments].
///
/// Wires together [Taskflare] with the configured [ProgressReporter],
/// [MarkdownReportWriter] (when enabled), and OS notifications.
Future<void> runTestCommand(
  List<String> arguments,
  TaskflareConfig config,
) async {
  if (Platform.isWindows) {
    await WindowsInitializer.ensureRegistered();
  }

  final cwd = Directory.current.path;
  final profile = const TestProfile();
  final runner = profile.buildRunner(arguments, cwd);
  final commandLabel = profile.resolveCommandLabel(cwd);
  final reportsDir = '$cwd${Platform.pathSeparator}taskflare-reports';

  final liveNotifier = WindowsNotifier();

  final taskflare = Taskflare(
    runner: runner,
    parser: JsonEventParser(),
    notifier: CompositeNotifier([
      const ConsoleNotifier(),
      WindowsNotifier(),
    ]),
    progressReporter: ConsoleProgressReporter(
      showFailed: config.showFailed,
      showErrored: config.showErrored,
      showSkipped: config.showSkipped,
    ),
    reportWriter: config.testReportEnabled
        ? MarkdownReportWriter(reportsDirectory: reportsDir)
        : null,
    command: commandLabel,
    onTestFailed: (name) => liveNotifier.notifyTestFailed(name),
  );

  await taskflare.run();
}
