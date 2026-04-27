import 'dart:convert';
import 'dart:io';

/// Persisted user preferences for Taskflare.
///
/// Loaded from the platform config file on startup and written back by
/// the `taskflare config` interactive menu.
class TaskflareConfig {
  /// Creates a [TaskflareConfig] with the given settings.
  const TaskflareConfig({
    this.testReportEnabled = true,
    this.showFailed = true,
    this.showErrored = true,
    this.showSkipped = true,
    this.runReportEnabled = true,
  });

  /// Whether to generate a markdown report in `taskflare-reports/` after each `taskflare test` run.
  final bool testReportEnabled;

  /// Whether to print a permanent FAIL line in the terminal when a test fails.
  final bool showFailed;

  /// Whether to print a permanent THROW line in the terminal when a test errors.
  final bool showErrored;

  /// Whether to print a permanent SKIP line in the terminal when a test is skipped.
  final bool showSkipped;

  /// Whether to generate a markdown report in `taskflare-reports/` after each `taskflare run` invocation.
  final bool runReportEnabled;

  /// Deserialises a [TaskflareConfig] from a JSON map.
  ///
  /// Supports both the current nested format (`tests` / `run` keys) and the
  /// legacy flat format (`report` / `filter` keys) so older config files remain valid.
  factory TaskflareConfig.fromJson(Map<String, dynamic> json) {
    final testsBlock = (json['tests'] as Map?)?.cast<String, dynamic>();
    final runBlock = (json['run'] as Map?)?.cast<String, dynamic>();

    if (testsBlock != null || runBlock != null) {
      final report = (testsBlock?['report'] as Map?)?.cast<String, dynamic>() ?? {};
      final filter = (testsBlock?['filter'] as Map?)?.cast<String, dynamic>() ?? {};
      final runReport = (runBlock?['report'] as Map?)?.cast<String, dynamic>() ?? {};
      return TaskflareConfig(
        testReportEnabled: report['enabled'] as bool? ?? true,
        showFailed: filter['showFailed'] as bool? ?? true,
        showErrored: filter['showErrored'] as bool? ?? true,
        showSkipped: filter['showSkipped'] as bool? ?? true,
        runReportEnabled: runReport['enabled'] as bool? ?? true,
      );
    }

    // Legacy format.
    final report = (json['report'] as Map?)?.cast<String, dynamic>() ?? {};
    final filter = (json['filter'] as Map?)?.cast<String, dynamic>() ?? {};
    return TaskflareConfig(
      testReportEnabled: report['enabled'] as bool? ?? true,
      showFailed: filter['showFailed'] as bool? ?? true,
      showErrored: filter['showErrored'] as bool? ?? true,
      showSkipped: filter['showSkipped'] as bool? ?? true,
    );
  }

  /// Serialises this config to a JSON map.
  Map<String, dynamic> toJson() => {
        'tests': {
          'report': {'enabled': testReportEnabled},
          'filter': {
            'showFailed': showFailed,
            'showErrored': showErrored,
            'showSkipped': showSkipped,
          },
        },
        'run': {
          'report': {'enabled': runReportEnabled},
        },
      };

  /// Returns a copy of this config with the given fields replaced.
  TaskflareConfig copyWith({
    bool? testReportEnabled,
    bool? showFailed,
    bool? showErrored,
    bool? showSkipped,
    bool? runReportEnabled,
  }) {
    return TaskflareConfig(
      testReportEnabled: testReportEnabled ?? this.testReportEnabled,
      showFailed: showFailed ?? this.showFailed,
      showErrored: showErrored ?? this.showErrored,
      showSkipped: showSkipped ?? this.showSkipped,
      runReportEnabled: runReportEnabled ?? this.runReportEnabled,
    );
  }

  /// Loads configuration from the platform config file.
  ///
  /// Returns defaults if the file does not exist or cannot be parsed.
  static Future<TaskflareConfig> load() async {
    final file = _configFile;
    if (!file.existsSync()) {
      return const TaskflareConfig();
    }
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return TaskflareConfig.fromJson(json);
    } catch (_) {
      return const TaskflareConfig();
    }
  }

  /// Saves this configuration to the platform config file, creating the
  /// directory if necessary.
  Future<void> save() async {
    final file = _configFile;
    await file.parent.create(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(toJson()),
    );
  }

  /// The platform-specific config file location.
  ///
  /// Windows: `%APPDATA%\Taskflare\config.json`
  /// Others:  `~/.config/taskflare/config.json`
  static File get _configFile {
    if (Platform.isWindows) {
      final base = Platform.environment['APPDATA'] ??
          '${Platform.environment['USERPROFILE']}\\AppData\\Roaming';
      return File('$base\\Taskflare\\config.json');
    }
    final home = Platform.environment['HOME'] ?? '';
    return File('$home/.config/taskflare/config.json');
  }
}
