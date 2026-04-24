import 'dart:io';

import '../config/taskflare_config.dart';
import 'command_registry.dart';
import 'terminal.dart';

/// Opens the interactive "Run command" submenu and executes the chosen command.
Future<void> runRunCommand(TaskflareConfig config) async {
  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final registry = commandRegistry;
    final screen = TerminalScreen();
    _printRunMenu(registry, screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == 'b') {
      screen.clear();
      return;
    }
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      screen.clear();
      await registry[index - 1].run([], config);
      return;
    } else {
      screen.writeln('  Enter a number or b to go back.');
      prev = screen;
    }
  }
}

void _printRunMenu(List<CliCommandEntry> registry, TerminalScreen s) {
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
