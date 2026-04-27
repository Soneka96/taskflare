import 'package:taskflare/src/entities/error_event.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorEvent.isExpectFailure', () {
    test('true when isFailure flag is set', () {
      final e = ErrorEvent(testId: 1, isFailure: true, error: 'some error');
      expect(e.isExpectFailure, isTrue);
    });

    test('true when error message contains TestFailure', () {
      final e = ErrorEvent(
        testId: 1,
        isFailure: false,
        error: 'The following TestFailure was thrown running a test:\nExpected: exactly one matching candidate\n  Actual: ...',
      );
      expect(e.isExpectFailure, isTrue);
    });

    test('true when error message starts with Expected:', () {
      final e = ErrorEvent(
        testId: 1,
        isFailure: false,
        error: 'Expected: <true>\n  Actual: <false>',
      );
      expect(e.isExpectFailure, isTrue);
    });

    test('true when error message starts with "Test failed." (Flutter form)', () {
      final e = ErrorEvent(
        testId: 1,
        isFailure: false,
        error: 'Test failed. See exception logs above.\nThe test description was: my test',
      );
      expect(e.isExpectFailure, isTrue);
    });

    test('false for a genuine uncaught exception', () {
      final e = ErrorEvent(
        testId: 1,
        isFailure: false,
        error: 'Null check operator used on a null value',
      );
      expect(e.isExpectFailure, isFalse);
    });
  });

  group('ErrorEvent.fromJson()', () {
    test('parses testID, isFailure, and error fields', () {
      final e = ErrorEvent.fromJson({
        'type': 'error',
        'testID': 42,
        'isFailure': true,
        'error': 'TestFailure (Expected: 1, Actual: 2)',
        'stackTrace': '',
      });

      expect(e.testId, 42);
      expect(e.isFailure, isTrue);
      expect(e.error, 'TestFailure (Expected: 1, Actual: 2)');
    });

    test('defaults error to empty string when absent', () {
      final e = ErrorEvent.fromJson({'type': 'error', 'testID': 1});
      expect(e.error, isEmpty);
      expect(e.isFailure, isFalse);
    });
  });
}
