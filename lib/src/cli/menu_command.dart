import 'dart:io';

import '../config/taskflare_config.dart';
import 'config_command.dart';
import 'help_command.dart';
import 'run_command.dart';
import 'terminal.dart';

/// Displays the main interactive menu shown when `taskflare` is run with no arguments.
Future<void> runMenuCommand() async {
  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final screen = TerminalScreen();
    _printMenu(screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        await runHelpCommand();
        prev = screen;
      case '2':
        await runConfigCommand();
        prev = screen;
      case '3':
        final config = await TaskflareConfig.load();
        await runRunCommand(config);
        prev = screen;
      case 'q':
        screen.clear();
        return;
      default:
        screen.writeln('  Enter 1, 2, 3, or q.');
        prev = screen;
    }
  }
}

void _printMenu(TerminalScreen s) {
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
