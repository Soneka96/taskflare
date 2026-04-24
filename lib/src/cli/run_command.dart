import 'dart:io';

import '../config/taskflare_config.dart';
import 'command_registry.dart';

/// Opens the interactive "Run command" submenu and executes the chosen command.
Future<void> runRunCommand(TaskflareConfig config) async {
  while (true) {
    final registry = commandRegistry;
    _printRunMenu(registry);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == 'b') return;
    final index = int.tryParse(input ?? '');
    if (index != null && index >= 1 && index <= registry.length) {
      await registry[index - 1].run([], config);
      return;
    } else {
      stdout.writeln('  Enter a number or b to go back.');
    }
  }
}

void _printRunMenu(List<CliCommandEntry> registry) {
  stdout.writeln('');
  stdout.writeln('  Run command');
  stdout.writeln('');
  for (var i = 0; i < registry.length; i++) {
    final e = registry[i];
    stdout.writeln('  ${i + 1}) ${e.profile.name.padRight(14)}${e.profile.description}');
  }
  stdout.writeln('  b) Back');
  stdout.writeln('');
  stdout.write('Choose: ');
}
