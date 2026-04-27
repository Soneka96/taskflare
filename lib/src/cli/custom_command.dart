import 'dart:io';

import '../config/taskflare_config.dart';
import '../notifier/windows_initializer.dart';
import '../notifier/windows_notifier.dart';
import '../reporter/shell_report_writer.dart';
import '../runner/shell_runner.dart';

/// Runs an arbitrary shell command, streams its output, fires a desktop
/// notification on completion, and optionally writes a markdown report.
///
/// If [args] is empty, the user is prompted to type a command.
Future<void> runCustomCommand(
  List<String> args,
  TaskflareConfig config,
) async {
  final command = _resolveCommand(args);
  if (command.isEmpty) {
    return;
  }

  if (Platform.isWindows) {
    await WindowsInitializer.ensureRegistered();
  }

  final runner = ShellRunner(command: command);
  final process = await runner.start();
  final startTime = DateTime.now();
  final output = <String>[];

  stdout.writeln();
  stdout.writeln('  Running: $command');
  stdout.writeln();

  await Future.wait([
    process.stdout.forEach((line) {
      stdout.writeln(line);
      output.add(line);
    }),
    process.stderr.forEach((line) {
      stderr.writeln(line);
      output.add(line);
    }),
  ]);

  final duration = DateTime.now().difference(startTime);
  final exitCode = await process.exitCode;
  final secs = (duration.inMilliseconds / 1000).toStringAsFixed(1);
  final success = exitCode == 0;

  stdout.writeln();
  stdout.writeln(
    success
        ? '  [SUCCESS] Finished in ${secs}s'
        : '  [FAILURE] Exited with code $exitCode in ${secs}s',
  );

  final notifier = WindowsNotifier();
  await notifier.notifyCommandFinished(command, success: success);

  if (config.runReportEnabled) {
    final reportsDir = '${Directory.current.path}${Platform.pathSeparator}taskflare-reports';
    final writer = ShellReportWriter(reportsDirectory: reportsDir);
    await writer.write(
      command: command,
      directory: Directory.current.path,
      startedAt: startTime,
      duration: duration,
      exitCode: exitCode,
      output: output,
    );
  }
}

String _resolveCommand(List<String> args) {
  if (args.isNotEmpty) {
    return args.join(' ');
  }
  stdout.write('  Command: ');
  final line = stdin.readLineSync()?.trim() ?? '';
  return line;
}
