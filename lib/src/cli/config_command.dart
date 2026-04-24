import 'dart:io';

import '../config/taskflare_config.dart';

/// Runs the interactive configuration menu, saving changes on exit.
Future<void> runConfigCommand() async {
  var config = await TaskflareConfig.load();

  while (true) {
    _printMainMenu(config);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = _filterMenu(config);
      case '2':
        config = _reportMenu(config);
      case 'q':
        await config.save();
        stdout.writeln('\nConfiguration saved.');
        return;
      default:
        stdout.writeln('  Unknown option. Enter 1, 2, or q.');
    }
  }
}

void _printMainMenu(TaskflareConfig config) {
  stdout.writeln('');
  stdout.writeln('Taskflare configuration');
  stdout.writeln('');
  stdout.writeln('  1) Filter (terminal output)');
  stdout.writeln('  2) Report file');
  stdout.writeln('  q) Save and quit');
  stdout.writeln('');
  stdout.write('Choose: ');
}

TaskflareConfig _filterMenu(TaskflareConfig config) {
  while (true) {
    _printFilterMenu(config);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(showFailed: !config.showFailed);
      case '2':
        config = config.copyWith(showErrored: !config.showErrored);
      case '3':
        config = config.copyWith(showSkipped: !config.showSkipped);
      case 'b':
        return config;
      default:
        stdout.writeln('  Unknown option. Enter 1, 2, 3, or b.');
    }
  }
}

void _printFilterMenu(TaskflareConfig config) {
  stdout.writeln('');
  stdout.writeln('Filter — what to print as a permanent line in the terminal?');
  stdout.writeln('');
  stdout.writeln('  1) Failed tests      ${_toggle(config.showFailed)}');
  stdout.writeln('  2) Errored tests     ${_toggle(config.showErrored)}');
  stdout.writeln('  3) Skipped tests     ${_toggle(config.showSkipped)}');
  stdout.writeln('  b) Back');
  stdout.writeln('');
  stdout.write('Choose number to toggle: ');
}

TaskflareConfig _reportMenu(TaskflareConfig config) {
  while (true) {
    _printReportMenu(config);
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case '1':
        config = config.copyWith(reportEnabled: !config.reportEnabled);
      case 'b':
        return config;
      default:
        stdout.writeln('  Unknown option. Enter 1 or b.');
    }
  }
}

void _printReportMenu(TaskflareConfig config) {
  stdout.writeln('');
  stdout.writeln('Report file — written to taskflare-reports/ after each run.');
  stdout.writeln('');
  stdout.writeln('  1) Generate report   ${_toggle(config.reportEnabled)}');
  stdout.writeln('  b) Back');
  stdout.writeln('');
  stdout.write('Choose number to toggle: ');
}

String _toggle(bool value) => value ? '[ON ]' : '[OFF]';
