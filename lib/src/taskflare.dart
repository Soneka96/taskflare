import 'dart:convert';

import 'notifier/notifier.dart';
import 'notifier/progress_reporter.dart';
import 'parser/json_event_parser.dart';
import 'runner/command_runner.dart';
import 'utils/enums.dart';

class Taskflare {
  Taskflare({
    required this.runner,
    required this.parser,
    required this.notifier,
    this.progressReporter,
    this.onTestFailed,
  });

  final CommandRunner runner;
  final JsonEventParser parser;
  final Notifier notifier;
  final ProgressReporter? progressReporter;
  final Future<void> Function(String testName)? onTestFailed;

  Future<void> run() async {
    final process = await runner.start();

    final lines = <String>[];
    final stderrLines = <String>[];
    final nameById = <int, String>{};
    final pendingNotifications = <Future<void>>[];
    var passed = 0;
    var failed = 0;
    var skipped = 0;

    await Future.wait([
      process.stdout.forEach((line) {
        lines.add(line);
        final event = _tryDecodeEvent(line);
        if (event == null) return;

        final type = event['type'] as String?;

        if (type == 'testStart') {
          final test = event['test'] as Map<String, dynamic>?;
          if (test != null) {
            final id = test['id'] as int?;
            final name = test['name'] as String?;
            if (id != null && name != null) nameById[id] = name;
          }
        } else if (type == 'testDone') {
          if (event['hidden'] == true) return;
          final result = event['result'] as String?;
          final isSkipped = event['skipped'] == true;
          final testId = event['testID'] as int?;

          if (isSkipped) {
            skipped++;
          } else if (result == 'success') {
            passed++;
          } else {
            failed++;
            final name = testId != null ? nameById[testId] : null;
            if (name != null && onTestFailed != null) {
              pendingNotifications.add(onTestFailed!(name));
            }
          }
          progressReporter?.update(passed, failed, skipped);
        }
      }),
      process.stderr.forEach(stderrLines.add),
    ]);

    progressReporter?.done();

    await Future.wait(pendingNotifications);

    final exitCode = await process.exitCode;
    var summary = parser.parse(lines, exitCode);

    if (summary.outcome == TestOutcome.crash && stderrLines.isNotEmpty) {
      summary = summary.copyWith(crashOutput: stderrLines.join('\n'));
    }

    await notifier.notify(summary);
  }

  Map<String, dynamic>? _tryDecodeEvent(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
