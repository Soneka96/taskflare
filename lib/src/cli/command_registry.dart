import '../config/taskflare_config.dart';
import 'custom_command.dart';
import 'profile/command_profile.dart';
import 'profile/run_profile.dart';
import 'profile/test_profile.dart';
import 'test_command.dart';

/// A runnable command entry wiring a [CommandProfile] to its [run] function.
class CliCommandEntry {
  const CliCommandEntry({
    required this.profile,
    required this.run,
  });

  final CommandProfile profile;
  final Future<void> Function(List<String> args, TaskflareConfig config) run;
}

/// All commands available to the CLI, in display order.
///
/// Adding a new command: create a [CommandProfile] subclass and append an
/// entry here — the menu, help screen, and run submenu all derive from this list.
List<CliCommandEntry> get commandRegistry => [
      CliCommandEntry(
        profile: const TestProfile(),
        run: (args, config) => runTestCommand(args, config),
      ),
      CliCommandEntry(
        profile: const RunProfile(),
        run: (args, config) => runCustomCommand(args, config),
      ),
    ];
