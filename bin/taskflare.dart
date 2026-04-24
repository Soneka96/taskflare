import 'dart:io';

import 'package:taskflare/src/cli/config_command.dart';
import 'package:taskflare/src/cli/test_command.dart';
import 'package:taskflare/src/config/taskflare_config.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    final config = await TaskflareConfig.load();
    await runTestCommand(const [], config);
    return;
  }

  switch (args.first) {
    case 'test':
      final config = await TaskflareConfig.load();
      await runTestCommand(args.skip(1).toList(), config);
    case 'config':
      await runConfigCommand();
    case 'help':
      _printHelp();
    default:
      // Pass unknown args straight through as test arguments (backwards compat).
      final config = await TaskflareConfig.load();
      await runTestCommand(args, config);
  }
}

void _printHelp() {
  stdout.writeln('');
  stdout.writeln('Taskflare — test runner wrapper with live progress and notifications');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  taskflare                Run tests (auto-detects dart/flutter)');
  stdout.writeln('  taskflare test [args]    Run tests, passing [args] to the test runner');
  stdout.writeln('  taskflare config         Interactive configuration menu');
  stdout.writeln('  taskflare help           Show this help');
  stdout.writeln('');
  stdout.writeln('Report files are written to taskflare-reports/ in the current directory.');
  stdout.writeln('');
}
