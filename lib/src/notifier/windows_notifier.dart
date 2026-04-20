import 'dart:io';

import '../entities/run_summary.dart';
import '../utils/enums.dart';
import 'notifier.dart';

typedef _ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

class WindowsNotifier implements Notifier {
  WindowsNotifier({
    String appId = 'taskflare',
    _ProcessRunner? processRunner,
  })  : _appId = appId,
        _processRunner = processRunner ?? Process.run;

  final String _appId;
  final _ProcessRunner _processRunner;

  @override
  Future<void> notify(RunSummary summary) async {
    final title = switch (summary.outcome) {
      TestOutcome.success => 'SUCCESS',
      TestOutcome.failure => 'FAILURE',
      TestOutcome.crash => 'CRASH',
    };

    final body = 'passed: ${summary.passed}  '
        'failed: ${summary.failed}  '
        'skipped: ${summary.skipped}';

    await _sendToast(title: title, body: body);
  }

  Future<void> _sendToast({
    required String title,
    required String body,
  }) async {
    final escapedTitle = title.replaceAll("'", "\\'");
    final escapedBody = body.replaceAll("'", "\\'");
    final escapedAppId = _appId.replaceAll("'", "\\'");

    final script = '''
\$ErrorActionPreference = 'Stop'
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null
\$template = '<toast><visual><binding template="ToastGeneric"><text>$escapedTitle</text><text>$escapedBody</text></binding></visual></toast>'
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml(\$template)
\$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('$escapedAppId').Show(\$toast)
''';

    await _processRunner('powershell', ['-NoProfile', '-Command', script]);
  }
}
