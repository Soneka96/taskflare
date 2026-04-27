import 'dart:io';

/// Writes a simple markdown report for a `taskflare run` invocation.
///
/// Contains the command, directory, timing, exit code, and captured output.
class ShellReportWriter {
  /// Creates a [ShellReportWriter] that writes files into [reportsDirectory].
  ShellReportWriter({required this.reportsDirectory});

  /// Absolute path to the directory where report files are written.
  final String reportsDirectory;

  /// Writes the report file and returns the path it was written to.
  Future<String> write({
    required String command,
    required String directory,
    required DateTime startedAt,
    required Duration duration,
    required int exitCode,
    required List<String> output,
  }) async {
    await Directory(reportsDirectory).create(recursive: true);
    final filename = 'taskflare-run-${_timestamp(startedAt)}.md';
    final file = File('$reportsDirectory${Platform.pathSeparator}$filename');
    file.writeAsStringSync(
      _build(
        command: command,
        directory: directory,
        startedAt: startedAt,
        duration: duration,
        exitCode: exitCode,
        output: output,
      ),
    );
    return file.path;
  }

  String _build({
    required String command,
    required String directory,
    required DateTime startedAt,
    required Duration duration,
    required int exitCode,
    required List<String> output,
  }) {
    final buf = StringBuffer();
    final secs = (duration.inMilliseconds / 1000).toStringAsFixed(1);
    final outcome = exitCode == 0 ? 'SUCCESS' : 'FAILURE';

    buf.writeln('# Taskflare Run');
    buf.writeln();
    buf.writeln('**Started:** ${_datetime(startedAt)}  ');
    buf.writeln('**Command:** `$command`  ');
    buf.writeln('**Directory:** `$directory`');
    buf.writeln();
    buf.writeln('---');
    buf.writeln();
    buf.writeln('## Summary');
    buf.writeln();
    buf.writeln('- **Outcome:** $outcome');
    buf.writeln('- **Exit code:** $exitCode');
    buf.writeln('- **Duration:** ${secs}s');
    buf.writeln();

    if (output.isNotEmpty) {
      buf.writeln('---');
      buf.writeln();
      buf.writeln('## Output');
      buf.writeln();
      buf.writeln('```');
      for (final line in output) {
        buf.writeln(line);
      }
      buf.writeln('```');
    }

    return buf.toString();
  }

  String _timestamp(DateTime dt) {
    return '${_p(dt.year, 4)}-${_p(dt.month)}-${_p(dt.day)}'
        '-${_p(dt.hour)}${_p(dt.minute)}${_p(dt.second)}';
  }

  String _datetime(DateTime dt) {
    return '${_p(dt.year, 4)}-${_p(dt.month)}-${_p(dt.day)} '
        '${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
  }

  String _p(int value, [int width = 2]) => value.toString().padLeft(width, '0');
}
