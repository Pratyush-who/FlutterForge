import 'dart:convert';
import 'dart:io';
import 'package:flutterforge_cli/folder_struc.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  String _apiKey = '';

  GeminiService() {
    _loadApiKey();
  }

  void _loadApiKey() {
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx <= 0) continue;
          final key = line.substring(0, idx).trim();
          var value = line.substring(idx + 1).trim();
          if ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith('\'') && value.endsWith('\''))) {
            value = value.substring(1, value.length - 1);
          }
          if (key == 'GEMINI_API_KEY') {
            _apiKey = value;
            break;
          }
        }
      }
    } catch (_) {}

    if (_apiKey.isEmpty) {
      _apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    }

    // Silent loading - don't display API key or status
    if (_apiKey.isEmpty) {
      print('   ⚠️ GEMINI_API_KEY not found in .env or environment');
    }
  }

  Future<GeminiResponse?> analyzeProjectRequirements(
    String userInput,
    String? architecturePattern,
  ) async {
    if (_apiKey.isEmpty) {
      print('   ❌ API key not configured');
      return null;
    }

    try {
      final prompt = _buildPrompt(userInput, architecturePattern);
      final response = await _callGeminiApi(prompt);

      if (response != null) {
        return _parseResponse(response);
      }

      return null;
    } catch (e) {
      print('   ❌ Error: $e');
      return null;
    }
  }

  /// Regenerate recommendations with user modifications
  Future<GeminiResponse?> modifyRecommendations(
    String originalInput,
    String? architecture,
    String modifications,
    GeminiResponse currentResponse,
  ) async {
    if (_apiKey.isEmpty) {
      print('   ❌ API key not configured');
      return null;
    }

    try {
      final prompt =
          '''You are a Flutter architecture expert. The user wants to modify their project recommendations.

ORIGINAL PROJECT: "$originalInput"
${architecture != null ? 'ARCHITECTURE: $architecture (USER REQUESTED)' : ''}

CURRENT RECOMMENDATIONS:
- Packages (${currentResponse.packages.length}): ${currentResponse.packages.join(', ')}
- Architecture: ${currentResponse.folderStructure.pattern}
- Folders: ${currentResponse.folderStructure.folders.join(', ')}

USER REQUESTED CHANGES: "$modifications"

Apply the requested changes and return ONLY valid JSON with this EXACT structure:
{
  "packages": ["package1", "package2"],
  "appFlow": ["Screen1", "Screen2"],
  "folderStructure": {
    "pattern": "architecture-name",
    "folders": ["folder/path1", "folder/path2"]
  },
  "notes": "Brief guidance about changes made"
}

CRITICAL:
- Keep what the user didn't ask to change
- Add/remove/replace only what was requested
- Ensure all packages exist on pub.dev
- Maintain architecture consistency
- If unclear, interpret intelligently

Examples of changes:
- "add payment integration" → add razorpay_flutter, flutter_stripe
- "remove firebase" → remove all firebase_* packages
- "add maps" → add google_maps_flutter, geolocator
- "use bloc instead" → replace provider with flutter_bloc, bloc
- "add more folders for features" → add feature-specific folders
''';

      final response = await _callGeminiApi(prompt);
      if (response != null) {
        return _parseResponse(response);
      }
      return null;
    } catch (e) {
      print('   ❌ Error: $e');
      return null;
    }
  }

  String _buildPrompt(String userInput, String? architecture) {
    return '''You are a Flutter architecture expert. Analyze this project and provide recommendations.

PROJECT: "$userInput"
${architecture != null ? 'ARCHITECTURE: $architecture (USER REQUESTED - MUST USE THIS)' : 'ARCHITECTURE: Choose the best pattern'}

Return ONLY valid JSON with this EXACT structure:
{
  "packages": ["package1", "package2"],
  "appFlow": ["Screen1", "Screen2"],
  "folderStructure": {
    "pattern": "architecture-name",
    "folders": ["folder/path1", "folder/path2"]
  },
  "notes": "Brief guidance"
}

RULES:
1. For ${architecture ?? 'any architecture'}, generate appropriate folder structure
2. Recommend 8-15 packages from pub.dev based on complexity
3. Include state management (riverpod/bloc/provider)
4. For e-commerce: dio, firebase_auth, cloud_firestore, image_picker, google_maps_flutter, razorpay_flutter, go_router, cached_network_image, shimmer
5. For social apps: firebase suite, image_picker, video_player, share_plus
6. For simple apps: fewer packages (provider, hive, intl)

ARCHITECTURE PATTERNS:
- mvvm: ["models", "views/screens", "views/widgets", "viewmodels", "services", "repositories", "utils", "constants"]
- mvc: ["models", "views/screens", "views/widgets", "controllers", "services", "utils", "constants"]
- clean: ["data/models", "data/repositories", "data/datasources/remote", "data/datasources/local", "domain/entities", "domain/usecases", "domain/repositories", "presentation/screens", "presentation/widgets", "presentation/bloc", "core/utils", "core/constants", "core/network"]
- feature-first: ["features/auth/data", "features/auth/domain", "features/auth/presentation", "features/home/data", "features/home/domain", "features/home/presentation", "core/network", "core/utils", "shared/widgets"]

${architecture != null && ![
              'mvvm',
              'mvc',
              'clean',
              'feature-first'
            ].contains(architecture.toLowerCase()) ? 'CUSTOM: Interpret "$architecture" and create meaningful folders based on the description.' : ''}

CRITICAL: Return ONLY the JSON object. No markdown, no explanations.''';
  }

  Future<String?> _callGeminiApi(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 8192,
          'responseMimeType': 'application/json',
        },
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          print('\n   📄 Response received\n');
          return text.toString();
        }
      } else {
        print('   API Error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('   Network Error: $e');
      return null;
    }
  }

  GeminiResponse _parseResponse(String responseText) {
    try {
      String cleanedText = responseText.trim();

      // Remove markdown code blocks if present
      cleanedText = cleanedText.replaceAll(RegExp(r'```json\s*'), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'```\s*'), '');
      cleanedText = cleanedText.trim();

      // Find JSON object boundaries
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }

      final json = jsonDecode(cleanedText);

      // Validate required fields
      if (json['folderStructure'] == null ||
          json['folderStructure']['folders'] == null ||
          (json['folderStructure']['folders'] as List).isEmpty) {
        print('   ⚠️ Warning: Invalid folder structure in response');
        throw FormatException('Missing folder structure');
      }

      return GeminiResponse.fromJson(json);
    } catch (e) {
      print('   ❌ Parse Error: $e');
      print(
        '   Response was: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...',
      );
      rethrow;
    }
  }
}
