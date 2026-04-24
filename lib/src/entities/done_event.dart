import 'test_event.dart';

/// A `done` event emitted when the test runner has finished all tests.
class DoneEvent extends TestEvent {
  /// Creates a [DoneEvent].
  DoneEvent({required this.success});

  /// Parses a [DoneEvent] from the raw JSON event map.
  factory DoneEvent.fromJson(Map<String, dynamic> json) {
    return DoneEvent(success: json['success'] as bool?);
  }

  /// Whether all tests passed according to the runner.
  ///
  /// `null` when the runner does not report this field — callers should
  /// fall back to the process exit code in that case.
  final bool? success;
}
