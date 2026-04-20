import 'package:taskflare/src/parser/json_event_parser.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  late JsonEventParser parser;

  setUp(() {
    parser = JsonEventParser();
  });

  group('Method parse() returns the correct outcome', () {
    test('Method parse() returns crash when lines are empty', () {
      final result = parser.parse([], 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('Method parse() returns crash when no JSON lines are present', () {
      final result = parser.parse(['not json', 'also not json'], 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('Method parse() returns crash when done event is missing', () {
      const lines = ['{"type":"start","protocolVersion":"0.1.1"}'];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test('Method parse() returns success when done reports success', () {
      final lines = [
        ..._testDoneLines(passed: 3, failed: 0, skipped: 0),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test(
        'Method parse() returns failure when done reports failure and failed count is positive',
        () {
      final lines = [
        ..._testDoneLines(passed: 2, failed: 1, skipped: 0),
        '{"type":"done","success":false}',
      ];
      final result = parser.parse(lines, 1);
      expect(result.outcome, equals(TestOutcome.failure));
    });

    test(
        'Method parse() returns crash when done reports failure and no failed tests are counted',
        () {
      const lines = ['{"type":"done","success":false}'];
      final result = parser.parse(lines, 1);
      expect(result.outcome, equals(TestOutcome.crash));
    });

    test(
        'Method parse() returns success when done reports success despite non-JSON lines',
        () {
      final lines = [
        'Observatory listening on http://127.0.0.1:0',
        '{"type":"start","protocolVersion":"0.1.1"}',
        'some stderr output',
        ..._testDoneLines(passed: 1, failed: 0, skipped: 0),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
    });

    test('Method parse() uses last done event when multiple are present', () {
      final lines = [
        '{"type":"done","success":false}',
        ..._testDoneLines(passed: 5, failed: 0, skipped: 0),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.outcome, equals(TestOutcome.success));
    });
  });

  group('Method parse() returns the correct counts', () {
    test('Method parse() reports correct passed count from testDone events', () {
      final lines = [
        ..._testDoneLines(passed: 7, failed: 0, skipped: 0),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(7));
    });

    test('Method parse() reports correct failed count from testDone events', () {
      final lines = [
        ..._testDoneLines(passed: 1, failed: 3, skipped: 0),
        '{"type":"done","success":false}',
      ];
      final result = parser.parse(lines, 1);
      expect(result.failed, equals(3));
    });

    test('Method parse() reports correct skipped count from testDone events',
        () {
      final lines = [
        ..._testDoneLines(passed: 2, failed: 0, skipped: 4),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.skipped, equals(4));
    });

    test('Method parse() ignores hidden testDone events in counts', () {
      final lines = [
        '{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone"}',
        '{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(1));
    });

    test(
        'Method parse() returns zero counts when no testDone events are present',
        () {
      const lines = ['{"type":"done","success":true}'];
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(0));
      expect(result.failed, equals(0));
      expect(result.skipped, equals(0));
    });

    test(
        'Method parse() uses last done event counts when multiple done events are present',
        () {
      final lines = [
        '{"type":"done","success":false}',
        ..._testDoneLines(passed: 5, failed: 0, skipped: 0),
        '{"type":"done","success":true}',
      ];
      final result = parser.parse(lines, 0);
      expect(result.passed, equals(5));
    });
  });
}

List<String> _testDoneLines({
  required int passed,
  required int failed,
  required int skipped,
}) {
  var id = 0;
  final lines = <String>[];

  for (var i = 0; i < passed; i++) {
    lines.add(
      '{"testID":${id++},"result":"success","skipped":false,"hidden":false,"type":"testDone"}',
    );
  }
  for (var i = 0; i < failed; i++) {
    lines.add(
      '{"testID":${id++},"result":"failure","skipped":false,"hidden":false,"type":"testDone"}',
    );
  }
  for (var i = 0; i < skipped; i++) {
    lines.add(
      '{"testID":${id++},"result":"success","skipped":true,"hidden":false,"type":"testDone"}',
    );
  }

  return lines;
}
