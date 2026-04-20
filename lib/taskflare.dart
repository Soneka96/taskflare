/// A Dart CLI tool that wraps `dart test` (or `flutter test`), parses the
/// JSON event stream, reports live progress in the terminal, and fires desktop
/// notifications on test failure and completion.
///
/// Typical programmatic usage:
/// ```dart
/// import 'package:taskflare/taskflare.dart';
/// ```
///
/// The two types re-exported here are the only ones needed to interpret
/// results: [TestOutcome] describes the overall verdict and [RunSummary]
/// carries all counts, failed test names, and optional timing/crash info.
library;

export 'src/entities/run_summary.dart';
export 'src/utils/enums.dart';
