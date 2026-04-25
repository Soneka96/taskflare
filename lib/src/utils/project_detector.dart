import 'dart:io';

/// Detects the type of Dart project in a given directory by inspecting its `pubspec.yaml`.
class ProjectDetector {
  const ProjectDetector();

  /// Returns `true` if [directory] contains a Flutter project.
  ///
  /// Checks for an indented `flutter:` key in `pubspec.yaml`, which is how
  /// Flutter declares its SDK dependency. Returns `false` when the file is
  /// absent or contains no such key.
  bool isFlutterProject(String directory) {
    final pubspec = File('$directory${Platform.pathSeparator}pubspec.yaml');
    if (!pubspec.existsSync()) {
      return false;
    }

    final content = pubspec.readAsStringSync();
    return RegExp(r'^\s+flutter:', multiLine: true).hasMatch(content);
  }
}
