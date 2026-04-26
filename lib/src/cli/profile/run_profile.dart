import '../../runner/command_runner.dart';
import '../../runner/shell_runner.dart';
import 'command_profile.dart';

/// A [CommandProfile] that runs an arbitrary shell command supplied by the user.
class RunProfile extends CommandProfile {
  const RunProfile({this.command = ''});

  /// The shell command to execute. Empty when not yet known (interactive prompt will fill it).
  final String command;

  @override
  String get name => 'run';

  @override
  String get description => 'Run any shell command and get notified on finish';

  @override
  String get commandLabel => 'taskflare run';

  @override
  String get helpText => '''
  Runs any shell command, streams its output to the terminal, fires a
  desktop notification when it finishes, and optionally writes a report.

  Usage:
    taskflare run dart pub get        Run a command directly
    taskflare run                     Prompt for a command interactively

  Report file (taskflare-reports/):
    Written after each run when "Generate report" is ON in config.
    Contains the command, exit code, duration, and captured output.

  Outcomes:
    SUCCESS — the command exited with code 0
    FAILURE — the command exited with a non-zero code''';

  @override
  CommandRunner buildRunner(List<String> arguments, String workingDirectory) {
    final cmd = arguments.isEmpty ? command : arguments.join(' ');
    return ShellRunner(command: cmd);
  }
}
