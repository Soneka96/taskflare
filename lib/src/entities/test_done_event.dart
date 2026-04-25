import 'test_event.dart';

/// A `testDone` event emitted by the test runner when a test finishes.
class TestDoneEvent extends TestEvent {
  /// Creates a [TestDoneEvent].
  TestDoneEvent({
    required this.testId,
    required this.result,
    required this.skipped,
    required this.hidden,
  });

  /// Parses a [TestDoneEvent] from the raw JSON event map.
  factory TestDoneEvent.fromJson(Map<String, dynamic> json) {
    return TestDoneEvent(
      testId: json['testID'] as int,
      result: json['result'] as String?,
      skipped: json['skipped'] == true,
      hidden: json['hidden'] == true,
    );
  }

  /// Identifier of the test that finished, matching [TestStartEvent.id].
  final int testId;

  /// Outcome reported by the runner: `'success'`, `'failure'`, or `'error'`.
  /// `null` when the runner omits the result field.
  final String? result;

  /// Whether the test was explicitly skipped.
  final bool skipped;

  /// Whether this is an auto-generated hidden test (e.g. a group-level setup).
  /// Hidden tests are excluded from displayed counts.
  final bool hidden;
}
