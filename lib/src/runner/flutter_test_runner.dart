import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';

class FlutterTestRunner extends CommandRunner {
  const FlutterTestRunner({
    this.arguments = const [],
    this.workingDirectory,
  });

  final List<String> arguments;
  final String? workingDirectory;

  @override
  Future<CommandProcess> start() async {
    final process = await Process.start(
      'flutter',
      ['test', '--machine', ...arguments],
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
