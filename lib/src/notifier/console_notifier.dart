import 'package:taskflare/taskflare.dart';

import 'notifier.dart';

/// A [Notifier] that prints the run outcome to stdout.
class ConsoleNotifier implements Notifier {
  /// Creates a [ConsoleNotifier].
  ///
  /// [printer] defaults to [print] when omitted, and can be overridden for testing.
  const ConsoleNotifier({void Function(String)? printer})
      : _printer = printer ?? print;

  final void Function(String) _printer;

  @override
  Future<void> notify(RunSummary summary) async {
    final label = switch (summary.outcome) {
      TestOutcome.success => '[SUCCESS]',
      TestOutcome.failure => '[FAILURE]',
      TestOutcome.crash => '[CRASH]  ',
    };

    final durationSuffix = summary.duration != null
        ? '  (${(summary.duration!.inMilliseconds / 1000).toStringAsFixed(1)}s)'
        : '';

    _printer('$label  passed: ${summary.passed}  '
        'failed: ${summary.failed}  skipped: ${summary.skipped}$durationSuffix');

    if (summary.crashOutput != null && summary.crashOutput!.isNotEmpty) {
      _printer('');
      _printer('  ERROR OUTPUT:');
      for (final line in summary.crashOutput!.split('\n')) {
        _printer('  $line');
      }
    }
  }
}
