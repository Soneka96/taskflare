import 'dart:io';

import 'command_registry.dart';
import 'terminal.dart';

/// Interactive help index.
///
/// Loops until the user presses `b`. Uses [term] for all screen I/O so the
/// display stays inside the caller's alt buffer.
Future<void> runHelpCommand(TerminalSession term) async {
  final registry = commandRegistry;
  while (true) {
    term.clear();
    _printHelpIndex(registry, term);
    final input = term.readLine()?.trim().toLowerCase();
    if (input == 'b') return;
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      term.clear();
      _printCommandHelpByEntry(registry[index - 1], term);
      term.writeln();
      term.write('  Press Enter to go back...');
      term.readLine();
    }
  }
}

/// Prints help for [name] directly to stdout without entering the alt buffer.
///
/// Used by `taskflare help <command>` from the CLI.
void printCommandHelp(String name) {
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
  final buf = StringBuffer();
  buf.writeln();
  buf.writeln('  ${entry.profile.name} — ${entry.profile.description}');
  buf.writeln();
  for (final line in entry.profile.helpText.split('\n')) {
    buf.writeln(line);
  }
  stdout.write(buf);
}

void _printCommandHelpByEntry(CliCommandEntry entry, TerminalSession s) {
  s.writeln();
  s.writeln('  ${entry.profile.name} — ${entry.profile.description}');
  s.writeln();
  for (final line in entry.profile.helpText.split('\n')) {
    s.writeln(line);
  }
}

void _printHelpIndex(List<CliCommandEntry> registry, TerminalSession s) {
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
