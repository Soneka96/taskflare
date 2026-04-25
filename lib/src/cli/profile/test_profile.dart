import '../../runner/command_runner.dart';
import '../../runner/dart_test_runner.dart';
import '../../runner/flutter_test_runner.dart';
import '../../utils/project_detector.dart';
import 'command_profile.dart';

/// A [CommandProfile] that wraps `dart test` or `flutter test`,
/// auto-detecting the project type via [ProjectDetector].
class TestProfile extends CommandProfile {
  /// Creates a [TestProfile].
  ///
  /// [detector] defaults to [ProjectDetector] and can be overridden for testing.
  const TestProfile({
    this.detector = const ProjectDetector(),
  });

  /// Used to determine whether to invoke `dart test` or `flutter test`.
  final ProjectDetector detector;

  @override
  String get name => 'test';

  @override
  String get description => 'Run dart test or flutter test (auto-detected)';

  @override
  String get commandLabel => 'taskflare test';

  @override
  String get helpText => '''
  Runs your test suite using `dart test` or `flutter test`,
  auto-detected from the presence of a Flutter SDK dependency
  in pubspec.yaml.

  Usage:
    taskflare test                Run all tests
    taskflare test --name "foo"   Run tests matching a name
    taskflare test test/parser/   Run tests in a specific folder

  Output lines (permanent, stay visible after the run):
    FAIL  — assertion error (expect failed)
    THROW — uncaught exception
    SKIP  — test was skipped

  File references are printed as path/to/file.dart:line.
  Ctrl+click in most terminals and IDEs to jump directly to the test.

  Outcomes:
    [SUCCESS] — all tests passed
    [FAILURE] — at least one test failed or errored
    [CRASH]   — process exited before completing''';


  /// Returns a [DartTestRunner] or [FlutterTestRunner] based on whether
  /// [workingDirectory] contains a Flutter project.
  @override
  CommandRunner buildRunner(List<String> arguments, String workingDirectory) {
    final isFlutter = detector.isFlutterProject(workingDirectory);
    if (isFlutter) {
      return FlutterTestRunner(
        arguments: arguments,
        workingDirectory: workingDirectory,
      );
    }
    return DartTestRunner(
      arguments: arguments,
      workingDirectory: workingDirectory,
    );
  }

  /// Returns `'dart test'` or `'flutter test'` based on the project type.
  String resolveCommandLabel(String workingDirectory) {
    final isFlutter = detector.isFlutterProject(workingDirectory);
    return isFlutter ? 'flutter test' : 'dart test';
  }
}
