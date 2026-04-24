import 'dart:io';

import 'package:path/path.dart' as p;

import '../entities/test_event.dart';
import '../utils/enums.dart';

class RunState {
  final lines = <String>[];
  final stderrLines = <String>[];
  final pendingNotifications = <Future<void>>[];

  final _nameById = <int, String>{};
  final _groupById = <int, String>{};
  final _testGroupIds = <int, List<int>>{};
  final _fileById = <int, String?>{};

  int passed = 0;
  int failed = 0;
  int skipped = 0;

  void recordGroup(GroupEvent e) {
    _groupById[e.id] = e.name;
  }

  void recordTestStart(TestStartEvent e) {
    _nameById[e.id] = e.name;
    _testGroupIds[e.id] = e.groupIds;
    _fileById[e.id] = _buildFileRef(e.url, e.line);
  }

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

  bool isUserTest(int testId) => (_testGroupIds[testId]?.length ?? 0) > 1;

  String leafName(int testId) {
    final fullName = _nameById[testId] ?? '';
    return _stripGroupPrefix(fullName, _testGroupIds[testId] ?? []);
  }

  String leafNameStripped(int testId) => _stripFilePaths(leafName(testId));

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
