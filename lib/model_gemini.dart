/// Model class to hold parsed Gemini API response
class GeminiResponse {
  /// List of recommended Flutter packages
  final List<String> packages;

  /// Suggested app flow/navigation structure
  final List<String> appFlow;

  /// Additional notes or recommendations
  final String notes;

  GeminiResponse({
    required this.packages,
    required this.appFlow,
    required this.notes,
  });

  /// Creates a GeminiResponse from JSON
  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      packages:
          (json['packages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appFlow:
          (json['appFlow'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: json['notes']?.toString() ?? '',
    );
  }

  /// Converts GeminiResponse to JSON
  Map<String, dynamic> toJson() {
    return {'packages': packages, 'appFlow': appFlow, 'notes': notes};
  }

  @override
  String toString() {
    return 'GeminiResponse(packages: $packages, appFlow: $appFlow, notes: $notes)';
  }
}
