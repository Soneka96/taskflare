import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';

/// A [CommandRunner] that spawns a system process and streams its output line by line.
///
/// Subclasses must declare [executable] and [baseArgs]; this class handles
/// starting the process and transforming stdout/stderr to line streams.
abstract class ProcessTestRunner extends CommandRunner {
  const ProcessTestRunner({
    this.arguments = const [],
    this.workingDirectory,
  });

  /// Additional arguments appended after [baseArgs] when starting the process.
  final List<String> arguments;

  /// Working directory for the test process. Defaults to the current directory when `null`.
  final String? workingDirectory;

  /// The executable name to invoke (e.g. `'dart'` or `'flutter'`).
  String get executable;

  /// Base arguments prepended before [arguments] (e.g. `['test', '--reporter=json']`).
  List<String> get baseArgs;

  @override
  Future<CommandProcess> start() async {
    final process = await Process.start(
      executable,
      [...baseArgs, ...arguments],
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    return CommandProcess(
      stdout: process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter()),
      stderr: process.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter()),
      exitCode: process.exitCode,
    );
  }
}
