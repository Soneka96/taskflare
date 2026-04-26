import 'package:path/path.dart' as p;

import '../utils/enums.dart';

/// All information known about a single test, accumulated across the lifetime
/// of a test run as JSON events arrive.
///
/// Fields are populated in three phases:
///   1. [TestStartEvent]  — identity and location fields
///   2. [ErrorEvent]      — error details (optional, before done)
///   3. [TestDoneEvent]   — result, duration, hidden flag
class Test {
  Test._({
    required this.id,
    required this.rawName,
    required this.leafName,
    required this.groupName,
    required this.groupIds,
    required this.fileRef,
    required this.startedAt,
  });

  /// Creates a [Test] from a `testStart` JSON event, resolving [leafName] and
  /// [groupName] immediately using [groupNames] (the current group-name table).
  factory Test.fromStart({
    required int id,
    required String rawName,
    required List<int> groupIds,
    required String? url,
    required int? line,
    required Map<int, String> groupNames,
  }) {
    return Test._(
      id: id,
      rawName: rawName,
      leafName: _stripGroupPrefix(rawName, groupIds, groupNames),
      groupName: _outerGroupName(groupIds, groupNames),
      groupIds: groupIds,
      fileRef: _buildFileRef(url, line),
      startedAt: DateTime.now(),
    );
  }

  // ── Identity ────────────────────────────────────────────────────────────────

  /// Unique identifier assigned by the test runner.
  final int id;

  /// Full display name including the group prefix (as emitted by the runner).
  final String rawName;

  /// Display name with the outermost group prefix removed.
  final String leafName;

  /// Name of the outermost named group, or empty string for ungrouped tests.
  final String groupName;

  /// IDs of all containing groups, outermost first.
  final List<int> groupIds;

  /// Relative `path:line` source reference, or `null` when unavailable.
  String? fileRef;

  /// Wall-clock time when the test started.
  final DateTime startedAt;

  // ── Set from ErrorEvent ───────────────────────────────────────────────────

  /// The error message, or `null` if no error was reported.
  String? errorMessage;

  /// `true` when the error originated from an `expect()` call.
  ///
  /// Flutter wraps `TestFailure` before it reaches the JSON reporter, making
  /// `isFailure` unreliable. We detect it from the error message as well.
  bool isExpectFailure = false;

  // ── Set from TestDoneEvent ────────────────────────────────────────────────

  /// Outcome of the test. Starts as [TestResultKind.none] until done.
  TestResultKind result = TestResultKind.none;

  /// Wall-clock duration from start to completion.
  Duration? duration;

  /// Whether this is an auto-generated hidden test (e.g. a group-level setup).
  bool hidden = false;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// `true` if the test belongs to at least one named group.
  bool get isUserTest => groupIds.length > 1;

  /// [leafName] with any embedded absolute file paths reduced to just the filename.
  String get leafNameStripped => _stripFilePaths(leafName);

  // ── Static helpers ────────────────────────────────────────────────────────

  static String _outerGroupName(List<int> groupIds, Map<int, String> groupNames) {
    for (final id in groupIds) {
      final name = groupNames[id] ?? '';
      if (name.isNotEmpty) {
        return name;
      }
    }
    return '';
  }

  static String _stripGroupPrefix(
    String fullName,
    List<int> groupIds,
    Map<int, String> groupNames,
  ) {
    for (final id in groupIds.reversed) {
      final groupName = groupNames[id] ?? '';
      if (groupName.isEmpty) {
        continue;
      }
      final prefix = '$groupName ';
      return fullName.startsWith(prefix)
          ? fullName.substring(prefix.length)
          : fullName;
    }
    return fullName;
  }

  static String? _buildFileRef(String? url, int? line) {
    if (url == null) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'file') {
      return null;
    }
    final abs = uri.toFilePath();
    final rel = p.relative(abs);
    return line != null ? '$rel:$line' : rel;
  }

  static String _stripFilePaths(String name) {
    return name.replaceAllMapped(
      RegExp(r'(?:[A-Za-z]:[/\\]|(?<!\w)/)\S+'),
      (match) => p.basename(match.group(0)!),
    );
  }
}
