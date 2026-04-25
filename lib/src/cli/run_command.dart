import '../config/taskflare_config.dart';
import 'command_registry.dart';
import 'terminal.dart';

/// Shows the run-command submenu and executes the chosen command.
///
/// Returns `true` when a command was executed — the caller should then exit
/// the menu loop, as the alt buffer has already been left via [TerminalSession.exitAlt].
/// Returns `false` when the user presses back.
///
/// [config] is forwarded to the selected command's run function.
/// [term] is used for screen I/O and is exited before the command runs so
/// its output lands in the normal terminal scrollback.
Future<bool> runRunCommand(TaskflareConfig config, TerminalSession term) async {
  final registry = commandRegistry;
  while (true) {
    term.clear();
    _printRunMenu(registry, term);
    final input = term.readLine()?.trim().toLowerCase();
    if (input == 'b') return false;
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      term.exitAlt();
      await registry[index - 1].run([], config);
      return true;
    }
  }
}

void _printRunMenu(List<CliCommandEntry> registry, TerminalSession s) {
  s.writeln();
  s.writeln('  Run command');
  s.writeln();
  for (var i = 0; i < registry.length; i++) {
    final e = registry[i];
    s.writeln('  ${i + 1}) ${e.profile.name.padRight(14)}${e.profile.description}');
  }
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose: ');
}
