import 'dart:io';
import 'package:flutterforge/cli_helper.dart';
import 'package:flutterforge/banner.dart';
import 'package:flutterforge/cmd_execute.dart';
import 'package:flutterforge/folder_creator.dart';
import 'package:flutterforge/gemini.dart';

Future<void> main() async {
  final cliHelper = CliHelper();
  final geminiService = GeminiService();
  final commandExecutor = CommandExecutor();
  final folderCreator = FolderCreator();

  Banner.show();

   
  cliHelper.printInfo('   Checking Flutter installation...');
  final isFlutterInstalled = await commandExecutor.checkFlutterInstallation();

  if (!isFlutterInstalled) {
    cliHelper.printError('   ✗ Flutter not found in PATH');
    cliHelper.printWarning(
      '   Install: https://flutter.dev/docs/get-started/install',
    );
    exit(1);
  }

  final flutterVersion = await commandExecutor.getFlutterVersion();
  if (flutterVersion != null) {
    cliHelper.printSuccess('   ✓ $flutterVersion');
  }

  Banner.showSeparator();

   
  final projectPath = folderCreator.getCurrentProjectPath();
  if (projectPath == null) {
    cliHelper.printWarning('\n   ⚠️  Not in a Flutter project directory');
    cliHelper.printInfo('   Run from project root (where pubspec.yaml exists)');
    if (!cliHelper.confirm('\n   Continue anyway? (y/n): ')) {
      exit(0);
    }
  } else {
    cliHelper.printSuccess('\n   ✓ Flutter project detected');
  }

   
  cliHelper.printSection('\n   PROJECT DESCRIPTION');
  Banner.showSubSeparator();
  cliHelper.printDim(
    '   Examples: "todo app", "e-commerce with payments", "social media feed"\n',
  );
  cliHelper.printPrompt('   → ');
  final userInput = stdin.readLineSync()?.trim();

  if (userInput == null || userInput.isEmpty) {
    cliHelper.printError('   ✗ Project description required');
    exit(1);
  }

   
  cliHelper.printSection('\n   ARCHITECTURE PATTERN');
  Banner.showSubSeparator();
  print('''
   ${_cyan}1.$_reset MVVM          - Model-View-ViewModel (Recommended)
   ${_cyan}2.$_reset MVC           - Model-View-Controller  
   ${_cyan}3.$_reset Clean         - Clean Architecture (Complex apps)
   ${_cyan}4.$_reset Feature-First - Modular by features
   ${_cyan}5.$_reset AI Decision   - Let AI choose best pattern
   ${_cyan}6.$_reset Custom        - Your own pattern
''');
  cliHelper.printPrompt('\n   → Select [1-6]: ');
  final choice = stdin.readLineSync()?.trim() ?? '';

  String? architecture;

  switch (choice) {
    case '1':
    case '':
      architecture = 'mvvm';
      break;
    case '2':
      architecture = 'mvc';
      break;
    case '3':
      architecture = 'clean';
      break;
    case '4':
      architecture = 'feature-first';
      break;
    case '5':
      architecture = null;
      cliHelper.printInfo('   ✓ AI will analyze and choose');
      break;
    case '6':
      cliHelper.printPrompt('\n   → Enter pattern name: ');
      architecture = stdin.readLineSync()?.trim();
      if (architecture == null || architecture.isEmpty) {
        architecture = 'mvvm';
        cliHelper.printWarning('   → Using default: MVVM');
      }
      break;
    default:
      architecture = choice.isEmpty ? 'mvvm' : choice;
      cliHelper.printInfo('   → Using: $architecture');
  }

  if (architecture != null) {
    cliHelper.printSuccess('   ✓ Selected: ${architecture.toUpperCase()}');
  }

  Banner.showSeparator();

   
  cliHelper.printSection('\n   AI ANALYSIS');
  Banner.showSubSeparator();
  cliHelper.showSpinner('   Analyzing with Gemini API...');

  final response = await geminiService.analyzeProjectRequirements(
    userInput,
    architecture,
  );

  cliHelper.clearLine();

  if (response == null) {
    cliHelper.printError('   ✗ Analysis failed - check API key and connection');
    exit(1);
  }

  cliHelper.printSuccess('   ✓ Analysis complete\n');

   
  Banner.showSeparator();

   
  var finalResponse = response;
  var shouldReview = true;

  while (shouldReview) {
     
    if (finalResponse.packages.isNotEmpty) {
      cliHelper.printSection(
        '\n   RECOMMENDED PACKAGES (${finalResponse.packages.length})',
      );
      Banner.showSubSeparator();
      for (var i = 0; i < finalResponse.packages.length; i++) {
        print(
          '   ${_cyan}${(i + 1).toString().padLeft(2)}.$_reset ${finalResponse.packages[i]}',
        );
      }
    } else {
      cliHelper.printWarning('\n   ⚠️  No packages recommended');
    }

    cliHelper.printSection('\n   ARCHITECTURE');
    Banner.showSubSeparator();
    final displayPattern =
        architecture ?? finalResponse.folderStructure.pattern;
    print('   ${_green}→$_reset ${displayPattern.toUpperCase()}');

    cliHelper.printSection(
      '\n   FOLDER STRUCTURE (${finalResponse.folderStructure.folders.length} folders)',
    );
    Banner.showSubSeparator();
    for (var folder in finalResponse.folderStructure.folders) {
      print('   ${_cyan}lib/$_reset$folder/');
    }

    if (finalResponse.notes.isNotEmpty) {
      cliHelper.printSection('\n   IMPLEMENTATION NOTES');
      Banner.showSubSeparator();
      print('   ${_dim}${finalResponse.notes}$_reset');
    }

    Banner.showSeparator();

     
    print('');
    cliHelper.printSection('   REVIEW OPTIONS');
    print('   ${_green}1.$_reset Proceed with installation');
    print('   ${_cyan}2.$_reset Make changes (describe what to modify)');
    print('   ${_yellow}3.$_reset Cancel\n');

    cliHelper.printPrompt('   Choose (1-3) [default: 1]: ');
    final choice = stdin.readLineSync()?.trim() ?? '1';

    if (choice == '3') {
      cliHelper.printWarning('\n   → Cancelled by user');
      exit(0);
    } else if (choice == '2') {
       
      print('');
      cliHelper.printPrompt(
        '   Describe changes (e.g., "add payment, remove firebase, use bloc"): ',
      );
      final modifications = stdin.readLineSync()?.trim();

      if (modifications == null || modifications.isEmpty) {
        cliHelper.printWarning(
          '   → No changes specified, keeping current setup',
        );
        continue;
      }

       
      cliHelper.printSection('\n   Applying modifications...');
      final modifiedResponse = await geminiService.modifyRecommendations(
        userInput,
        architecture,
        modifications,
        finalResponse,
      );

      if (modifiedResponse == null) {
        cliHelper.printError('   ✗ Failed to apply modifications');
        cliHelper.printInfo('   → Keeping previous recommendations\n');
      } else {
        finalResponse = modifiedResponse;
        cliHelper.printSuccess('   ✓ Recommendations updated!\n');
        Banner.showSeparator();
      }
    } else {
       
      shouldReview = false;
    }
  }

   
  print('');
  final installPackages =
      finalResponse.packages.isNotEmpty &&
      cliHelper.confirm(
        '   Install ${finalResponse.packages.length} packages? (y/n): ',
      );
  final createFolders = cliHelper.confirm(
    '   Create folder structure? (y/n): ',
  );

  if (!installPackages && !createFolders) {
    cliHelper.printWarning('\n   → No actions selected');
    exit(0);
  }

  Banner.showSeparator();

   
  if (createFolders) {
    if (projectPath == null) {
      cliHelper.printError(
        '\n   ✗ Cannot create folders outside Flutter project',
      );
    } else {
      await folderCreator.createFolderStructure(
        finalResponse.folderStructure,
        projectPath,
      );
    }
  }

   
  if (installPackages) {
    if (projectPath == null) {
      cliHelper.printWarning(
        '\n   ✗ Cannot install packages outside Flutter project',
      );
      cliHelper.printInfo('\n   Add these to pubspec.yaml manually:');
      for (var pkg in finalResponse.packages) {
        print('   - $pkg');
      }
    } else {
      cliHelper.printSection('\n   INSTALLING PACKAGES');
      Banner.showSubSeparator();
      final success = await commandExecutor.installPackages(
        finalResponse.packages,
      );

      if (success) {
        cliHelper.printSuccess('\n   ✓ All packages installed');
      } else {
        cliHelper.printWarning('\n   ⚠️  Some packages failed');
      }

      cliHelper.printInfo('\n   → Running pub get...');
      await commandExecutor.runPubGet();
    }
  }

   
  Banner.showSeparator();
  print('''
$_green$_bold
   ✓ SETUP COMPLETE
$_reset
   ${_cyan}Next Steps:$_reset
   ${_dim}1. Review folder structure in lib/$_reset
   ${_dim}2. Check lib/ARCHITECTURE.md for guidance$_reset
   ${_dim}3. Start building your ${userInput}!$_reset

   ${_green}Happy coding! 🚀$_reset
''');

  if (cliHelper.confirm('\n   Show architecture tips? (y/n): ')) {
    _showTips(architecture ?? finalResponse.folderStructure.pattern, cliHelper);
  }

  print('');
}

 
const _reset = '\x1B[0m';
const _green = '\x1B[32m';
const _cyan = '\x1B[36m';
const _yellow = '\x1B[33m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';

void _showTips(String pattern, CliHelper cli) {
  Banner.showSeparator();
  cli.printSection('\n   TIPS FOR ${pattern.toUpperCase()}');
  Banner.showSubSeparator();

  final tips = {
    'mvvm': [
      'Keep ViewModels Flutter-independent',
      'Use ChangeNotifier or Riverpod for state',
      'Handle all business logic in ViewModels',
      'Use repositories for data abstraction',
      'Views should only contain UI code',
    ],
    'mvc': [
      'Controllers handle user input',
      'Keep Views lightweight',
      'Models represent data and rules',
      'Use services for external operations',
      'Controllers coordinate Model and View',
    ],
    'clean': [
      'Follow dependency rule strictly',
      'Domain layer has NO dependencies',
      'Use interfaces for repositories',
      'One UseCase per business operation',
      'Entities are framework-independent',
      'Data layer implements domain interfaces',
    ],
    'feature-first': [
      'Each feature is self-contained',
      'Organize by feature, not layer',
      'Features should be independent',
      'Use core/ for shared infrastructure',
      'Easy to scale with new features',
      'Extract features into packages',
    ],
  };

  final tipList =
      tips[pattern.toLowerCase()] ??
      [
        'Maintain separation of concerns',
        'Keep business logic separate from UI',
        'Use dependency injection',
        'Write testable code',
        'Follow SOLID principles',
      ];

  for (var i = 0; i < tipList.length; i++) {
    print('   ${_cyan}${i + 1}.$_reset ${tipList[i]}');
  }

  Banner.showSeparator();
}
