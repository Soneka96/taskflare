import '../../runner/command_runner.dart';

/// Defines how to start a specific type of wrapped command (e.g. `test`, `build`).
///
/// Each profile knows which executable to invoke and how to build the
/// [CommandRunner] for it. The [Taskflare] orchestrator is profile-agnostic.
abstract class CommandProfile {
  const CommandProfile();

  /// Short identifier used in the CLI (e.g. `'test'`, `'build'`).
  String get name;

  /// Human-readable description shown in `taskflare help`.
  String get description;

  /// Detailed help text printed when the user selects this command in `taskflare help`.
  String get helpText;

  /// The command string shown in the report header (e.g. `'dart test'`).
  String get commandLabel;

  /// Builds a [CommandRunner] for this profile using [arguments] and [workingDirectory].
  CommandRunner buildRunner(List<String> arguments, String workingDirectory);
}
