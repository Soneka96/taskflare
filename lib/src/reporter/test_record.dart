import '../utils/enums.dart';

/// Snapshot of a single completed test, buffered by [ReportWriter] for inclusion in the report.
class TestRecord {
  /// Creates a [TestRecord].
  const TestRecord({
    required this.leafName,
    required this.groupName,
    required this.result,
    this.fileRef,
    this.duration,
  });

  /// Display name of the test with the group prefix stripped.
  final String leafName;

  /// Name of the outermost group that contains this test.
  ///
  /// Empty string for tests that belong to no named group (shown as `(ungrouped)`).
  final String groupName;

  /// Outcome of the test.
  final TestResultKind result;

  /// Clickable `file:line` source reference, or `null` when unavailable.
  final String? fileRef;

  /// Wall-clock time from test start to test completion.
  final Duration? duration;
}
