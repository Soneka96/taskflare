import 'package:taskflare/src/config/taskflare_config.dart';
import 'package:test/test.dart';

void main() {
  group('TaskflareConfig.fromJson()', () {
    group('new nested format', () {
      test('parses all fields from a complete JSON map', () {
        final config = TaskflareConfig.fromJson({
          'tests': {
            'report': {'enabled': false},
            'filter': {
              'showFailed': false,
              'showErrored': false,
              'showSkipped': false,
            },
          },
          'run': {
            'report': {'enabled': false},
          },
        });

        expect(config.testReportEnabled, isFalse);
        expect(config.showFailed, isFalse);
        expect(config.showErrored, isFalse);
        expect(config.showSkipped, isFalse);
        expect(config.runReportEnabled, isFalse);
      });

      test('falls back to defaults when nested blocks are missing', () {
        final config = TaskflareConfig.fromJson({'tests': {}, 'run': {}});

        expect(config.testReportEnabled, isTrue);
        expect(config.showFailed, isTrue);
        expect(config.showErrored, isTrue);
        expect(config.showSkipped, isTrue);
        expect(config.runReportEnabled, isTrue);
      });
    });

    group('legacy flat format', () {
      test('parses all fields from the old format', () {
        final config = TaskflareConfig.fromJson({
          'report': {'enabled': false},
          'filter': {
            'showFailed': false,
            'showErrored': false,
            'showSkipped': false,
          },
        });

        expect(config.testReportEnabled, isFalse);
        expect(config.showFailed, isFalse);
        expect(config.showErrored, isFalse);
        expect(config.showSkipped, isFalse);
        expect(config.runReportEnabled, isTrue);
      });

      test('falls back to defaults when fields are missing', () {
        final config = TaskflareConfig.fromJson({});

        expect(config.testReportEnabled, isTrue);
        expect(config.showFailed, isTrue);
        expect(config.showErrored, isTrue);
        expect(config.showSkipped, isTrue);
        expect(config.runReportEnabled, isTrue);
      });
    });
  });

  group('TaskflareConfig.toJson()', () {
    test('serialises to the new nested format', () {
      const config = TaskflareConfig(
        testReportEnabled: false,
        showFailed: true,
        showErrored: false,
        showSkipped: true,
        runReportEnabled: false,
      );

      final json = config.toJson();

      expect((json['tests'] as Map)['report'], {'enabled': false});
      expect((json['tests'] as Map)['filter'], {
        'showFailed': true,
        'showErrored': false,
        'showSkipped': true,
      });
      expect((json['run'] as Map)['report'], {'enabled': false});
    });

    test('round-trips through fromJson', () {
      const original = TaskflareConfig(
        testReportEnabled: false,
        showFailed: true,
        showErrored: false,
        showSkipped: true,
        runReportEnabled: false,
      );

      final roundTripped = TaskflareConfig.fromJson(original.toJson());

      expect(roundTripped.testReportEnabled, equals(original.testReportEnabled));
      expect(roundTripped.showFailed, equals(original.showFailed));
      expect(roundTripped.showErrored, equals(original.showErrored));
      expect(roundTripped.showSkipped, equals(original.showSkipped));
      expect(roundTripped.runReportEnabled, equals(original.runReportEnabled));
    });
  });

  group('TaskflareConfig.copyWith()', () {
    test('replaces only the specified fields', () {
      const base = TaskflareConfig(
        testReportEnabled: true,
        showFailed: true,
        showErrored: true,
        showSkipped: true,
        runReportEnabled: true,
      );

      final updated = base.copyWith(
        showSkipped: false,
        testReportEnabled: false,
        runReportEnabled: false,
      );

      expect(updated.testReportEnabled, isFalse);
      expect(updated.showFailed, isTrue);
      expect(updated.showErrored, isTrue);
      expect(updated.showSkipped, isFalse);
      expect(updated.runReportEnabled, isFalse);
    });
  });
}
