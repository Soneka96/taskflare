import 'dart:convert';

import '../entities/run_summary.dart';
import '../utils/enums.dart';

class JsonEventParser {
  RunSummary parse(List<String> lines, int exitCode) {
    final events = _decodeEvents(lines);

    if (events.isEmpty) {
      return RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
      );
    }

    final done = _findDoneEvent(events);

    if (done == null) {
      return RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
      );
    }

    final counts = _countResults(events);
    final passed = counts.passed;
    final failed = counts.failed;
    final skipped = counts.skipped;

    // Prefer the done event's success flag; fall back to exit code.
    final success = (done['success'] as bool?) ?? (exitCode == 0);

    final outcome = !success
        ? (failed > 0 ? TestOutcome.failure : TestOutcome.crash)
        : TestOutcome.success;

    return RunSummary(
      outcome: outcome,
      passed: passed,
      failed: failed,
      skipped: skipped,
    );
  }

  List<Map<String, dynamic>> _decodeEvents(List<String> lines) {
    final events = <Map<String, dynamic>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          events.add(decoded);
        }
      } catch (_) {
        // non-JSON lines are skipped
      }
    }
    return events;
  }

  Map<String, dynamic>? _findDoneEvent(List<Map<String, dynamic>> events) {
    for (final event in events.reversed) {
      if (event['type'] == 'done') return event;
    }
    return null;
  }

  _TestCounts _countResults(List<Map<String, dynamic>> events) {
    var passed = 0;
    var failed = 0;
    var skipped = 0;

    for (final event in events) {
      if (event['type'] != 'testDone') continue;
      if (event['hidden'] == true) continue;

      final result = event['result'] as String?;
      final isSkipped = event['skipped'] == true;

      if (isSkipped) {
        skipped++;
      } else if (result == 'success') {
        passed++;
      } else {
        failed++;
      }
    }

    return _TestCounts(passed: passed, failed: failed, skipped: skipped);
  }
}

class _TestCounts {
  const _TestCounts({
    required this.passed,
    required this.failed,
    required this.skipped,
  });

  final int passed;
  final int failed;
  final int skipped;
}
