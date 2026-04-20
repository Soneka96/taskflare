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
    final groupById = <int, String>{};
    final testGroupIds = <int, List<int>>{};
    final pendingNotifications = <Future<void>>[];
    var passed = 0;
    var failed = 0;
    var skipped = 0;

    final startTime = DateTime.now();

    await Future.wait([
      process.stdout.forEach((line) {
        lines.add(line);
        final event = _tryDecodeEvent(line);
        if (event == null) return;

        final type = event['type'] as String?;

        if (type == 'group') {
          final group = event['group'] as Map<String, dynamic>?;
          if (group != null) {
            final id = group['id'] as int?;
            final name = (group['name'] as String?) ?? '';
            if (id != null) groupById[id] = name;
          }
        } else if (type == 'testStart') {
          final test = event['test'] as Map<String, dynamic>?;
          if (test != null) {
            final id = test['id'] as int?;
            final name = test['name'] as String?;
            final rawGroupIds = test['groupIDs'] as List<dynamic>?;
            if (id != null && name != null) {
              final groupIds = rawGroupIds?.cast<int>() ?? <int>[];
              nameById[id] = name;
              testGroupIds[id] = groupIds;
              // skip auto-generated root-only tests (loading/compile stubs)
              final isUserTest = groupIds.length > 1;
              if (isUserTest) {
                final leaf = _leafTestName(name, groupIds, groupById);
                progressReporter?.onTestStart(leaf);
              }
            }
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
            final fullName = testId != null ? nameById[testId] : null;
            if (fullName != null && onTestFailed != null) {
              final leafName = _leafTestName(
                fullName,
                testGroupIds[testId] ?? [],
                groupById,
              );
              pendingNotifications.add(onTestFailed!(leafName));
            }
          }
          progressReporter?.update(passed, failed, skipped);
        }
      }),
      process.stderr.forEach(stderrLines.add),
    ]);

    progressReporter?.done();

    await Future.wait(pendingNotifications);

    final elapsed = DateTime.now().difference(startTime);
    final exitCode = await process.exitCode;
    var summary = parser.parse(lines, exitCode);

    summary = summary.copyWith(duration: elapsed);

    if (summary.outcome == TestOutcome.crash && stderrLines.isNotEmpty) {
      summary = summary.copyWith(crashOutput: stderrLines.join('\n'));
    }

    await notifier.notify(summary);
  }

  /// Strips the innermost non-empty group name prefix from [fullName].
  /// dart test accumulates group names, so the deepest group name is the
  /// full prefix: e.g. "Group A Group B test name" → "test name".
  String _leafTestName(
    String fullName,
    List<int> groupIds,
    Map<int, String> groupById,
  ) {
    for (final id in groupIds.reversed) {
      final groupName = groupById[id] ?? '';
      if (groupName.isEmpty) continue;
      final prefix = '$groupName ';
      return fullName.startsWith(prefix)
          ? fullName.substring(prefix.length)
          : fullName;
    }
    return fullName;
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
