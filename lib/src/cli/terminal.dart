import 'dart:io';

/// Tracks stdout lines so they can be erased before the next redraw.
///
/// Use [writeln] / [write] in place of stdout directly, then call [clear]
/// to erase exactly what this screen printed — no more, no less.
class TerminalScreen {
  int _lines = 0;

  void writeln([String text = '']) {
    stdout.writeln(text);
    _lines++;
  }

  void write(String text) {
    stdout.write(text);
  }

  /// Erases all lines written since creation, including the prompt+input line.
  ///
  /// Safe to call when [_lines] is zero (no-op).
  void clear() {
    if (_lines == 0) return;
    // +1 accounts for the "Choose: [input]\n" line the user typed on.
    stdout.write('\x1B[${_lines + 1}A\x1B[0J');
    _lines = 0;
  }
}
