import 'dart:io';

class ProjectDetector {
  const ProjectDetector();

  /// Returns true if the given directory contains a Flutter project
  /// (pubspec.yaml declares a dependency on flutter).
  bool isFlutterProject(String directory) {
    final pubspec = File('$directory${Platform.pathSeparator}pubspec.yaml');
    if (!pubspec.existsSync()) {
      return false;
    }

    final content = pubspec.readAsStringSync();
    return RegExp(r'^\s+flutter:', multiLine: true).hasMatch(content);
  }
}
