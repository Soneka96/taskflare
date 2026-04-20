import 'package:taskflare/src/notifier/console_notifier.dart';
import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/runner/dart_test_runner.dart';
import 'package:taskflare/src/taskflare.dart';

Future<void> main(List<String> args) async {
  final taskflare = Taskflare(
    runner: DartTestRunner(arguments: args),
    parser: JsonEventParser(),
    notifier: const ConsoleNotifier(),
  );

  await taskflare.run();
}
