import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';

class DartTestRunner extends CommandRunner {
  const DartTestRunner({
    this.arguments = const [],
    this.workingDirectory,
  });

  final List<String> arguments;
  final String? workingDirectory;

  @override
  Future<CommandResult> run() async {
    final process = await Process.start(
      'dart',
      ['test', '--reporter=json', ...arguments],
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    final lines = <String>[];
    final stderrLines = <String>[];

    await Future.wait([
      process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .forEach(lines.add),
      process.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .forEach(stderrLines.add),
    ]);

    final exitCode = await process.exitCode;

    return CommandResult(
      lines: lines,
      stderrLines: stderrLines,
      exitCode: exitCode,
    );
  }
}
