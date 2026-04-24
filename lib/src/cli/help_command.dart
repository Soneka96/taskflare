import 'dart:io';

import 'command_registry.dart';

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

  while (true) {
    final registry = commandRegistry;
    _printHelpIndex(registry);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == 'b') return;
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      _printCommandHelpByEntry(registry[index - 1]);
      stdout.writeln('');
      stdout.write('  Press Enter to go back...');
      stdin.readLineSync();
    } else {
      stdout.writeln('  Enter a number or b to go back.');
    }
  }
}

void _printCommandHelp(String name) {
  final registry = commandRegistry;
  final entry = registry.where((e) => e.profile.name == name).firstOrNull;
  if (entry == null) {
    stdout.writeln('');
    stdout.writeln("  Unknown command '$name'.");
    stdout.writeln(
      '  Available: ${registry.map((e) => e.profile.name).join(', ')}',
    );
    stdout.writeln('');
    return;
  }
  _printCommandHelpByEntry(entry);
}

void _printCommandHelpByEntry(CliCommandEntry entry) {
  stdout.writeln('');
  stdout.writeln('  ${entry.profile.name} — ${entry.profile.description}');
  stdout.writeln('');
  stdout.writeln(entry.profile.helpText);
}

void _printHelpIndex(List<CliCommandEntry> registry) {
  stdout.writeln('');
  stdout.writeln('  Help — available commands');
  stdout.writeln('');
  for (var i = 0; i < registry.length; i++) {
    final e = registry[i];
    stdout.writeln('  ${i + 1}) ${e.profile.name.padRight(14)}${e.profile.description}');
  }
  stdout.writeln('  b) Back');
  stdout.writeln('');
  stdout.write('Choose: ');
}
