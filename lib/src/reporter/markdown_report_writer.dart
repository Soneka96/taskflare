import 'dart:io';

import 'package:taskflare/taskflare.dart';

import 'report_writer.dart';
import 'test_record.dart';

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

  /// Tests grouped by [TestRecord.groupName], preserving insertion order.
  final _groups = <String, List<TestRecord>>{};

  @override
  void recordTest(TestRecord record) {
    _groups.putIfAbsent(record.groupName, () => []).add(record);
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

    final failed = _allRecords()
        .where((r) => r.result == TestResultKind.failed || r.result == TestResultKind.errored)
        .toList();

    if (failed.isNotEmpty) {
      buf.writeln('## Failed tests');
      buf.writeln();
      for (final record in failed) {
        buf.writeln(_testLine(record));
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    // ── Skipped ───────────────────────────────────────────────────────────────

    final skipped = _allRecords()
        .where((r) => r.result == TestResultKind.skipped)
        .toList();

    if (skipped.isNotEmpty) {
      buf.writeln('## Skipped tests');
      buf.writeln();
      for (final record in skipped) {
        buf.writeln(_testLine(record));
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
        for (final record in entry.value) {
          buf.writeln(_testLine(record));
        }
        buf.writeln();
      }
    }

    return buf.toString();
  }

  Iterable<TestRecord> _allRecords() => _groups.values.expand((r) => r);

  String _testLine(TestRecord record) {
    final icon = switch (record.result) {
      TestResultKind.passed => '✅',
      TestResultKind.failed => '❌',
      TestResultKind.errored => '⚠️',
      TestResultKind.skipped => '⏭',
      TestResultKind.none => '❓',
    };

    final label = switch (record.result) {
      TestResultKind.passed => 'PASS',
      TestResultKind.failed => 'FAIL',
      TestResultKind.errored => 'THROW',
      TestResultKind.skipped => 'SKIP',
      TestResultKind.none => 'NONE',
    };

    final meta = <String>[];
    if (record.fileRef != null) {
      meta.add(record.fileRef!);
    }
    if (record.duration != null) {
      final secs = (record.duration!.inMilliseconds / 1000).toStringAsFixed(2);
      meta.add('${secs}s');
    }

    final firstLine = '- $icon **$label** — ${record.leafName}';
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
