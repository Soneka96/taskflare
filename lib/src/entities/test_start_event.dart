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
    this.rootUrl,
    this.rootLine,
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
      rootUrl: test['root_url'] as String?,
      rootLine: test['root_line'] as int?,
    );
  }

  /// Unique identifier for this test.
  final int id;

  /// Full display name of the test, including the group name prefix.
  final String name;

  /// IDs of the groups that contain this test, ordered from outermost to innermost.
  final List<int> groupIds;

  /// File URL where this test is defined (e.g. `file:///path/to/test.dart`).
  /// For Flutter widget tests this points at `package:flutter_test/...`,
  /// not the user's test file — see [rootUrl].
  final String? url;

  /// Line number within [url] where this test is defined.
  final int? line;

  /// File URL of the user-authored call site (set when the test is invoked
  /// through a wrapper like Flutter's `testWidgets`). Always a `file:` URL
  /// pointing to the actual `_test.dart` file when present.
  final String? rootUrl;

  /// Line number within [rootUrl] of the user-authored call site.
  final int? rootLine;
}
