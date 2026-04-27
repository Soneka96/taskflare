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
    required this.filePath,
    required this.line,
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
    String? rootUrl,
    int? rootLine,
  }) {
    final (path, resolvedLine) = _resolveLocation(url, line, rootUrl, rootLine);
    return Test._(
      id: id,
      rawName: rawName,
      leafName: _stripGroupPrefix(rawName, groupIds, groupNames),
      groupName: _outerGroupName(groupIds, groupNames),
      groupIds: groupIds,
      filePath: path,
      line: resolvedLine,
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

  /// Relative path to the test source file, or `null` when unavailable.
  String? filePath;

  /// Line number within [filePath], or `null` when unknown.
  int? line;

  /// Relative `path:line` source reference, or just `path` when [line] is null,
  /// or `null` when [filePath] is null.
  String? get fileRef {
    if (filePath == null) {
      return null;
    }
    return line != null ? '$filePath:$line' : filePath;
  }

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

  /// Picks the best (path, line) pair from a `testStart` event.
  ///
  /// Prefers [rootUrl]/[rootLine] when present (Flutter's `testWidgets` puts
  /// the user-test location there while [url] points at the framework file).
  /// Falls back to [url]/[line]. Only `file:` URLs resolve to a path.
  static (String?, int?) _resolveLocation(
    String? url,
    int? line,
    String? rootUrl,
    int? rootLine,
  ) {
    final rootPath = _toRelativePath(rootUrl);
    if (rootPath != null) {
      return (rootPath, rootLine);
    }
    return (_toRelativePath(url), line);
  }

  static String? _toRelativePath(String? url) {
    if (url == null) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'file') {
      return null;
    }
    return p.relative(uri.toFilePath());
  }

  static String _stripFilePaths(String name) {
    return name.replaceAllMapped(
      RegExp(r'(?:[A-Za-z]:[/\\]|(?<!\w)/)\S+'),
      (match) => p.basename(match.group(0)!),
    );
  }
}
