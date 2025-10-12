import 'dart:io';

/// Utility class for displaying animated startup banner
class Banner {
  /// Shows the FlutterForge startup banner
  static void show() {
    // ANSI color codes
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const green = '\x1B[32m';

    final banner =
        '''
$cyan$bold
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     ⚡ ${yellow}F L U T T E R F O R G E$cyan ⚡                       ║
║                                                            ║
║            ${green}v1.0.0$cyan - AI-Powered Setup Assistant           ║
║                                                            ║
║                    ${reset}Created by ${bold}Pratyush$cyan                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
$reset
''';

    print(banner);

    // Simulate loading animation
    _animateLoading();
  }

  /// Shows a simple loading animation
  static void _animateLoading() {
    const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';

    stdout.write('$cyan  Initializing...$reset ');

    for (var i = 0; i < 15; i++) {
      stdout.write('\b${frames[i % frames.length]}');
      sleep(Duration(milliseconds: 80));
    }

    stdout.write('\b✓\n');
  }

  /// Shows a simple separator line
  static void showSeparator() {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    print('$cyan${'─' * 60}$reset');
  }
}
