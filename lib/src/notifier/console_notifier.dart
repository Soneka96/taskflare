import '../entities/run_summary.dart';
import '../utils/enums.dart';
import 'notifier.dart';

class ConsoleNotifier implements Notifier {
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

    _printer('$label  passed: ${summary.passed}  '
        'failed: ${summary.failed}  skipped: ${summary.skipped}');

    if (summary.failedTestNames.isNotEmpty) {
      _printer('');
      for (final name in summary.failedTestNames) {
        _printer('  FAILED: $name');
      }
    }
  }
}
