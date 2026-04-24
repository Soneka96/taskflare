import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';

abstract class ProcessTestRunner extends CommandRunner {
  const ProcessTestRunner({
    this.arguments = const [],
    this.workingDirectory,
  });

  final List<String> arguments;
  final String? workingDirectory;

  String get executable;
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
