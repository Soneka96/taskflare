import 'dart:convert';
import 'dart:io';

import 'command_runner.dart';

/// A [CommandRunner] that spawns an arbitrary shell command and streams its output.
class ShellRunner extends CommandRunner {
  const ShellRunner({required this.command});

  /// The full command string to execute (e.g. `'dart pub get'`).
  final String command;

  @override
  Future<CommandProcess> start() async {
    final parts = _split(command);
    final executable = parts.first;
    final args = parts.skip(1).toList();

    final process = await Process.start(
      executable,
      args,
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

  /// Splits a shell command string into tokens, respecting quoted strings.
  static List<String> _split(String command) {
    final tokens = <String>[];
    final buf = StringBuffer();
    var inSingle = false;
    var inDouble = false;

    for (var i = 0; i < command.length; i++) {
      final ch = command[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
      } else if (ch == ' ' && !inSingle && !inDouble) {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
      } else {
        buf.write(ch);
      }
    }
    if (buf.isNotEmpty) {
      tokens.add(buf.toString());
    }
    return tokens.isEmpty ? [command] : tokens;
  }
}
