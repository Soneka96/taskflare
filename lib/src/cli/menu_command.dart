import '../config/taskflare_config.dart';
import 'config_command.dart';
import 'help_command.dart';
import 'run_command.dart';
import 'terminal.dart';

/// Entry point for the bare `taskflare` command.
///
/// Creates a [TerminalSession], enters the alt buffer, and loops the main menu
/// until the user quits or launches a command.
Future<void> runMenuCommand() async {
  final term = TerminalSession();
  await term.run(() => _menuLoop(term));
}

Future<void> _menuLoop(TerminalSession term) async {
  while (true) {
    term.clear();
    _printMenu(term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        await runHelpCommand(term);
      case '2':
        await runConfigCommand(term);
      case '3':
        final config = await TaskflareConfig.load();
        final ran = await runRunCommand(config, term);
        if (ran) return;
      case 'q':
        return;
    }
  }
}

void _printMenu(TerminalSession s) {
  s.writeln();
  s.writeln(r'  ████████╗ █████╗ ███████╗██╗  ██╗███████╗██╗      █████╗ ██████╗ ███████╗');
  s.writeln(r'     ██╔══╝██╔══██╗██╔════╝██║ ██╔╝██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝');
  s.writeln(r'     ██║   ███████║███████╗█████╔╝ █████╗  ██║     ███████║██████╔╝█████╗  ');
  s.writeln(r'     ██║   ██╔══██║╚════██║██╔═██╗ ██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝  ');
  s.writeln(r'     ██║   ██║  ██║███████║██║  ██╗██║     ███████╗██║  ██║██║  ██║███████╗');
  s.writeln(r'     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝');
  s.writeln();
  s.writeln('  Run your tools. Get notified.');
  s.writeln();
  s.writeln('  1) Help');
  s.writeln('  2) Config');
  s.writeln('  3) Run command');
  s.writeln('  q) Quit');
  s.writeln();
  s.write('Choose: ');
}
