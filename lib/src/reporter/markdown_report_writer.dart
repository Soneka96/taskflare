import 'dart:io';

import 'package:taskflare/taskflare.dart';

import '../entities/test.dart';
import 'report_writer.dart';

/// A [ReportWriter] that produces a Markdown file in a `taskflare-reports/`
/// subdirectory of the working directory.
///
/// Tests are buffered in memory and written all at once in [finish]. The
/// document order is: header → summary → failed → skipped → all tests by group.
class MarkdownReportWriter implements ReportWriter {
  /// Creates a [MarkdownReportWriter] that writes files into [reportsDirectory].
  MarkdownReportWriter({required this.reportsDirectory});

  /// Absolute path to the directory where report files are written.
  final String reportsDirectory;

  /// Tests grouped by [Test.groupName], preserving insertion order.
  final _groups = <String, List<Test>>{};

  @override
  void recordTest(Test test) {
    _groups.putIfAbsent(test.groupName, () => []).add(test);
  }

  @override
  Future<void> finish({
    required RunSummary summary,
    required String command,
    required String directory,
    required DateTime startedAt,
  }) async {
    await Directory(reportsDirectory).create(recursive: true);
    final filename = 'taskflare-${_timestamp(startedAt)}.md';
    final file = File('$reportsDirectory${Platform.pathSeparator}$filename');
    file.writeAsStringSync(_build(summary, command, directory, startedAt));
  }

  String _build(
    RunSummary summary,
    String command,
    String directory,
    DateTime startedAt,
  ) {
    final buf = StringBuffer();

    // ── Header ────────────────────────────────────────────────────────────────

    buf.writeln('# Taskflare Run');
    buf.writeln();
    buf.writeln('**Started:** ${_datetime(startedAt)}  ');
    buf.writeln('**Command:** `$command`  ');
    buf.writeln('**Directory:** `$directory`');
    buf.writeln();
    buf.writeln('---');
    buf.writeln();

    // ── Summary ───────────────────────────────────────────────────────────────

    buf.writeln('## Summary');
    buf.writeln();

    final outcomeLabel = switch (summary.outcome) {
      TestOutcome.success => 'SUCCESS',
      TestOutcome.failure => 'FAILURE',
      TestOutcome.crash => 'CRASH',
    };

    buf.writeln('- **Outcome:** $outcomeLabel');
    buf.writeln('- **Passed:** ${summary.passed}');
    buf.writeln('- **Failed:** ${summary.failed}');
    buf.writeln('- **Skipped:** ${summary.skipped}');

    if (summary.duration != null) {
      final secs = (summary.duration!.inMilliseconds / 1000).toStringAsFixed(1);
      buf.writeln('- **Duration:** ${secs}s');
    }

    buf.writeln();
    buf.writeln('---');
    buf.writeln();

    // ── Failed ────────────────────────────────────────────────────────────────

    final failed = _allTests()
        .where((t) => t.result == TestResultKind.failed || t.result == TestResultKind.errored)
        .toList();

    if (failed.isNotEmpty) {
      buf.writeln('## Failed tests');
      buf.writeln();
      for (final test in failed) {
        buf.writeln(_testLine(test));
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    // ── Skipped ───────────────────────────────────────────────────────────────

    final skipped = _allTests()
        .where((t) => t.result == TestResultKind.skipped)
        .toList();

    if (skipped.isNotEmpty) {
      buf.writeln('## Skipped tests');
      buf.writeln();
      for (final test in skipped) {
        buf.writeln(_testLine(test));
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    // ── All tests by group ────────────────────────────────────────────────────

    buf.writeln('## All tests');
    buf.writeln();

    if (_groups.isEmpty) {
      buf.writeln('_No tests recorded._');
      buf.writeln();
    } else {
      for (final entry in _groups.entries) {
        final heading = entry.key.isEmpty ? '(ungrouped)' : entry.key;
        buf.writeln('### $heading');
        buf.writeln();
        for (final test in entry.value) {
          buf.writeln(_testLine(test));
        }
        buf.writeln();
      }
    }

    return buf.toString();
  }

  Iterable<Test> _allTests() => _groups.values.expand((t) => t);

  String _testLine(Test test) {
    final icon = switch (test.result) {
      TestResultKind.passed => '✅',
      TestResultKind.failed => '❌',
      TestResultKind.errored => '⚠️',
      TestResultKind.skipped => '⏭',
      TestResultKind.none => '❓',
    };

    final label = switch (test.result) {
      TestResultKind.passed => 'PASS',
      TestResultKind.failed => 'FAIL',
      TestResultKind.errored => 'THROW',
      TestResultKind.skipped => 'SKIP',
      TestResultKind.none => 'NONE',
    };

    final meta = <String>[];
    if (test.fileRef != null) {
      meta.add(test.fileRef!);
    }
    if (test.duration != null) {
      final secs = (test.duration!.inMilliseconds / 1000).toStringAsFixed(2);
      meta.add('${secs}s');
    }

    final firstLine = '- $icon **$label** — ${test.leafName}';
    if (meta.isEmpty) {
      return firstLine;
    }
    return '$firstLine  \n  ${meta.join(' · ')}';
  }

  String _timestamp(DateTime dt) {
    return '${_p(dt.year, 4)}-${_p(dt.month)}-${_p(dt.day)}'
        '-${_p(dt.hour)}${_p(dt.minute)}${_p(dt.second)}';
  }

  String _datetime(DateTime dt) {
    return '${_p(dt.year, 4)}-${_p(dt.month)}-${_p(dt.day)} '
        '${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
  }

  String _p(int value, [int width = 2]) => value.toString().padLeft(width, '0');
}
