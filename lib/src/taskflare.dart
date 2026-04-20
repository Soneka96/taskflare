import 'entities/run_summary.dart';
import 'notifier/notifier.dart';
import 'parser/json_event_parser.dart';
import 'runner/command_runner.dart';
import 'utils/enums.dart';

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
    var summary = parser.parse(result.lines, result.exitCode);

    if (summary.outcome == TestOutcome.crash &&
        result.stderrLines.isNotEmpty) {
      summary = summary.copyWith(
        crashOutput: result.stderrLines.join('\n'),
      );
    }

    await notifier.notify(summary);
  }
}
