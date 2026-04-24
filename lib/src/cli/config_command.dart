import 'dart:io';

import '../config/taskflare_config.dart';
import 'terminal.dart';

/// Runs the interactive configuration menu, saving changes on exit.
Future<void> runConfigCommand() async {
  var config = await TaskflareConfig.load();

  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final screen = TerminalScreen();
    _printMainMenu(config, screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = _filterMenu(config);
        prev = screen;
      case '2':
        config = _reportMenu(config);
        prev = screen;
      case 'q':
        screen.clear();
        await config.save();
        stdout.writeln('Configuration saved.');
        return;
      default:
        screen.writeln('  Unknown option. Enter 1, 2, or q.');
        prev = screen;
    }
  }
}

void _printMainMenu(TaskflareConfig config, TerminalScreen s) {
  s.writeln();
  s.writeln('  Taskflare configuration');
  s.writeln();
  s.writeln('  1) Filter (terminal output)');
  s.writeln('  2) Report file');
  s.writeln('  q) Save and quit');
  s.writeln();
  s.write('Choose: ');
}

TaskflareConfig _filterMenu(TaskflareConfig config) {
  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final screen = TerminalScreen();
    _printFilterMenu(config, screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(showFailed: !config.showFailed);
        prev = screen;
      case '2':
        config = config.copyWith(showErrored: !config.showErrored);
        prev = screen;
      case '3':
        config = config.copyWith(showSkipped: !config.showSkipped);
        prev = screen;
      case 'b':
        screen.clear();
        return config;
      default:
        screen.writeln('  Unknown option. Enter 1, 2, 3, or b.');
        prev = screen;
    }
  }
}

void _printFilterMenu(TaskflareConfig config, TerminalScreen s) {
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

TaskflareConfig _reportMenu(TaskflareConfig config) {
  TerminalScreen? prev;
  while (true) {
    prev?.clear();
    final screen = TerminalScreen();
    _printReportMenu(config, screen);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(reportEnabled: !config.reportEnabled);
        prev = screen;
      case 'b':
        screen.clear();
        return config;
      default:
        screen.writeln('  Unknown option. Enter 1 or b.');
        prev = screen;
    }
  }
}

void _printReportMenu(TaskflareConfig config, TerminalScreen s) {
  s.writeln();
  s.writeln('  Report file — written to taskflare-reports/ after each run.');
  s.writeln();
  s.writeln('  1) Generate report   ${_toggle(config.reportEnabled)}');
  s.writeln('  b) Back');
  s.writeln();
  s.write('Choose number to toggle: ');
}

String _toggle(bool value) => value ? '[ON ]' : '[OFF]';
