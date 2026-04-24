import 'dart:convert';

import 'done_event.dart';
import 'group_event.dart';
import 'test_done_event.dart';
import 'test_start_event.dart';

export 'done_event.dart';
export 'group_event.dart';
export 'test_done_event.dart';
export 'test_start_event.dart';

/// Base class for all JSON events emitted by the test runner.
///
/// Concrete subtypes are [GroupEvent], [TestStartEvent], [TestDoneEvent],
/// and [DoneEvent].
abstract class TestEvent {
  /// Attempts to decode a single JSON line into a [TestEvent].
  ///
  /// Returns `null` if the line is empty, not valid JSON,
  /// or has an unrecognised event type.
  static TestEvent? tryDecode(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      return switch (json['type'] as String?) {
        'group' => GroupEvent.fromJson(json),
        'testStart' => TestStartEvent.fromJson(json),
        'testDone' => TestDoneEvent.fromJson(json),
        'done' => DoneEvent.fromJson(json),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}
