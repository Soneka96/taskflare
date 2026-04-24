import 'dart:io';

import '../config/taskflare_config.dart';
import 'config_command.dart';
import 'help_command.dart';
import 'run_command.dart';

/// Displays the main interactive menu shown when `taskflare` is run with no arguments.
Future<void> runMenuCommand() async {
  while (true) {
    _printMenu();
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        await runHelpCommand();
      case '2':
        await runConfigCommand();
      case '3':
        final config = await TaskflareConfig.load();
        await runRunCommand(config);
      case 'q':
        return;
      default:
        stdout.writeln('  Enter 1, 2, 3, or q.');
    }
  }
}

void _printMenu() {
  stdout.writeln('');
  stdout.writeln(r'  ████████╗ █████╗ ███████╗██╗  ██╗███████╗██╗      █████╗ ██████╗ ███████╗');
  stdout.writeln(r'     ██╔══╝██╔══██╗██╔════╝██║ ██╔╝██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝');
  stdout.writeln(r'     ██║   ███████║███████╗█████╔╝ █████╗  ██║     ███████║██████╔╝█████╗  ');
  stdout.writeln(r'     ██║   ██╔══██║╚════██║██╔═██╗ ██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝  ');
  stdout.writeln(r'     ██║   ██║  ██║███████║██║  ██╗██║     ███████╗██║  ██║██║  ██║███████╗');
  stdout.writeln(r'     ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝');
  stdout.writeln('');
  stdout.writeln('  Run your tools. Get notified.');
  stdout.writeln('');
  stdout.writeln('  1) Help');
  stdout.writeln('  2) Config');
  stdout.writeln('  3) Run command');
  stdout.writeln('  q) Quit');
  stdout.writeln('');
  stdout.write('Choose: ');
}
