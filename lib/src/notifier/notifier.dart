import '../entities/run_summary.dart';

abstract class Notifier {
  Future<void> notify(RunSummary summary);
}
