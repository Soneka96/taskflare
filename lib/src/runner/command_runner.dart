abstract class CommandRunner {
  const CommandRunner();

  Future<CommandProcess> start();
}

class CommandProcess {
  CommandProcess({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  final Stream<String> stdout;
  final Stream<String> stderr;
  final Future<int> exitCode;
}
