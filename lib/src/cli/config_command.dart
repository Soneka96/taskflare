import '../config/taskflare_config.dart';
import 'terminal.dart';

/// Interactive configuration menu.
///
/// Loads the current config, lets the user toggle settings per command type,
/// and saves on quit. Uses [term] for all screen I/O.
Future<void> runConfigCommand(TerminalSession term) async {
  var config = await TaskflareConfig.load();
  while (true) {
    term.clear();
    _printMainMenu(term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = await _testsMenu(config, term);
      case '2':
        config = await _runMenu(config, term);
      case 'q':
        await config.save();
        return;
    }
  }
}

void _printMainMenu(TerminalSession s) {
  s.writeln();
  s.writeln('  Taskflare configuration');
  s.writeln();
  s.writeln('  1) Tests');
  s.writeln('  2) Run');
  s.writeln('  q) Save and quit');
  s.writeln();
  s.write('Choose: ');
}

// ── Tests ────────────────────────────────────────────────────────────────────

Future<TaskflareConfig> _testsMenu(
  TaskflareConfig config,
  TerminalSession term,
) async {
  while (true) {
    term.clear();
    _printTestsMenu(config, term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(showFailed: !config.showFailed);
      case '2':
        config = config.copyWith(showErrored: !config.showErrored);
      case '3':
        config = config.copyWith(showSkipped: !config.showSkipped);
      case '4':
        config = config.copyWith(testReportEnabled: !config.testReportEnabled);
      case 'b':
        return config;
    }
  }
}

void _printTestsMenu(TaskflareConfig config, TerminalSession s) {
  s.writeln();
  s.writeln('  Tests');
  s.writeln();
  s.writeln('  Terminal output — permanent lines shown during a test run:');
  s.writeln('  1) Failed tests      ${_toggle(config.showFailed)}');
  s.writeln('  2) Errored tests     ${_toggle(config.showErrored)}');
  s.writeln('  3) Skipped tests     ${_toggle(config.showSkipped)}');
  s.writeln();
  s.writeln('  Report file — written to taskflare-reports/ after each run:');
  s.writeln('  4) Generate report   ${_toggle(config.testReportEnabled)}');
  s.writeln();
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose number to toggle: ');
}

// ── Run ──────────────────────────────────────────────────────────────────────

Future<TaskflareConfig> _runMenu(
  TaskflareConfig config,
  TerminalSession term,
) async {
  while (true) {
    term.clear();
    _printRunMenu(config, term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(runReportEnabled: !config.runReportEnabled);
      case 'b':
        return config;
    }
  }
}

void _printRunMenu(TaskflareConfig config, TerminalSession s) {
  s.writeln();
  s.writeln('  Run');
  s.writeln();
  s.writeln('  Report file — written to taskflare-reports/ after each run:');
  s.writeln('  1) Generate report   ${_toggle(config.runReportEnabled)}');
  s.writeln();
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose number to toggle: ');
}

String _toggle(bool value) => value ? '[ON ]' : '[OFF]';
