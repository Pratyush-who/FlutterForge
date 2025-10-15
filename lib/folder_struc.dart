 
class FolderStructure {
   
  final String pattern;
  
   
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

 
class GeminiResponse {
   
  final List<String> packages;
  
   
  final List<String> appFlow;
  
   
  final FolderStructure folderStructure;
  
   
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