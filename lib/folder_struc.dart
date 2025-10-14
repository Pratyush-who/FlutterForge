/// Folder structure configuration
class FolderStructure {
  /// Architecture pattern (mvvm, mvc, clean, feature-first)
  final String pattern;
  
  /// List of folder paths to create
  final List<String> folders;

  FolderStructure({
    required this.pattern,
    required this.folders,
  });

  factory FolderStructure.fromJson(Map<String, dynamic> json) {
    return FolderStructure(
      pattern: json['pattern']?.toString() ?? 'mvvm',
      folders: (json['folders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'folders': folders,
    };
  }

  @override
  String toString() {
    return 'FolderStructure(pattern: $pattern, folders: ${folders.length} folders)';
  }
}

/// Model class to hold parsed Gemini API response
class GeminiResponse {
  /// List of recommended Flutter packages
  final List<String> packages;
  
  /// Suggested app flow/navigation structure
  final List<String> appFlow;
  
  /// Folder structure configuration
  final FolderStructure folderStructure;
  
  /// Additional notes or recommendations
  final String notes;

  GeminiResponse({
    required this.packages,
    required this.appFlow,
    required this.folderStructure,
    required this.notes,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      packages: (json['packages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appFlow: (json['appFlow'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      folderStructure: json['folderStructure'] != null
          ? FolderStructure.fromJson(
              json['folderStructure'] as Map<String, dynamic>)
          : FolderStructure(
              pattern: 'mvvm',
              folders: [],
            ),
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packages': packages,
      'appFlow': appFlow,
      'folderStructure': folderStructure.toJson(),
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'GeminiResponse(packages: ${packages.length}, appFlow: ${appFlow.length}, folderStructure: $folderStructure, notes: $notes)';
  }
}