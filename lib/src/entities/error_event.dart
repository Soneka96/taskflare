import 'test_event.dart';

/// An `error` event emitted by the test runner when a test encounters an error.
///
/// Fired before the matching [TestDoneEvent]. [isFailure] distinguishes a
/// `TestFailure` thrown by `expect()` from a genuine uncaught exception.
class ErrorEvent extends TestEvent {
  ErrorEvent({
    required this.testId,
    required this.isFailure,
    required this.error,
  });

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(
      testId: json['testID'] as int,
      isFailure: json['isFailure'] == true,
      error: json['error'] as String? ?? '',
    );
  }

  /// Identifier of the test that encountered the error.
  final int testId;

  /// `true` when the thrown object is a `TestFailure` (i.e. from `expect()`).
  /// `false` when it is any other uncaught exception.
  final bool isFailure;

  /// The error message string as reported by the test runner.
  final String error;

  /// Whether this error originated from an `expect()` call, either via the
  /// [isFailure] flag or because the message is a `TestFailure` string
  /// (Flutter wraps `TestFailure` before it reaches the JSON reporter,
  /// causing [isFailure] to be `false` even for assertion mismatches).
  bool get isExpectFailure =>
      isFailure || error.contains('TestFailure') || error.startsWith('Expected:');
}
