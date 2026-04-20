import '../entities/run_summary.dart';
import 'notifier.dart';

class CompositeNotifier implements Notifier {
  const CompositeNotifier(this._notifiers);

  final List<Notifier> _notifiers;

  @override
  Future<void> notify(RunSummary summary) async {
    for (final notifier in _notifiers) {
      await notifier.notify(summary);
    }
  }
}
