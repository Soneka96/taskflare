import 'dart:io';

import 'package:path/path.dart' as p;

import '../entities/test_event.dart';
import '../utils/enums.dart';

/// Mutable state accumulated during a single test run in [Taskflare.run].
///
/// Records groups, tests, and their outcomes as events arrive, and exposes
/// helpers to look up display names, file references, and outcome kinds.
class RunState {
  /// All stdout lines received from the test process, forwarded to [JsonEventParser] after the run.
  final lines = <String>[];

  /// All stderr lines received from the test process, captured for crash output.
  final stderrLines = <String>[];

  /// In-flight per-failure notification futures, awaited after the run completes.
  final pendingNotifications = <Future<void>>[];

  final _nameById = <int, String>{};
  final _groupById = <int, String>{};
  final _testGroupIds = <int, List<int>>{};
  final _fileById = <int, String?>{};

  /// Number of tests that have passed so far.
  int passed = 0;

  /// Number of tests that have failed or errored so far.
  int failed = 0;

  /// Number of tests that have been skipped so far.
  int skipped = 0;

  /// Records a group from a [GroupEvent] so its name can be stripped from test display names.
  void recordGroup(GroupEvent e) {
    _groupById[e.id] = e.name;
  }

  /// Records a test start from a [TestStartEvent], storing its name, group membership,
  /// and file reference for later lookup.
  void recordTestStart(TestStartEvent e) {
    _nameById[e.id] = e.name;
    _testGroupIds[e.id] = e.groupIds;
    _fileById[e.id] = _buildFileRef(e.url, e.line);
  }

  /// Records a test completion from a [TestDoneEvent], increments the appropriate counter,
  /// and returns the [TestResultKind].
  TestResultKind recordTestDone(TestDoneEvent e) {
    final resultKind = e.skipped
        ? TestResultKind.skipped
        : e.result == 'success'
            ? TestResultKind.passed
            : e.result == 'error'
                ? TestResultKind.errored
                : TestResultKind.failed;

    if (e.skipped) {
      skipped++;
    } else if (e.result == 'success') {
      passed++;
    } else {
      failed++;
    }

    return resultKind;
  }

  /// Returns `true` if the test belongs to a named group (not just the implicit root group).
  bool isUserTest(int testId) => (_testGroupIds[testId]?.length ?? 0) > 1;

  /// Returns the display name of the test with its outermost group name prefix removed.
  String leafName(int testId) {
    final fullName = _nameById[testId] ?? '';
    return _stripGroupPrefix(fullName, _testGroupIds[testId] ?? []);
  }

  /// Returns [leafName] with any embedded absolute file paths reduced to just the filename.
  String leafNameStripped(int testId) => _stripFilePaths(leafName(testId));

  /// Returns the `file:line` reference for the test, or `null` if the source location is unavailable.
  String? fileRef(int testId) => _fileById[testId];

  String _stripGroupPrefix(String fullName, List<int> groupIds) {
    for (final id in groupIds.reversed) {
      final groupName = _groupById[id] ?? '';
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
    final rel = p.relative(abs, from: Directory.current.path);
    return line != null ? '$rel:$line' : rel;
  }

  static String _stripFilePaths(String name) {
    return name.replaceAllMapped(
      RegExp(r'(?:[A-Za-z]:[/\\]|(?<!\w)/)\S+'),
      (match) => p.basename(match.group(0)!),
    );
  }
}
