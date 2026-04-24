import 'package:taskflare/taskflare.dart';

import 'notifier.dart';

/// A [Notifier] that delegates to multiple [Notifier] instances in sequence.
///
/// Useful for sending the same [RunSummary] to several notification channels.
class CompositeNotifier implements Notifier {
  /// Creates a [CompositeNotifier] that invokes each notifier in the given list in order.
  const CompositeNotifier(this._notifiers);

  final List<Notifier> _notifiers;

  @override
  Future<void> notify(RunSummary summary) async {
    for (final notifier in _notifiers) {
      await notifier.notify(summary);
    }
  }
}
