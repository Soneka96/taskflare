import 'dart:io';

import 'package:taskflare/src/cli/config_command.dart';
import 'package:taskflare/src/cli/custom_command.dart';
import 'package:taskflare/src/cli/help_command.dart';
import 'package:taskflare/src/cli/menu_command.dart';
import 'package:taskflare/src/cli/terminal.dart';
import 'package:taskflare/src/cli/test_command.dart';
import 'package:taskflare/src/config/taskflare_config.dart';
import 'package:taskflare/src/runner/shell_runner.dart';

Future<void> main(List<String> args) async {
  if (Platform.environment.containsKey(taskflareRunningEnv)) {
    stderr.writeln('  taskflare cannot be run inside taskflare run.');
    exit(1);
  }

  if (args.isEmpty) {
    await runMenuCommand();
    return;
  }

  switch (args.first) {
    case 'test':
      final config = await TaskflareConfig.load();
      await runTestCommand(args.skip(1).toList(), config);
    case 'run':
      final config = await TaskflareConfig.load();
      await runCustomCommand(args.skip(1).toList(), config);
    case 'config':
      final term = TerminalSession();
      await term.run(() => runConfigCommand(term));
    case 'help':
      if (args.length > 1) {
        printCommandHelp(args[1]);
      } else {
        final term = TerminalSession();
        await term.run(() => runHelpCommand(term));
      }
    default:
      final config = await TaskflareConfig.load();
      await runTestCommand(args, config);
  }
}
