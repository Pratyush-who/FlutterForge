import 'dart:io';
import 'package:process_run/shell.dart';
import 'cli_helper.dart';

/// Utility class to execute Flutter CLI commands
class CommandExecutor {
  final _cliHelper = CliHelper();

  /// Installs multiple Flutter packages
  Future<bool> installPackages(List<String> packages) async {
    if (packages.isEmpty) {
      _cliHelper.printWarning('No packages to install.');
      return true;
    }

    try {
      final shell = Shell();
      var successCount = 0;

      for (var i = 0; i < packages.length; i++) {
        final package = packages[i];
        _cliHelper.printInfo(
          '  [${i + 1}/${packages.length}] Installing $package...',
        );

        try {
          // Run flutter pub add command
          await shell.run('flutter pub add $package');
          successCount++;
          _cliHelper.printSuccess('      ✓ $package installed successfully');
        } catch (e) {
          _cliHelper.printError('      ✗ Failed to install $package: $e');
        }
      }

      _cliHelper.printInfo(
        '\n  Summary: $successCount/${packages.length} packages installed',
      );
      return successCount == packages.length;
    } catch (e) {
      _cliHelper.printError('Error executing commands: $e');
      return false;
    }
  }

  /// Runs flutter pub get
  Future<bool> runPubGet() async {
    try {
      final shell = Shell();
      _cliHelper.printInfo('  Running flutter pub get...');

      await shell.run('flutter pub get');
      _cliHelper.printSuccess('  ✓ Dependencies resolved successfully');
      return true;
    } catch (e) {
      _cliHelper.printError('  ✗ Failed to run pub get: $e');
      return false;
    }
  }

  /// Runs flutter pub upgrade
  Future<bool> runPubUpgrade() async {
    try {
      final shell = Shell();
      _cliHelper.printInfo('  Running flutter pub upgrade...');

      await shell.run('flutter pub upgrade');
      _cliHelper.printSuccess('  ✓ Dependencies upgraded successfully');
      return true;
    } catch (e) {
      _cliHelper.printError('  ✗ Failed to run pub upgrade: $e');
      return false;
    }
  }

  /// Runs flutter clean
  Future<bool> runClean() async {
    try {
      final shell = Shell();
      _cliHelper.printInfo('  Running flutter clean...');

      await shell.run('flutter clean');
      _cliHelper.printSuccess('  ✓ Project cleaned successfully');
      return true;
    } catch (e) {
      _cliHelper.printError('  ✗ Failed to clean project: $e');
      return false;
    }
  }

  /// Checks if Flutter is installed
  Future<bool> checkFlutterInstallation() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets Flutter version
  Future<String?> getFlutterVersion() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n').first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Runs a custom Flutter command
  Future<bool> runCustomCommand(String command) async {
    try {
      final shell = Shell();
      await shell.run(command);
      return true;
    } catch (e) {
      _cliHelper.printError('Error running command: $e');
      return false;
    }
  }
}
