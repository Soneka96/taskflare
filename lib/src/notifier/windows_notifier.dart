import 'dart:io';

import 'package:taskflare/taskflare.dart';

import 'notifier.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class WindowsNotifier implements Notifier {
  WindowsNotifier({
    String appId = 'Taskflare.App',
    ProcessRunner? processRunner,
  })  : _appId = appId,
        _processRunner = processRunner ?? Process.run;

  final String _appId;
  final ProcessRunner _processRunner;

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

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _escapePowerShellString(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
}
