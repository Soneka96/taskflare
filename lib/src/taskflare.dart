import 'notifier/notifier.dart';
import 'parser/json_event_parser.dart';
import 'runner/command_runner.dart';

class Taskflare {
  const Taskflare({
    required this.runner,
    required this.parser,
    required this.notifier,
  });

  final CommandRunner runner;
  final JsonEventParser parser;
  final Notifier notifier;

  Future<void> run() async {
    final result = await runner.run();
    final summary = parser.parse(result.lines, result.exitCode);
    notifier.notify(summary);
  }
}
