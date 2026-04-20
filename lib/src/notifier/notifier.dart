import '../entities/run_summary.dart';

abstract class Notifier {
  void notify(RunSummary summary);
}
