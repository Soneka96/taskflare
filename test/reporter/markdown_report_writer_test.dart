import 'dart:io';

import 'package:taskflare/src/entities/test.dart';
import 'package:taskflare/src/reporter/markdown_report_writer.dart';
import 'package:taskflare/taskflare.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late MarkdownReportWriter writer;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('taskflare_test_');
    writer = MarkdownReportWriter(reportsDirectory: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('MarkdownReportWriter', () {
    test('creates the reports directory when it does not exist', () async {
      final nested = '${tempDir.path}/nested/reports';
      final w = MarkdownReportWriter(reportsDirectory: nested);

      await w.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/project',
        startedAt: DateTime(2026, 4, 24, 14, 30, 0),
      );

      expect(Directory(nested).existsSync(), isTrue);
    });

    test('creates a file named with the timestamp', () async {
      await writer.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/project',
        startedAt: DateTime(2026, 4, 24, 14, 30, 5),
      );

      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.first.path, contains('taskflare-2026-04-24-143005'));
    });

    test('report contains the started date and command', () async {
      await writer.finish(
        summary: _summary(),
        command: 'flutter test',
        directory: '/my/project',
        startedAt: DateTime(2026, 4, 24, 9, 0, 0),
      );

      final content = _readReport(tempDir);
      expect(content, contains('2026-04-24'));
      expect(content, contains('flutter test'));
      expect(content, contains('/my/project'));
    });

    test('report includes test results grouped by group name', () async {
      writer.recordTest(_makeTest(leafName: 'should pass', groupName: 'Auth', result: TestResultKind.passed));
      writer.recordTest(_makeTest(leafName: 'should fail', groupName: 'Auth', result: TestResultKind.failed));
      writer.recordTest(_makeTest(leafName: 'ungrouped test', groupName: '', result: TestResultKind.passed));

      await writer.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('### Auth'));
      expect(content, contains('should pass'));
      expect(content, contains('should fail'));
      expect(content, contains('### (ungrouped)'));
      expect(content, contains('ungrouped test'));
    });

    test('report uses correct emoji for each result kind', () async {
      writer
        ..recordTest(_makeTest(leafName: 'p', groupName: '', result: TestResultKind.passed))
        ..recordTest(_makeTest(leafName: 'f', groupName: '', result: TestResultKind.failed))
        ..recordTest(_makeTest(leafName: 'e', groupName: '', result: TestResultKind.errored))
        ..recordTest(_makeTest(leafName: 's', groupName: '', result: TestResultKind.skipped));

      await writer.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('✅'));
      expect(content, contains('❌'));
      expect(content, contains('⚠️'));
      expect(content, contains('⏭'));
    });

    test('summary section is the first section after the header', () async {
      await writer.finish(
        summary: const RunSummary(
          outcome: TestOutcome.failure,
          passed: 10,
          failed: 2,
          skipped: 1,
          duration: Duration(milliseconds: 3500),
        ),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('## Summary'));
      expect(content.indexOf('## Summary'), lessThan(content.indexOf('## All tests')));
      expect(content, contains('FAILURE'));
      expect(content, contains('**Passed:** 10'));
      expect(content, contains('**Failed:** 2'));
      expect(content, contains('**Skipped:** 1'));
      expect(content, contains('3.5s'));
    });

    test('failed section appears before all tests and uses rich formatting', () async {
      writer.recordTest(_makeTest(
        leafName: 'my failing test',
        groupName: 'Group',
        result: TestResultKind.failed,
        fileRef: 'test/group_test.dart:10',
        duration: const Duration(milliseconds: 50),
      ),);

      await writer.finish(
        summary: const RunSummary(outcome: TestOutcome.failure, passed: 0, failed: 1, skipped: 0),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('## Failed tests'));
      expect(content, contains('my failing test'));
      expect(content, contains('test/group_test.dart:10'));
      expect(content, contains('❌'));
      expect(content.indexOf('## Failed tests'), lessThan(content.indexOf('## All tests')));
    });

    test('skipped section appears before all tests and uses rich formatting', () async {
      writer.recordTest(_makeTest(
        leafName: 'a skipped test',
        groupName: 'Group',
        result: TestResultKind.skipped,
        fileRef: 'test/group_test.dart:20',
      ),);

      await writer.finish(
        summary: const RunSummary(outcome: TestOutcome.success, passed: 0, failed: 0, skipped: 1),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('## Skipped tests'));
      expect(content, contains('a skipped test'));
      expect(content, contains('⏭'));
      expect(content.indexOf('## Skipped tests'), lessThan(content.indexOf('## All tests')));
    });

    test('failed and skipped sections are absent when there are none', () async {
      writer.recordTest(_makeTest(leafName: 'only passing', groupName: '', result: TestResultKind.passed));

      await writer.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, isNot(contains('## Failed tests')));
      expect(content, isNot(contains('## Skipped tests')));
    });

    test('includes file ref and duration as plain text when provided', () async {
      writer.recordTest(_makeTest(
        leafName: 'my test',
        groupName: 'Group',
        result: TestResultKind.passed,
        fileRef: 'test/my_test.dart:42',
        duration: const Duration(milliseconds: 120),
      ),);

      await writer.finish(
        summary: _summary(),
        command: 'dart test',
        directory: '/p',
        startedAt: DateTime(2026),
      );

      final content = _readReport(tempDir);
      expect(content, contains('test/my_test.dart:42'));
      expect(content, contains('0.12s'));
    });
  });
}

Test _makeTest({
  required String leafName,
  required String groupName,
  required TestResultKind result,
  String? fileRef,
  Duration? duration,
}) {
  final test = Test.fromStart(
    id: 0,
    rawName: groupName.isEmpty ? leafName : '$groupName $leafName',
    groupIds: groupName.isEmpty ? [0] : [0, 1],
    url: null,
    line: null,
    groupNames: {0: '', 1: groupName},
  );
  test.result = result;
  test.duration = duration;
  if (fileRef != null) {
    final colon = fileRef.lastIndexOf(':');
    final maybeLine = colon == -1 ? null : int.tryParse(fileRef.substring(colon + 1));
    if (maybeLine != null) {
      test.filePath = fileRef.substring(0, colon);
      test.line = maybeLine;
    } else {
      test.filePath = fileRef;
    }
  }
  return test;
}

RunSummary _summary() => const RunSummary(
      outcome: TestOutcome.success,
      passed: 1,
      failed: 0,
      skipped: 0,
    );

String _readReport(Directory dir) {
  return dir.listSync().whereType<File>().first.readAsStringSync();
}
