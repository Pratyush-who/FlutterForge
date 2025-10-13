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

  // Show banner
  Banner.show();

  // Check Flutter installation
  cliHelper.printInfo('\n🔍 Checking Flutter installation...');
  final isFlutterInstalled = await commandExecutor.checkFlutterInstallation();

  if (!isFlutterInstalled) {
    cliHelper.printError('❌ Flutter is not installed or not in PATH');
    cliHelper.printWarning(
      'Please install Flutter: https://flutter.dev/docs/get-started/install',
    );
    exit(1);
  }

  final flutterVersion = await commandExecutor.getFlutterVersion();
  if (flutterVersion != null) {
    cliHelper.printSuccess('✓ $flutterVersion');
  }

  Banner.showSeparator();

  // Check if we're in a Flutter project
  final projectPath = folderCreator.getCurrentProjectPath();
  if (projectPath == null) {
    cliHelper.printWarning(
      '\n⚠️  Not in a Flutter project directory!',
    );
    cliHelper.printInfo(
      'Please run this command from your Flutter project root (where pubspec.yaml is located).',
    );
    
    if (!cliHelper.confirm('\nContinue anyway? (y/n): ')) {
      exit(0);
    }
  } else {
    cliHelper.printSuccess('\n✓ Flutter project detected');
  }

  // Ask what user is building
  cliHelper.printSection('\n💡 What are you building today?');
  cliHelper.printDim(
    '   Examples: "a todo app", "social media app with chat", "e-commerce store"\n',
  );
  cliHelper.printPrompt('📝 Your project: ');
  final userInput = stdin.readLineSync()?.trim();

  if (userInput == null || userInput.isEmpty) {
    cliHelper.printError('❌ Project description is required');
    exit(1);
  }

  // Ask about architecture pattern
  cliHelper.printSection('\n🏗️  Choose your architecture pattern:');
  cliHelper.printItem('   1. MVVM (Model-View-ViewModel) - Recommended for most apps');
  cliHelper.printItem('   2. MVC (Model-View-Controller) - Simple and familiar');
  cliHelper.printItem('   3. Clean Architecture - Best for large, complex apps');
  cliHelper.printItem('   4. Feature-First - Organize by features, not layers');
  cliHelper.printItem('   5. Let AI decide (based on your project)');
  cliHelper.printItem('   6. Custom (specify your own)\n');
  cliHelper.printPrompt('🔢 Choose (1-6) [default: 1]: ');
  final architectureChoice = stdin.readLineSync()?.trim() ?? '1';

  String? architecturePattern;
  switch (architectureChoice) {
    case '1':
    case '':
      architecturePattern = 'mvvm';
      break;
    case '2':
      architecturePattern = 'mvc';
      break;
    case '3':
      architecturePattern = 'clean';
      break;
    case '4':
      architecturePattern = 'feature-first';
      break;
    case '5':
      architecturePattern = null; // Let AI decide
      cliHelper.printInfo('   ✓ AI will analyze and choose the best pattern');
      break;
    case '6':
      cliHelper.printPrompt('\n   Enter your architecture pattern: ');
      architecturePattern = stdin.readLineSync()?.trim();
      if (architecturePattern == null || architecturePattern.isEmpty) {
        architecturePattern = 'mvvm';
        cliHelper.printWarning('   Using default: MVVM');
      }
      break;
    default:
      cliHelper.printWarning('   Invalid choice, using MVVM');
      architecturePattern = 'mvvm';
  }

  if (architecturePattern != null) {
    cliHelper.printSuccess('   ✓ Selected: ${architecturePattern.toUpperCase()}');
  }

  Banner.showSeparator();

  // Analyze with Gemini
  cliHelper.printSection('\n🤖 Analyzing your project with AI...');
  cliHelper.showSpinner('   Please wait...');

  final response = await geminiService.analyzeProjectRequirements(
    userInput,
    architecturePattern,
  );

  cliHelper.clearLine();

  if (response == null) {
    cliHelper.printError('❌ Failed to analyze project requirements');
    exit(1);
  }

  cliHelper.printSuccess('✓ Analysis complete!\n');

  // Display recommendations
  Banner.showSeparator();
  cliHelper.printSection('\n📦 Recommended Packages:');
  if (response.packages.isEmpty) {
    cliHelper.printWarning('   No packages recommended');
  } else {
    for (var i = 0; i < response.packages.length; i++) {
      cliHelper.printItem('   ${i + 1}. ${response.packages[i]}');
    }
  }

  cliHelper.printSection('\n🗺️  Suggested App Flow:');
  if (response.appFlow.isEmpty) {
    cliHelper.printWarning('   No app flow suggested');
  } else {
    final flow = response.appFlow.join(' → ');
    cliHelper.printItem('   $flow');
  }

  cliHelper.printSection('\n🏗️  Architecture Pattern:');
  cliHelper.printItem('   ${response.folderStructure.pattern.toUpperCase()}');

  cliHelper.printSection('\n📁 Folder Structure:');
  for (var folder in response.folderStructure.folders) {
    cliHelper.printItem('   lib/$folder/');
  }

  if (response.notes.isNotEmpty) {
    cliHelper.printSection('\n💡 Implementation Notes:');
    cliHelper.printDim('   ${response.notes}');
  }

  Banner.showSeparator();

  // Confirm actions
  print('');
  final shouldInstallPackages = cliHelper.confirm(
    '📦 Install recommended packages? (y/n): ',
  );

  final shouldCreateFolders = cliHelper.confirm(
    '📁 Create folder structure? (y/n): ',
  );

  if (!shouldInstallPackages && !shouldCreateFolders) {
    cliHelper.printWarning('\n⚠️  No actions selected. Exiting...');
    exit(0);
  }

  Banner.showSeparator();

  // Create folders
  if (shouldCreateFolders) {
    if (projectPath == null) {
      cliHelper.printError(
        '\n❌ Cannot create folders: Not in a Flutter project directory',
      );
    } else {
      final success = await folderCreator.createFolderStructure(
        response.folderStructure,
        projectPath,
      );

      if (!success) {
        cliHelper.printWarning(
          '⚠️  Some folders could not be created',
        );
      }
    }
  }

  // Install packages
  if (shouldInstallPackages) {
    if (projectPath == null) {
      cliHelper.printWarning(
        '\n⚠️  Not in Flutter project. Skipping package installation.',
      );
      cliHelper.printInfo(
        '   You can manually add these packages to your pubspec.yaml:',
      );
      for (var pkg in response.packages) {
        print('   - $pkg');
      }
    } else {
      cliHelper.printSection('\n📦 Installing packages...');
      final success = await commandExecutor.installPackages(response.packages);

      if (success) {
        cliHelper.printSuccess('\n✅ All packages installed successfully!');
      } else {
        cliHelper.printWarning(
          '\n⚠️  Some packages failed to install. Check the errors above.',
        );
      }

      // Run pub get to ensure everything is resolved
      cliHelper.printInfo('\n🔄 Resolving dependencies...');
      await commandExecutor.runPubGet();
    }
  }

  // Final summary
  Banner.showSeparator();
  cliHelper.printBox('''
✨ Setup Complete!

Next Steps:
1. Review the generated folder structure
2. Check ARCHITECTURE.md for guidance
3. Start building your ${userInput}!

Happy coding! 🚀
''');

  // Ask if user wants to see additional tips
  if (cliHelper.confirm('\n📚 Show quick tips for this architecture? (y/n): ')) {
    _showArchitectureTips(response.folderStructure.pattern, cliHelper);
  }

  print('\n');
}

/// Shows helpful tips based on architecture pattern
void _showArchitectureTips(String pattern, CliHelper cliHelper) {
  Banner.showSeparator();
  cliHelper.printSection('\n💡 Quick Tips for ${pattern.toUpperCase()}:\n');

  switch (pattern.toLowerCase()) {
    case 'mvvm':
      cliHelper.printItem('''
   1. Keep ViewModels independent of Flutter widgets
   2. Use ChangeNotifier or StateNotifier for state management
   3. ViewModels should only expose data and actions
   4. Handle all business logic in ViewModels
   5. Use repositories to abstract data sources
''');
      break;

    case 'mvc':
      cliHelper.printItem('''
   1. Controllers handle user input and update models
   2. Keep Views lightweight - only UI code
   3. Models represent data and business rules
   4. Use services for external operations
   5. Controllers coordinate between Models and Views
''');
      break;

    case 'clean':
      cliHelper.printItem('''
   1. Follow the dependency rule strictly
   2. Domain layer should have NO dependencies
   3. Use interfaces/abstract classes for repositories
   4. UseCases contain single business operations
   5. Keep entities pure - no framework dependencies
   6. Data layer implements domain interfaces
''');
      break;

    case 'feature-first':
      cliHelper.printItem('''
   1. Each feature is self-contained
   2. Organize by feature, not technical layer
   3. Features should be independent
   4. Use core/ for shared infrastructure
   5. Easy to scale by adding new features
   6. Consider extracting features into packages
''');
      break;

    default:
      cliHelper.printItem('''
   1. Maintain separation of concerns
   2. Keep business logic separate from UI
   3. Use dependency injection
   4. Write testable code
   5. Follow SOLID principles
''');
  }

  Banner.showSeparator();
}