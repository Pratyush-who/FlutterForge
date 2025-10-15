import 'dart:io';
import 'package:flutterforge_cli/folder_struc.dart';
import 'cli_helper.dart';

 
class FolderCreator {
  final _cliHelper = CliHelper();

   
  Future<bool> createFolderStructure(
    FolderStructure structure,
    String projectPath,
  ) async {
    try {
      _cliHelper.printSection('\n📁 Creating folder structure...');
      _cliHelper.printInfo('   Architecture: ${structure.pattern}');

      final libPath = '$projectPath/lib';
      final libDir = Directory(libPath);

      if (!libDir.existsSync()) {
        _cliHelper.printError('   ✗ lib/ directory not found!');
        return false;
      }

      var createdCount = 0;
      var skippedCount = 0;

      for (var i = 0; i < structure.folders.length; i++) {
        final folder = structure.folders[i];
        final folderPath = '$libPath/$folder';
        final dir = Directory(folderPath);

        if (dir.existsSync()) {
          _cliHelper.printWarning('   ⊙ $folder (already exists)');
          skippedCount++;
        } else {
          await dir.create(recursive: true);
          _cliHelper.printSuccess('   ✓ Created: $folder');

           
          final gitkeepFile = File('$folderPath/.gitkeep');
           
          await gitkeepFile.writeAsString('', flush: true);

          createdCount++;
        }

         
        _cliHelper.showProgress(i + 1, structure.folders.length);
      }

      print('');  
      _cliHelper.printSuccess('\n   ✓ Folder structure created successfully!');
      _cliHelper.printInfo(
        '   Summary: $createdCount created, $skippedCount already existed',
      );

       
      await _createArchitectureReadme(structure, libPath);

      return true;
    } catch (e) {
      _cliHelper.printError('   ✗ Error creating folders: $e');
      return false;
    }
  }

   
  Future<void> _createArchitectureReadme(
    FolderStructure structure,
    String libPath,
  ) async {
    final readmePath = '$libPath/ARCHITECTURE.md';
    final readmeFile = File(readmePath);

    String content;
    switch (structure.pattern.toLowerCase()) {
      case 'clean':
        content = _getCleanArchitectureReadme();
        break;
      case 'mvc':
        content = _getMvcReadme();
        break;
      case 'feature-first':
        content = _getFeatureFirstReadme();
        break;
      case 'mvvm':
      default:
        content = _getMvvmReadme();
        break;
    }

    await readmeFile.writeAsString(content);
    _cliHelper.printSuccess('   ✓ Created ARCHITECTURE.md guide');
  }

  String _getMvvmReadme() {
    return '''# MVVM Architecture

This project follows the **Model-View-ViewModel (MVVM)** pattern.

## Structure

- **models/**: Data models and entities
- **views/**: UI components (screens and widgets)
  - **screens/**: Full-page screens
  - **widgets/**: Reusable UI components
- **viewmodels/**: Business logic and state management
- **services/**: API calls, database operations
- **repositories/**: Data access layer
- **utils/**: Helper functions and utilities
- **constants/**: App-wide constants

## Flow

1. **View** displays UI and handles user interactions
2. **ViewModel** processes business logic and manages state
3. **Model** represents data structures
4. **Service/Repository** handles data operations

## Best Practices

- Keep Views simple, only UI code
- ViewModels handle all business logic
- Use dependency injection
- Maintain separation of concerns
''';
  }

  String _getMvcReadme() {
    return '''# MVC Architecture

This project follows the **Model-View-Controller (MVC)** pattern.

## Structure

- **models/**: Data models and business entities
- **views/**: UI layer
  - **screens/**: Full-page screens
  - **widgets/**: Reusable components
- **controllers/**: Business logic and data manipulation
- **services/**: External API and database interactions
- **utils/**: Helper functions
- **constants/**: App constants

## Flow

1. **View** sends user actions to Controller
2. **Controller** processes logic and updates Model
3. **Model** notifies View of changes
4. **Service** handles external data operations

## Best Practices

- Controllers manage app logic
- Views only render UI
- Models are data containers
- Use services for external operations
''';
  }

  String _getCleanArchitectureReadme() {
    return '''# Clean Architecture

This project follows **Clean Architecture** principles by Uncle Bob.

## Structure

### Data Layer
- **data/models/**: Data transfer objects
- **data/repositories/**: Repository implementations
- **data/datasources/**: Local and remote data sources

### Domain Layer
- **domain/entities/**: Business objects
- **domain/usecases/**: Business logic operations
- **domain/repositories/**: Repository interfaces

### Presentation Layer
- **presentation/screens/**: UI screens
- **presentation/widgets/**: Reusable widgets
- **presentation/bloc/**: State management

### Core
- **core/utils/**: Utilities
- **core/constants/**: Constants
- **core/errors/**: Error handling

## Principles

1. **Dependency Rule**: Dependencies point inward
2. **Separation of Concerns**: Each layer has specific responsibility
3. **Testability**: Easy to test each layer independently
4. **Maintainability**: Changes in one layer don't affect others

## Flow

Presentation → Domain (UseCases) → Data → External APIs/DB
''';
  }

  String _getFeatureFirstReadme() {
    return '''# Feature-First Architecture

This project organizes code by **features** rather than technical layers.

## Structure

Each feature has its own folder with:
- **data/**: Models, repositories, data sources
- **domain/**: Business logic, entities, use cases
- **presentation/**: UI screens, widgets, state management

### Shared Resources
- **core/**: Networking, utilities, base classes
- **shared/**: Shared widgets, constants

## Benefits

- **Scalability**: Easy to add/remove features
- **Team Collaboration**: Teams can work on separate features
- **Modularity**: Features can be extracted into packages
- **Clear Boundaries**: Each feature is self-contained

## Example Features

```
features/
  auth/
    data/
    domain/
    presentation/
  home/
    data/
    domain/
    presentation/
```

## Best Practices

- Keep features independent
- Share common code via core/ and shared/
- Each feature should be a mini-clean-architecture
''';
  }

   
  bool isFlutterProject(String path) {
    final pubspecFile = File('$path/pubspec.yaml');
    final libDir = Directory('$path/lib');
    return pubspecFile.existsSync() && libDir.existsSync();
  }

   
  String? getCurrentProjectPath() {
    final currentDir = Directory.current.path;
    if (isFlutterProject(currentDir)) {
      return currentDir;
    }
    return null;
  }
}
