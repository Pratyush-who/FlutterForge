class GeminiResponse {
  final List<String> packages;

  final List<String> appFlow;

  final String notes;

  GeminiResponse({
    required this.packages,
    required this.appFlow,
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
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'packages': packages, 'appFlow': appFlow, 'notes': notes};
  }

  @override
  String toString() {
    return 'GeminiResponse(packages: $packages, appFlow: $appFlow, notes: $notes)';
  }
}
