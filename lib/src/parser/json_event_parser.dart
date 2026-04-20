import 'dart:convert';

import '../entities/run_summary.dart';
import '../utils/enums.dart';

class JsonEventParser {
  RunSummary parse(List<String> lines, int exitCode) {
    final events = _decodeEvents(lines);

    if (events.isEmpty) {
      return const RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
      );
    }

    final done = _findDoneEvent(events);

    if (done == null) {
      return const RunSummary(
        outcome: TestOutcome.crash,
        passed: 0,
        failed: 0,
        skipped: 0,
      );
    }

    final nameById = _buildNameMap(events);
    final counts = _countResults(events, nameById);

    final success = (done['success'] as bool?) ?? (exitCode == 0);

    final outcome = !success
        ? (counts.failed > 0 ? TestOutcome.failure : TestOutcome.crash)
        : TestOutcome.success;

    return RunSummary(
      outcome: outcome,
      passed: counts.passed,
      failed: counts.failed,
      skipped: counts.skipped,
      failedTestNames: counts.failedTestNames,
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

  Map<int, String> _buildNameMap(List<Map<String, dynamic>> events) {
    final names = <int, String>{};
    for (final event in events) {
      if (event['type'] != 'testStart') continue;
      final test = event['test'] as Map<String, dynamic>?;
      if (test == null) continue;
      final id = test['id'] as int?;
      final name = test['name'] as String?;
      if (id != null && name != null) {
        names[id] = name;
      }
    }
    return names;
  }

  _TestCounts _countResults(
    List<Map<String, dynamic>> events,
    Map<int, String> nameById,
  ) {
    var passed = 0;
    var failed = 0;
    var skipped = 0;
    final failedTestNames = <String>[];

    for (final event in events) {
      if (event['type'] != 'testDone') continue;
      if (event['hidden'] == true) continue;

      final result = event['result'] as String?;
      final isSkipped = event['skipped'] == true;
      final testId = event['testID'] as int?;

      if (isSkipped) {
        skipped++;
      } else if (result == 'success') {
        passed++;
      } else {
        failed++;
        if (testId != null) {
          final name = nameById[testId];
          if (name != null) failedTestNames.add(name);
        }
      }
    }

    return _TestCounts(
      passed: passed,
      failed: failed,
      skipped: skipped,
      failedTestNames: failedTestNames,
    );
  }
}

class _TestCounts {
  const _TestCounts({
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.failedTestNames,
  });

  final int passed;
  final int failed;
  final int skipped;
  final List<String> failedTestNames;
}
