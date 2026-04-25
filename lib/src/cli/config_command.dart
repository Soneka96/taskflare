import '../config/taskflare_config.dart';
import 'terminal.dart';

/// Interactive configuration menu.
///
/// Loads the current config, lets the user toggle filter and report settings,
/// and saves on quit. Uses [term] for all screen I/O.
Future<void> runConfigCommand(TerminalSession term) async {
  var config = await TaskflareConfig.load();
  while (true) {
    term.clear();
    _printMainMenu(config, term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = _filterMenu(config, term);
      case '2':
        config = _reportMenu(config, term);
      case 'q':
        await config.save();
        return;
    }
  }
}

void _printMainMenu(TaskflareConfig config, TerminalSession s) {
  s.writeln();
  s.writeln('  Taskflare configuration');
  s.writeln();
  s.writeln('  1) Filter (terminal output)');
  s.writeln('  2) Report file');
  s.writeln('  q) Save and quit');
  s.writeln();
  s.write('Choose: ');
}

TaskflareConfig _filterMenu(TaskflareConfig config, TerminalSession term) {
  while (true) {
    term.clear();
    _printFilterMenu(config, term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(showFailed: !config.showFailed);
      case '2':
        config = config.copyWith(showErrored: !config.showErrored);
      case '3':
        config = config.copyWith(showSkipped: !config.showSkipped);
      case 'b':
        return config;
    }
  }
}

void _printFilterMenu(TaskflareConfig config, TerminalSession s) {
  s.writeln();
  s.writeln('  Filter — what to print as a permanent line in the terminal?');
  s.writeln();
  s.writeln('  1) Failed tests      ${_toggle(config.showFailed)}');
  s.writeln('  2) Errored tests     ${_toggle(config.showErrored)}');
  s.writeln('  3) Skipped tests     ${_toggle(config.showSkipped)}');
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose number to toggle: ');
}

TaskflareConfig _reportMenu(TaskflareConfig config, TerminalSession term) {
  while (true) {
    term.clear();
    _printReportMenu(config, term);
    final input = term.readLine()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(reportEnabled: !config.reportEnabled);
      case 'b':
        return config;
    }
  }
}

void _printReportMenu(TaskflareConfig config, TerminalSession s) {
  s.writeln();
  s.writeln('  Report file — written to taskflare-reports/ after each run.');
  s.writeln();
  s.writeln('  1) Generate report   ${_toggle(config.reportEnabled)}');
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose number to toggle: ');
}

String _toggle(bool value) => value ? '[ON ]' : '[OFF]';
