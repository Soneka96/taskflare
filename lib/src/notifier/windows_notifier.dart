import 'dart:io';

import 'package:taskflare/src/notifier/windows_initializer.dart';
import 'package:taskflare/taskflare.dart';

import 'notifier.dart';

/// A function type that runs a system process and returns its result.
///
/// Matches the signature of [Process.run], used to make [WindowsNotifier] testable
/// without spawning a real PowerShell process.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

/// A [Notifier] that sends Windows toast notifications for test run results.
///
/// Uses PowerShell to invoke the WinRT toast notification API. Requires
/// [WindowsInitializer.ensureRegistered] to be called once on startup so
/// the correct app name and icon are shown.
class WindowsNotifier implements Notifier {
  /// Creates a [WindowsNotifier].
  ///
  /// [appId] is the Windows Application User Model ID used to identify the
  /// notification source. Defaults to [WindowsInitializer.appId].
  /// [processRunner] is used to spawn PowerShell; defaults to [Process.run].
  WindowsNotifier({
    String appId = WindowsInitializer.appId,
    ProcessRunner? processRunner,
  })  : _appId = appId,
        _processRunner = processRunner ?? Process.run;

  final String _appId;
  final ProcessRunner _processRunner;

  /// Sends a toast notification summarising the completed test run.
  @override
  Future<void> notify(RunSummary summary) async {
    final outcome = switch (summary.outcome) {
      TestOutcome.success => 'SUCCESS',
      TestOutcome.failure => 'FAILURE',
      TestOutcome.crash => 'CRASH',
    };

    final body = '$outcome  passed: ${summary.passed}  '
        'failed: ${summary.failed}  '
        'skipped: ${summary.skipped}';

    await _sendToast(title: 'End of tests', body: body);
  }

  /// Sends a toast notification for a single failed test identified by [testName].
  Future<void> notifyTestFailed(String testName) async {
    await _sendToast(title: testName, body: 'Test failed');
  }

  /// Sends a toast notification with the given [title] and [body] via PowerShell.
  ///
  /// Throws a [ProcessException] if PowerShell exits with a non-zero code.
  Future<void> _sendToast({
    required String title,
    required String body,
  }) async {
    final escapedAppId = _escapePowerShellString(_appId);
    final escapedTitle = _escapeXml(title);
    final escapedBody = _escapeXml(body);
    final script = '''
\$ErrorActionPreference = 'Stop'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

\$template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$escapedTitle</text>
      <text>$escapedBody</text>
    </binding>
  </visual>
</toast>
"@

\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)

\$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('$escapedAppId').Show(\$toast)
''';

    final result =
        await _processRunner('powershell', ['-NoProfile', '-Command', script]);

    if (result.exitCode != 0) {
      throw ProcessException(
        'powershell',
        ['-NoProfile', '-Command', script],
        'Toast notification failed: ${result.stderr}',
        result.exitCode,
      );
    }
  }

  /// Escapes [value] for safe embedding in an XML element or attribute.
  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Escapes [value] for safe embedding in a single-quoted PowerShell string.
  String _escapePowerShellString(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}
