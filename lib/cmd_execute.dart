import 'dart:io';
import 'package:process_run/shell.dart';
import 'cli_helper.dart';

 
class CommandExecutor {
  final _cliHelper = CliHelper();

   
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

   
  Future<bool> checkFlutterInstallation() async {
     
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) return true;
    } catch (_) {}

     
    try {
      if (Platform.isWindows) {
        final whereRes = await Process.run('where', ['flutter']);
        if (whereRes.exitCode == 0 &&
            whereRes.stdout.toString().trim().isNotEmpty) {
          return true;
        }
      } else {
        final whichRes = await Process.run('which', ['flutter']);
        if (whichRes.exitCode == 0 &&
            whichRes.stdout.toString().trim().isNotEmpty) {
          return true;
        }
      }
    } catch (_) {}

     
    final pathEnv =
        Platform.environment['PATH'] ?? Platform.environment['Path'] ?? '';
    final separator = Platform.isWindows ? ';' : ':';
    final entries = pathEnv.split(separator);
    for (var entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
       
      final candidate1 = Platform.isWindows
          ? File('$trimmed\\flutter.bat')
          : File('$trimmed/flutter');

      if (candidate1.existsSync()) return true;

      final candidate2 = File(
        '${trimmed}${Platform.pathSeparator}bin${Platform.pathSeparator}flutter${Platform.isWindows ? '.bat' : ''}',
      );
      if (candidate2.existsSync()) return true;
    }

    return false;
  }

   
  Future<String?> getFlutterVersion() async {
     
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n').first;
      }
    } catch (_) {}

     
    try {
      String? pathCandidate;
      if (Platform.isWindows) {
        final whereRes = await Process.run('where', ['flutter']);
        if (whereRes.exitCode == 0) {
          final out = whereRes.stdout.toString().trim();
          if (out.isNotEmpty)
            pathCandidate = out.split(RegExp(r'\r?\n')).first.trim();
        }
      } else {
        final whichRes = await Process.run('which', ['flutter']);
        if (whichRes.exitCode == 0) {
          final out = whichRes.stdout.toString().trim();
          if (out.isNotEmpty) pathCandidate = out.split('\n').first.trim();
        }
      }

      if (pathCandidate != null && pathCandidate.isNotEmpty) {
        final verRes = await Process.run(pathCandidate, ['--version']);
        if (verRes.exitCode == 0)
          return verRes.stdout.toString().split('\n').first;
      }
    } catch (_) {}

     
    final pathEnv =
        Platform.environment['PATH'] ?? Platform.environment['Path'] ?? '';
    final separator = Platform.isWindows ? ';' : ':';
    final entries = pathEnv.split(separator);
    for (var entry in entries) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      final candidate = Platform.isWindows
          ? '${trimmed}${Platform.pathSeparator}flutter.bat'
          : '${trimmed}${Platform.pathSeparator}flutter';
      try {
        final file = File(candidate);
        if (file.existsSync()) {
          final verRes = await Process.run(candidate, ['--version']);
          if (verRes.exitCode == 0)
            return verRes.stdout.toString().split('\n').first;
        }
      } catch (_) {}
    }

    return null;
  }

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
