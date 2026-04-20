import 'package:taskflare/src/entities/run_summary.dart';
import 'package:taskflare/src/notifier/composite_notifier.dart';
import 'package:taskflare/src/notifier/notifier.dart';
import 'package:taskflare/src/utils/enums.dart';
import 'package:test/test.dart';

void main() {
  group('Method notify() calls all notifiers', () {
    test('Method notify() calls every notifier in the list', () async {
      final a = _FakeNotifier();
      final b = _FakeNotifier();
      final composite = CompositeNotifier([a, b]);

      await composite.notify(_summary());

      expect(a.callCount, equals(1));
      expect(b.callCount, equals(1));
    });

    test('Method notify() passes the same summary to every notifier', () async {
      final a = _FakeNotifier();
      final b = _FakeNotifier();
      final composite = CompositeNotifier([a, b]);
      final summary = _summary();

      await composite.notify(summary);

      expect(a.received, equals(summary));
      expect(b.received, equals(summary));
    });

    test('Method notify() calls notifiers in order', () async {
      final order = <int>[];
      final composite = CompositeNotifier([
        _OrderedFakeNotifier(id: 1, order: order),
        _OrderedFakeNotifier(id: 2, order: order),
        _OrderedFakeNotifier(id: 3, order: order),
      ]);

      await composite.notify(_summary());

      expect(order, equals([1, 2, 3]));
    });

    test('Method notify() works correctly with a single notifier', () async {
      final notifier = _FakeNotifier();
      final composite = CompositeNotifier([notifier]);

      await composite.notify(_summary());

      expect(notifier.callCount, equals(1));
    });

    test('Method notify() works correctly with an empty notifier list',
        () async {
      final composite = CompositeNotifier([]);
      await expectLater(composite.notify(_summary()), completes);
    });
  });
}

RunSummary _summary() => const RunSummary(
      outcome: TestOutcome.success,
      passed: 1,
      failed: 0,
      skipped: 0,
    );

class _FakeNotifier implements Notifier {
  RunSummary? received;
  int callCount = 0;

  @override
  Future<void> notify(RunSummary summary) async {
    received = summary;
    callCount++;
  }
}

class _OrderedFakeNotifier implements Notifier {
  _OrderedFakeNotifier({required this.id, required this.order});

  final int id;
  final List<int> order;

  @override
  Future<void> notify(RunSummary summary) async {
    order.add(id);
  }
}
