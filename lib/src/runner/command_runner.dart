abstract class CommandRunner {
  const CommandRunner();

  Future<CommandResult> run();
}

class CommandResult {
  const CommandResult({
    required this.lines,
    required this.exitCode,
  });

  final List<String> lines;
  final int exitCode;
}
