import 'dart:io';

import 'command_registry.dart';
import 'terminal.dart';

/// Runs the help screen.
///
/// When [commandName] is provided, prints that command's help directly
/// (non-interactive, suitable for `taskflare help test`).
/// Without it, opens an interactive list of commands.
Future<void> runHelpCommand({String? commandName}) async {
  if (commandName != null) {
    _printCommandHelp(commandName);
    return;
  }

  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final registry = commandRegistry;
    final screen = TerminalScreen();
    _printHelpIndex(registry, screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == 'b') {
      screen.clear();
      return;
    }
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      screen.clear();
      final detail = TerminalScreen();
      _printCommandHelpByEntry(registry[index - 1], detail);
      detail.writeln();
      detail.write('  Press Enter to go back...');
      stdin.readLineSync();
      detail.clear();
      prev = null;
    } else {
      screen.writeln('  Enter a number or b to go back.');
      prev = screen;
    }
  }
}

void _printCommandHelp(String name) {
  final registry = commandRegistry;
  final entry = registry.where((e) => e.profile.name == name).firstOrNull;
  if (entry == null) {
    stdout.writeln();
    stdout.writeln("  Unknown command '$name'.");
    stdout.writeln(
      '  Available: ${registry.map((e) => e.profile.name).join(', ')}',
    );
    stdout.writeln();
    return;
  }
  final s = TerminalScreen();
  _printCommandHelpByEntry(entry, s);
}

void _printCommandHelpByEntry(CliCommandEntry entry, TerminalScreen s) {
  s.writeln();
  s.writeln('  ${entry.profile.name} — ${entry.profile.description}');
  s.writeln();
  for (final line in entry.profile.helpText.split('\n')) {
    s.writeln(line);
  }
}

void _printHelpIndex(List<CliCommandEntry> registry, TerminalScreen s) {
  s.writeln();
  s.writeln('  Help — available commands');
  s.writeln();
  for (var i = 0; i < registry.length; i++) {
    final e = registry[i];
    s.writeln('  ${i + 1}) ${e.profile.name.padRight(14)}${e.profile.description}');
  }
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose: ');
}
