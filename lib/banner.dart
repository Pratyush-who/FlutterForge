class Banner {
  static void show() {
    const green = '\x1B[32m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';

    print('''
$green$bold
  ███████╗██╗     ██╗   ██╗████████╗████████╗███████╗██████╗ 
  ██╔════╝██║     ██║   ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
  █████╗  ██║     ██║   ██║   ██║      ██║   █████╗  ██████╔╝
  ██╔══╝  ██║     ██║   ██║   ██║      ██║   ██╔══╝  ██╔══██╗
  ██║     ███████╗╚██████╔╝   ██║      ██║   ███████╗██║  ██║
  ╚═╝     ╚══════╝ ╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
  
  ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
  ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
  █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  
  ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  
  ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
  ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝$reset
$reset
''');
  }

  static void showSeparator() {
    const green = '\x1B[32m';
    const reset = '\x1B[0m';
    print('$green${'═' * 70}$reset');
  }

  static void showSubSeparator() {
    const cyan = '\x1B[36m';
    const reset = '\x1B[0m';
    const dim = '\x1B[2m';
    print('$dim$cyan${'─' * 70}$reset');
  }

  static void showHelp() {
    const green = '\x1B[32m';
    const cyan = '\x1B[36m';
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    const bold = '\x1B[1m';

    print('''
$green$bold
╔════════════════════════════════════════════════════════════════════╗
║                        FLUTTERFORGE HELP                           ║
╚════════════════════════════════════════════════════════════════════╝$reset

$cyan$bold USAGE:$reset
   Run from your Flutter project root directory
   
$cyan$bold FEATURES:$reset
   • AI-powered package recommendations via Gemini API
   • Automatic folder structure generation
   • Multiple architecture pattern support
   • Automated package installation
   
$cyan$bold SUPPORTED ARCHITECTURES:$reset
   • MVVM    - Model-View-ViewModel pattern
   • MVC     - Model-View-Controller pattern  
   • Clean   - Uncle Bob's Clean Architecture
   • Feature - Feature-first modular structure
   • Custom  - Your own architecture pattern
   
$cyan$bold REQUIREMENTS:$reset
   • Flutter SDK installed and in PATH
   • GEMINI_API_KEY in .env file or environment
   • Internet connection for AI analysis
   
$yellow$bold GETTING STARTED:$reset
   1. Create .env file with: GEMINI_API_KEY=your_key_here
   2. Run: dart run flutterforge
   3. Follow the interactive prompts
   
$cyan$bold AUTHOR:$reset
   Pratyush
   
$green$bold═══════════════════════════════════════════════════════════════════════$reset
''');
  }
}
