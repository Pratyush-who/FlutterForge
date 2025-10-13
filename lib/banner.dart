import 'dart:io';

/// Utility class for displaying professional startup banner
class Banner {
  /// Shows the FlutterForge startup banner with clean design
  static void show() {
    // ANSI color codes
    const cyan = '\x1B[36m';
    const blue = '\x1B[34m';
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const dim = '\x1B[2m';

    // Clean, professional banner without emojis
    final banner =
        '''
$cyan$bold
┌────────────────────────────────────────────────────────────┐
│                                                            │
│    ${yellow}F L U T T E R F O R G E$cyan                               │
│                                                            │
│    ${reset}${dim}AI-Powered Flutter Project Setup Assistant$cyan$bold          │
│    ${reset}${dim}Version 1.0.0$cyan$bold                                       │
│                                                            │
└────────────────────────────────────────────────────────────┘
$reset
''';

    print(banner);

    // Minimal loading animation
    _showInitializing();
  }

  /// Shows initializing message with subtle animation
  static void _showInitializing() {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    const dim = '\x1B[2m';

    // Simple dot animation
    stdout.write('$dim  Initializing');
    for (var i = 0; i < 3; i++) {
      sleep(Duration(milliseconds: 200));
      stdout.write('.');
    }
    stdout.write(' ${cyan}Ready$reset\n\n');
  }

  /// Shows a clean separator line
  static void showSeparator() {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    const dim = '\x1B[2m';
    print('$dim$cyan${'─' * 60}$reset');
  }

  /// Alternative minimal banner style
  static void showMinimal() {
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';

    print('''
$cyan$bold
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ${yellow}FLUTTERFORGE$cyan v1.0.0
  
  AI-Powered Flutter Setup Assistant
  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$reset
''');
  }

  /// Spring Boot inspired banner
  static void showSpringStyle() {
    const green = '\x1B[32m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const dim = '\x1B[2m';

    print('''

  $green$bold.   ____          _            _____ __
 /\\\\ / ___'_ __ _ _(_)_ __  __ / ___// _|
( ( )\\___ | '_ | '_| | '_ \\/ _` \\___ \\| |_ 
 \\\\/  ___) | |_) | | | | | | (_| |___) |  _|
  '  |____/| .__/|_| |_|_| |_\\__, |____/|_|  
      =========|_|==============|___/=======

 :: FlutterForge ::                    ${dim}(v1.0.0)$reset
$reset
''');
  }

  /// Compact professional banner
  static void showCompact() {
    const cyan = '\x1B[36m';
    const blue = '\x1B[34m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';
    const dim = '\x1B[2m';

    print('''
$cyan$bold
╭──────────────────────────────────────────────────────────╮
│  ${blue}FLUTTERFORGE$cyan  ${dim}v1.0.0$cyan$bold                                  │
│  ${reset}${dim}Flutter Project Setup Assistant$cyan$bold                      │
╰──────────────────────────────────────────────────────────╯$reset

''');
  }

  /// Shows help/info section
  static void showHelp() {
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';

    print('''
$cyan$bold
USAGE:$reset
  Run this tool from your Flutter project root directory
  
$cyan$bold  FEATURES:$reset
  • AI-powered package recommendations
  • Automatic folder structure generation
  • Support for multiple architecture patterns
  • Package installation automation
  
$cyan$bold  SUPPORTED ARCHITECTURES:$reset
  • MVVM (Model-View-ViewModel)
  • MVC (Model-View-Controller)
  • Clean Architecture
  • Feature-First Architecture
  
$cyan$bold  AUTHOR:$reset
  Pratyush
  
$yellow$bold  NOTE:$reset
  Requires GEMINI_API_KEY in .env file or environment variables
$reset
''');
  }
}
