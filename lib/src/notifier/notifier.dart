import 'package:taskflare/taskflare.dart';

/// Contract for components that report the final outcome of a test run.
abstract class Notifier {
  /// Called once when the test run completes with the [summary] of results.
  Future<void> notify(RunSummary summary);
}
