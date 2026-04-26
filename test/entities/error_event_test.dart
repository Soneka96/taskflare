import 'package:taskflare/src/entities/error_event.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorEvent.isExpectFailure', () {
    test('true when isFailure flag is set', () {
      final e = ErrorEvent(testId: 1, isFailure: true, error: 'some error');
      expect(e.isExpectFailure, isTrue);
    });

    test('true when error message starts with TestFailure (', () {
      final e = ErrorEvent(
        testId: 1,
        isFailure: false,
        error: 'TestFailure (Expected: exactly one matching candidate\n  Actual: ...)',
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
