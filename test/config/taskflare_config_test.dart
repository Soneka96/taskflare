import 'package:taskflare/src/config/taskflare_config.dart';
import 'package:test/test.dart';

void main() {
  group('TaskflareConfig.fromJson()', () {
    test('parses all fields from a complete JSON map', () {
      final config = TaskflareConfig.fromJson({
        'report': {'enabled': false},
        'filter': {
          'showFailed': false,
          'showErrored': false,
          'showSkipped': false,
        },
      });

      expect(config.reportEnabled, isFalse);
      expect(config.showFailed, isFalse);
      expect(config.showErrored, isFalse);
      expect(config.showSkipped, isFalse);
    });

    test('falls back to defaults when fields are missing', () {
      final config = TaskflareConfig.fromJson({});

      expect(config.reportEnabled, isTrue);
      expect(config.showFailed, isTrue);
      expect(config.showErrored, isTrue);
      expect(config.showSkipped, isTrue);
    });

    test('falls back to defaults when nested maps are missing', () {
      final config = TaskflareConfig.fromJson({'report': {}, 'filter': {}});

      expect(config.reportEnabled, isTrue);
      expect(config.showFailed, isTrue);
    });
  });

  group('TaskflareConfig.toJson()', () {
    test('round-trips through fromJson', () {
      const original = TaskflareConfig(
        reportEnabled: false,
        showFailed: true,
        showErrored: false,
        showSkipped: true,
      );

      final roundTripped = TaskflareConfig.fromJson(original.toJson());

      expect(roundTripped.reportEnabled, equals(original.reportEnabled));
      expect(roundTripped.showFailed, equals(original.showFailed));
      expect(roundTripped.showErrored, equals(original.showErrored));
      expect(roundTripped.showSkipped, equals(original.showSkipped));
    });
  });

  group('TaskflareConfig.copyWith()', () {
    test('replaces only the specified fields', () {
      const base = TaskflareConfig(
        reportEnabled: true,
        showFailed: true,
        showErrored: true,
        showSkipped: true,
      );

      final updated = base.copyWith(showSkipped: false, reportEnabled: false);

      expect(updated.reportEnabled, isFalse);
      expect(updated.showFailed, isTrue);
      expect(updated.showErrored, isTrue);
      expect(updated.showSkipped, isFalse);
    });
  });
}
