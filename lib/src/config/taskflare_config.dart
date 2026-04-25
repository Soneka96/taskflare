import 'dart:convert';
import 'dart:io';

/// Persisted user preferences for Taskflare.
///
/// Loaded from the platform config file on startup and written back by
/// the `taskflare config` interactive menu.
class TaskflareConfig {
  /// Creates a [TaskflareConfig] with the given settings.
  ///
  /// All fields default to their recommended out-of-the-box values.
  const TaskflareConfig({
    this.reportEnabled = true,
    this.showFailed = true,
    this.showErrored = true,
    this.showSkipped = true,
  });

  /// Deserialises a [TaskflareConfig] from a JSON map.
  ///
  /// Missing fields fall back to their defaults, so older config files remain valid.
  factory TaskflareConfig.fromJson(Map<String, dynamic> json) {
    final report = (json['report'] as Map?)?.cast<String, dynamic>() ?? {};
    final filter = (json['filter'] as Map?)?.cast<String, dynamic>() ?? {};
    return TaskflareConfig(
      reportEnabled: report['enabled'] as bool? ?? true,
      showFailed: filter['showFailed'] as bool? ?? true,
      showErrored: filter['showErrored'] as bool? ?? true,
      showSkipped: filter['showSkipped'] as bool? ?? true,
    );
  }

  /// Whether to generate a markdown report file in `taskflare-reports/` after each run.
  final bool reportEnabled;

  /// Whether to print a permanent FAIL line in the terminal when a test fails (assertion error).
  final bool showFailed;

  /// Whether to print a permanent THROW line in the terminal when a test errors (uncaught exception).
  final bool showErrored;

  /// Whether to print a permanent SKIP line in the terminal when a test is skipped.
  final bool showSkipped;

  /// Serialises this config to a JSON map.
  Map<String, dynamic> toJson() => {
        'report': {'enabled': reportEnabled},
        'filter': {
          'showFailed': showFailed,
          'showErrored': showErrored,
          'showSkipped': showSkipped,
        },
      };

  /// Returns a copy of this config with the given fields replaced.
  TaskflareConfig copyWith({
    bool? reportEnabled,
    bool? showFailed,
    bool? showErrored,
    bool? showSkipped,
  }) {
    return TaskflareConfig(
      reportEnabled: reportEnabled ?? this.reportEnabled,
      showFailed: showFailed ?? this.showFailed,
      showErrored: showErrored ?? this.showErrored,
      showSkipped: showSkipped ?? this.showSkipped,
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
