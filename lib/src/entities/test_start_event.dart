import 'test_event.dart';

/// A `testStart` event emitted when the test runner begins executing a test.
class TestStartEvent extends TestEvent {
  /// Creates a [TestStartEvent].
  TestStartEvent({
    required this.id,
    required this.name,
    required this.groupIds,
    this.url,
    this.line,
  });

  /// Parses a [TestStartEvent] from the raw JSON event map.
  factory TestStartEvent.fromJson(Map<String, dynamic> json) {
    final test = json['test'] as Map<String, dynamic>;
    final rawGroupIds = test['groupIDs'] as List<dynamic>?;
    return TestStartEvent(
      id: test['id'] as int,
      name: test['name'] as String,
      groupIds: rawGroupIds?.cast<int>() ?? const [],
      url: test['url'] as String?,
      line: test['line'] as int?,
    );
  }

  /// Unique identifier for this test.
  final int id;

  /// Full display name of the test, including the group name prefix.
  final String name;

  /// IDs of the groups that contain this test, ordered from outermost to innermost.
  final List<int> groupIds;

  /// File URL where this test is defined (e.g. `file:///path/to/test.dart`).
  /// `null` when the runner does not report a source location.
  final String? url;

  /// Line number within [url] where this test is defined.
  /// `null` when the runner does not report a source location.
  final int? line;
}
