import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

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
    final fileById = <int, String?>{};
    final pendingNotifications = <Future<void>>[];
    var passed = 0;
    var failed = 0;
    var skipped = 0;

    final startTime = DateTime.now();

    await Future.wait([
      process.stdout.forEach((line) {
        lines.add(line);
        final event = _tryDecodeEvent(line);
        if (event == null) {
          return;
        }

        final type = event['type'] as String?;

        if (type == 'group') {
          final group = event['group'] as Map<String, dynamic>?;
          if (group != null) {
            final id = group['id'] as int?;
            final name = (group['name'] as String?) ?? '';
            if (id != null) {
              groupById[id] = name;
            }
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
              fileById[id] = _fileRef(test);
              final isUserTest = groupIds.length > 1;
              if (isUserTest) {
                final leaf = _leafTestName(name, groupIds, groupById);
                final elapsed = DateTime.now().difference(startTime);
                progressReporter?.onTestStart(leaf, elapsed);
              }
            }
          }
        } else if (type == 'testDone') {
          if (event['hidden'] == true) {
            return;
          }
          final result = event['result'] as String?;
          final isSkipped = event['skipped'] == true;
          final isPassed = result == 'success';
          final testId = event['testID'] as int?;

          final resultKind = isSkipped
              ? TestResultKind.skipped
              : isPassed
                  ? TestResultKind.passed
                  : result == 'error'
                      ? TestResultKind.errored
                      : TestResultKind.failed;

          if (isSkipped) {
            skipped++;
          } else if (isPassed) {
            passed++;
          } else {
            failed++;
            final fullName = testId != null ? nameById[testId] : null;
            if (fullName != null && onTestFailed != null) {
              final leafName = _stripFilePaths(
                _leafTestName(
                  fullName,
                  testGroupIds[testId] ?? [],
                  groupById,
                ),
              );
              pendingNotifications.add(onTestFailed!(leafName));
            }
          }

          if (progressReporter != null && testId != null) {
            final groupIds = testGroupIds[testId] ?? [];
            final isUserTest = groupIds.length > 1;
            if (isUserTest || resultKind != TestResultKind.passed) {
              final fullName = nameById[testId];
              if (fullName != null) {
                final leafName = _leafTestName(fullName, groupIds, groupById);
                progressReporter!.onTestDone(
                  leafName,
                  fileById[testId],   // relative path:line, e.g. test/foo_test.dart:10
                  resultKind,
                  passed,
                  failed,
                  skipped,
                );
              }
            }
          }
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
      if (groupName.isEmpty) {
        continue;
      }
      final prefix = '$groupName ';
      return fullName.startsWith(prefix)
          ? fullName.substring(prefix.length)
          : fullName;
    }
    return fullName;
  }

  /// Builds a clickable file reference from a testStart [test] object.
  /// Returns a relative path with optional line suffix, e.g. "test/foo_test.dart:10".
  String? _fileRef(Map<String, dynamic> test) {
    final url = test['url'] as String?;
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'file') return null;
    final abs = uri.toFilePath();
    final rel = p.relative(abs, from: Directory.current.path);
    final line = test['line'] as int?;
    return line != null ? '$rel:$line' : rel;
  }

  /// Replaces any absolute file path segment in [name] with just the filename.
  /// e.g. "loading C:/some/path/foo_test.dart" → "loading foo_test.dart"
  String _stripFilePaths(String name) {
    return name.replaceAllMapped(
      RegExp(r'(?:[A-Za-z]:[/\\]|(?<!\w)/)\S+'),
      (match) => p.basename(match.group(0)!),
    );
  }

  Map<String, dynamic>? _tryDecodeEvent(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }
}
