/// Contract for starting a test process and providing its output streams.
abstract class CommandRunner {
  const CommandRunner();

  /// Starts the underlying test process and returns a [CommandProcess].
  Future<CommandProcess> start();
}

/// Wraps the stdout, stderr, and exit code of a running test process.
class CommandProcess {
  CommandProcess({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  /// Line-by-line stream of the process standard output.
  final Stream<String> stdout;

  /// Line-by-line stream of the process standard error.
  final Stream<String> stderr;

  /// Completes with the process exit code when the process terminates.
  final Future<int> exitCode;
}
