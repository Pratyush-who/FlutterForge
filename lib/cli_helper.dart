import 'dart:io';

/// Helper class for terminal/CLI interactions with colored output
class CliHelper {
  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _cyan = '\x1B[36m';
  static const String _bold = '\x1B[1m';
  static const String _dim = '\x1B[2m';

  /// Prints an error message in red
  void printError(String message) {
    print('$_red$message$_reset');
  }

  /// Prints a success message in green
  void printSuccess(String message) {
    print('$_green$message$_reset');
  }

  /// Prints a warning message in yellow
  void printWarning(String message) {
    print('$_yellow$message$_reset');
  }

  /// Prints an info message in cyan
  void printInfo(String message) {
    print('$_cyan$message$_reset');
  }

  /// Prints a section header in bold blue
  void printSection(String message) {
    print('$_blue$_bold$message$_reset');
  }

  /// Prints a list item
  void printItem(String message) {
    print('$_cyan$message$_reset');
  }

  /// Prints a prompt without newline
  void printPrompt(String prompt) {
    stdout.write('$_green$_bold$prompt$_reset');
  }

  /// Prints a dim/gray message
  void printDim(String message) {
    print('$_dim$message$_reset');
  }

  /// Shows a loading spinner
  void showSpinner(String message) {
    stdout.write('$_cyan$message$_reset ');
  }

  /// Clears the current line
  void clearLine() {
    stdout.write('\r\x1B[K');
  }

  /// Asks user for confirmation (y/n)
  bool confirm(String question) {
    printWarning(question);
    printPrompt('> ');
    final answer = stdin.readLineSync()?.toLowerCase();
    return answer == 'y' || answer == 'yes';
  }

  /// Prints a horizontal line separator
  void printSeparator() {
    print('$_cyan${'─' * 60}$_reset');
  }

  /// Prints a box around text
  void printBox(String text) {
    final lines = text.split('\n');
    final maxLength = lines
        .map((l) => l.length)
        .reduce((a, b) => a > b ? a : b);

    print('$_cyan╔${'═' * (maxLength + 2)}╗$_reset');
    for (var line in lines) {
      final padding = ' ' * (maxLength - line.length);
      print('$_cyan║$_reset $line$padding $_cyan║$_reset');
    }
    print('$_cyan╚${'═' * (maxLength + 2)}╝$_reset');
  }

  /// Shows a progress indicator
  void showProgress(int current, int total) {
    final percentage = (current / total * 100).round();
    final filled = (current / total * 20).round();
    final empty = 20 - filled;

    final bar = '█' * filled + '░' * empty;
    stdout.write(
      '\r$_green[$bar]$_reset $percentage% ($_cyan$current$_reset/$total)',
    );

    if (current == total) {
      print('');
    }
  }
}
