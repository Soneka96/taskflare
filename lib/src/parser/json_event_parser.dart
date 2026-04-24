import 'package:taskflare/taskflare.dart';

import '../entities/test_event.dart';

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

    final done = events.whereType<DoneEvent>().lastOrNull;

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
    final success = done.success ?? (exitCode == 0);

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

  List<TestEvent> _decodeEvents(List<String> lines) {
    final events = <TestEvent>[];
    for (final line in lines) {
      final event = TestEvent.tryDecode(line);
      if (event != null) events.add(event);
    }
    return events;
  }

  Map<int, String> _buildNameMap(List<TestEvent> events) {
    final names = <int, String>{};
    for (final event in events) {
      if (event is TestStartEvent) names[event.id] = event.name;
    }
    return names;
  }

  _TestCounts _countResults(List<TestEvent> events, Map<int, String> nameById) {
    var passed = 0;
    var failed = 0;
    var skipped = 0;
    final failedTestNames = <String>[];

    for (final event in events) {
      if (event is! TestDoneEvent) {
        continue;
      }
      if (event.hidden) {
        continue;
      }

      if (event.skipped) {
        skipped++;
      } else if (event.result == 'success') {
        passed++;
      } else {
        failed++;
        final name = nameById[event.testId];
        if (name != null) {
          failedTestNames.add(name);
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
