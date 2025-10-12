#!/usr/bin/env dart

import 'dart:io';

import 'package:flutterforge/banner.dart';
import 'package:flutterforge/cli_helper.dart';
import 'package:flutterforge/cmd_execute.dart';
import 'package:flutterforge/gemini.dart';

/// Main entry point for FlutterForge CLI
Future<void> main(List<String> arguments) async {
  try {
    // Show animated banner
    Banner.show();

    // Initialize services
    final geminiService = GeminiService();
    final cliHelper = CliHelper();
    final commandExecutor = CommandExecutor();

    // Get user input
    cliHelper.printInfo('\n👋 Hey! What are you building today?');
    cliHelper.printPrompt('> ');
    final userInput = stdin.readLineSync();

    if (userInput == null || userInput.trim().isEmpty) {
      cliHelper.printError('❌ No input provided. Exiting...');
      exit(1);
    }

    cliHelper.printInfo('\n🤖 Analyzing your requirements with Gemini AI...\n');

    // Call Gemini API
    final response = await geminiService.analyzeProjectRequirements(userInput);

    if (response == null) {
      cliHelper.printError(
        '❌ Failed to get response from Gemini. Please check your API key.',
      );
      exit(1);
    }

    // Display results
    cliHelper.printSuccess('\n✨ Here\'s what I recommend:\n');

    // Display packages
    if (response.packages.isNotEmpty) {
      cliHelper.printSection('📦 Recommended Packages:');
      for (var package in response.packages) {
        cliHelper.printItem('  • $package');
      }
      print('');
    }

    // Display app flow
    if (response.appFlow.isNotEmpty) {
      cliHelper.printSection('🗺️  Suggested App Flow:');

      // If any item contains HomeTabs:, split and print tabs separately
      final flowLines = <String>[];
      final bottomTabs = <String>[];

      for (var item in response.appFlow) {
        if (item.startsWith('HomeTabs:')) {
          final tabsPart = item.split(':').length > 1 ? item.split(':')[1] : '';
          final tabs = tabsPart
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty);
          bottomTabs.addAll(tabs);
        } else {
          flowLines.add(item);
        }
      }

      if (flowLines.isNotEmpty) {
        cliHelper.printItem('  ${flowLines.join(' → ')}');
      }

      if (bottomTabs.isNotEmpty) {
        cliHelper.printSection('  Bottom Navigation Tabs:');
        for (var tab in bottomTabs) {
          cliHelper.printItem('    • $tab');
        }
      }

      print('');
    }

    // Display additional notes
    if (response.notes.isNotEmpty) {
      cliHelper.printSection('💡 Additional Notes:');
      cliHelper.printItem('  ${response.notes}');
      print('');
    }

    // Ask for confirmation
    if (response.packages.isNotEmpty) {
      cliHelper.printWarning(
        '\n⚠️  Do you want to install these packages? (y/n)',
      );
      cliHelper.printPrompt('> ');
      final confirmation = stdin.readLineSync()?.toLowerCase();

      if (confirmation == 'y' || confirmation == 'yes') {
        cliHelper.printInfo('\n📥 Installing packages...\n');

        // Execute flutter pub add commands
        final success = await commandExecutor.installPackages(
          response.packages,
        );

        if (success) {
          cliHelper.printSuccess('\n✅ All packages installed successfully!');
          cliHelper.printSuccess('✅ Running flutter pub get...\n');
          await commandExecutor.runPubGet();
        } else {
          cliHelper.printError(
            '\n❌ Some packages failed to install. Check the output above.',
          );
        }
      } else {
        cliHelper.printInfo('\n⏭️  Skipping package installation.');
      }
    }

    // Show completion message
    cliHelper.printSuccess('\n' + '═' * 60);
    cliHelper.printSuccess(
      '  ✅ Setup complete! Happy coding with FlutterForge 🚀',
    );
    cliHelper.printSuccess('═' * 60 + '\n');
  } catch (e) {
    CliHelper().printError('\n❌ An error occurred: $e\n');
    exit(1);
  }
}
