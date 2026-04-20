import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('JsonEventParser', () {
    final parser = JsonEventParser();

    test('returns crash when lines are empty', () {
      final result = parser.parse([], 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('returns crash when no JSON lines are present', () {
      final result = parser.parse(['not json', 'also not json'], 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('returns crash when done event is missing', () {
      const lines = [
        '{"type":"start","protocolVersion":"0.1.1"}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('returns success when all tests pass', () {
      final lines = _buildDoneLines(
        passed: 3,
        failed: 0,
        skipped: 0,
        success: true,
      );
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test('returns failure when at least one test fails', () {
      final lines = _buildDoneLines(
        passed: 2,
        failed: 1,
        skipped: 0,
        success: false,
      );
      final result = parser.parse(lines, 1);
      expect(result.outcome, equals(TestOutcome.failure));
    });

    test('returns crash when exit code is non-zero and no failures recorded', () {
      final lines = _buildDoneLines(
        passed: 0,
        failed: 0,
        skipped: 0,
        success: false,
      );
      final result = parser.parse(lines, 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('reports correct passed count', () {
      final lines = _buildDoneLines(
        passed: 7,
        failed: 0,
        skipped: 0,
        success: true,
      );
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(7));
    });

    test('reports correct failed count', () {
      final lines = _buildDoneLines(
        passed: 1,
        failed: 3,
        skipped: 0,
        success: false,
      );
      final result = parser.parse(lines, 1);
      expect(result.failed, equals(3));
    });

    test('reports correct skipped count', () {
      final lines = _buildDoneLines(
        passed: 2,
        failed: 0,
        skipped: 4,
        success: true,
      );
      final result = parser.parse(lines, 0);
      expect(result.skipped, equals(4));
    });

    test('ignores non-JSON lines mixed in with valid JSON', () {
      final lines = [
        'Observatory listening on http://127.0.0.1:0',
        '{"type":"start","protocolVersion":"0.1.1"}',
        'some stderr output',
        '{"type":"done","success":true,"passedCount":1,"failedCount":0,"skippedCount":0}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test('uses last done event when multiple are present', () {
      final lines = [
        '{"type":"done","success":false,"passedCount":0,"failedCount":1,"skippedCount":0}',
        '{"type":"done","success":true,"passedCount":5,"failedCount":0,"skippedCount":0}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
      expect(result.passed, equals(5));
    });

    test('returns zero counts when done event has no count fields', () {
      const lines = ['{"type":"done","success":true}'];
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(0));
      expect(result.failed, equals(0));
      expect(result.skipped, equals(0));
    });
  });
}

List<String> _buildDoneLines({
  required int passed,
  required int failed,
  required int skipped,
  required bool success,
}) {
  return [
    '{"type":"start","protocolVersion":"0.1.1"}',
    '{"type":"done","success":$success,"passedCount":$passed,"failedCount":$failed,"skippedCount":$skipped}',
  ];
}
