abstract class CommandRunner {
  const CommandRunner();

  Future<CommandResult> run();
}

class CommandResult {
  const CommandResult({
    required this.lines,
    required this.stderrLines,
    required this.exitCode,
  });

  final List<String> lines;
  final List<String> stderrLines;
  final int exitCode;
}
