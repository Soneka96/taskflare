import '../entities/run_summary.dart';
import 'test_record.dart';

/// Contract for components that produce a persistent report of a test run.
///
/// Called by [Taskflare] during the run to buffer individual test results,
/// then [finish] is called once with the final [RunSummary].
abstract class ReportWriter {
  /// Buffers a completed test for inclusion in the report.
  void recordTest(TestRecord record);

  /// Writes the report to its destination.
  ///
  /// [command] is the command string shown in the report header.
  /// [directory] is the working directory where tests were run.
  /// [startedAt] is the wall-clock time the run began.
  Future<void> finish({
    required RunSummary summary,
    required String command,
    required String directory,
    required DateTime startedAt,
  });
}
