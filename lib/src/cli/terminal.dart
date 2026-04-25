import 'dart:async';
import 'dart:io';

/// Manages the alternate screen buffer for interactive TUI flows.
///
/// One instance is created per top-level entry point (menu, standalone help,
/// standalone config) and injected into every sub-screen so they all share the
/// same buffer lifecycle.
///
/// Call [run] to enter the alt buffer and guarantee it is exited on every code
/// path, including SIGINT. Inside the body, use [clear], [writeln], [write],
/// and [readLine] instead of touching [stdout] / [stdin] directly.
///
/// When a sub-command's output must land in the normal scrollback (e.g. running
/// tests), call [exitAlt] before that command. The [run] finally-block is
/// safe to call afterwards — it guards against a double-exit.
class TerminalSession {
  bool _inAlt = false;

  /// Switches the terminal to the alternate screen buffer.
  ///
  /// No-op if already in the alt buffer.
  void enterAlt() {
    if (_inAlt) return;
    stdout.write('\x1B[?1049h');
    _inAlt = true;
  }

  /// Restores the normal screen buffer.
  ///
  /// No-op if not currently in the alt buffer.
  void exitAlt() {
    if (!_inAlt) return;
    stdout.write('\x1B[?1049l');
    _inAlt = false;
  }

  /// Enters the alt buffer, runs [body], then exits on any completion path.
  ///
  /// Installs a SIGINT handler for the duration so Ctrl-C also restores the
  /// terminal before the process exits.
  Future<T> run<T>(Future<T> Function() body) async {
    enterAlt();
    final sigint = ProcessSignal.sigint.watch().listen((_) {
      exitAlt();
      exit(0);
    });
    try {
      return await body();
    } finally {
      await sigint.cancel();
      exitAlt();
    }
  }

  /// Erases the entire viewport and moves the cursor to the top-left.
  void clear() => stdout.write('\x1B[H\x1B[2J');

  /// Writes [text] followed by a newline.
  void writeln([String text = '']) => stdout.writeln(text);

  /// Writes [text] without a trailing newline.
  void write(String text) => stdout.write(text);

  /// Reads one line of user input. Returns `null` on EOF.
  String? readLine() => stdin.readLineSync();
}
