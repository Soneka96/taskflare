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
  String get commandLabel {
    return 'taskflare test';
  }

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
