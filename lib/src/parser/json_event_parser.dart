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

    final passed = (done['passedCount'] as int?) ?? 0;
    final failed = (done['failedCount'] as int?) ?? 0;
    final skipped = (done['skippedCount'] as int?) ?? 0;
    final success = (done['success'] as bool?) ?? false;

    final outcome = exitCode != 0 && !success
        ? (failed > 0 ? TestOutcome.failure : TestOutcome.crash)
        : (failed > 0 ? TestOutcome.failure : TestOutcome.success);

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
}
