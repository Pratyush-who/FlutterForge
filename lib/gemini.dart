import 'dart:convert';
import 'dart:io';
import 'package:flutterforge/folder_struc.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-pro:generateContent';
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

    if (_apiKey.isNotEmpty) {
      final masked = _apiKey.length > 4
          ? '${_apiKey.substring(0, 4)}****'
          : '****';
      print('🔑 GEMINI_API_KEY loaded: $masked');
    } else {
      print('⚠️ GEMINI_API_KEY not found in .env or environment variables');
    }
  }

  /// Analyzes project requirements with enhanced architecture detection
  Future<GeminiResponse?> analyzeProjectRequirements(
    String userInput,
    String? architecturePattern,
  ) async {
    if (_apiKey.isEmpty) {
      print(
        '❌ API key not configured. Please set GEMINI_API_KEY in .env file.',
      );
      return null;
    }

    try {
      final prompt = _buildEnhancedPrompt(userInput, architecturePattern);
      final response = await _callGeminiApi(prompt);

      if (response != null) {
        final parsed = _parseResponse(response);

        if ((parsed.packages.isEmpty && parsed.appFlow.isEmpty) ||
            parsed.notes.isEmpty) {
          return _localFallback(userInput, architecturePattern);
        }

        return parsed;
      }

      return _localFallback(userInput, architecturePattern);
    } catch (e) {
      print('❌ Error calling Gemini API: $e');
      return _localFallback(userInput, architecturePattern);
    }
  }

  /// Enhanced prompt with better edge case handling
  String _buildEnhancedPrompt(String userInput, String? architecture) {
    final archInfo = architecture != null 
        ? '\n\nThe developer wants to use "$architecture" architecture pattern.'
        : '';

    return '''
You are an expert Flutter architect and developer. Analyze this project requirement carefully:

PROJECT: "$userInput"$archInfo

Provide recommendations in VALID JSON format ONLY. No markdown, no code blocks, no extra text.

CRITICAL RULES:
1. Return ONLY the JSON object - nothing before or after
2. Use real, published Flutter packages from pub.dev
3. Consider the project's complexity and scale
4. Include essential packages first, then optional enhancements
5. Ensure packages work together without conflicts
6. Suggest 5-10 packages maximum (avoid over-engineering)
7. Include state management appropriate for project size
8. Add packages for: networking, storage, navigation, UI components
9. Consider platform-specific needs (iOS/Android/Web)
10. Avoid deprecated or unmaintained packages

Response format:
{
  "packages": ["package1", "package2"],
  "appFlow": ["Screen1", "Screen2", "Screen3"],
  "folderStructure": {
    "pattern": "mvvm|mvc|clean|feature-first|auto-detect",
    "folders": ["folder1", "folder2"]
  },
  "notes": "Implementation guidance (max 150 chars)"
}

FOLDER STRUCTURE PATTERNS:
- "mvvm": models/, views/, viewmodels/, services/, utils/
- "mvc": models/, views/, controllers/, services/, utils/
- "clean": data/, domain/, presentation/, core/
- "feature-first": features/, core/, shared/
- "auto-detect": Analyze the project and choose the best pattern

EDGE CASES TO HANDLE:
- Vague descriptions: Ask for clarification in notes, provide general packages
- E-commerce: payment gateways, cart management, product catalogs
- Social apps: auth, real-time updates, media handling, chat
- Enterprise: offline-first, sync, security, scalability
- Games: game engines, physics, audio, animations
- IoT/Hardware: bluetooth, sensors, permissions
- Media apps: video/audio players, streaming, compression
- Educational: progress tracking, quizzes, content delivery
- Health/Fitness: sensors, tracking, charts, notifications
- Finance: encryption, biometrics, secure storage
- Location-based: maps, geolocation, tracking
- Small utility: minimal packages, simple structure
- Large enterprise: modular architecture, testing, CI/CD support

PACKAGE SELECTION GUIDELINES:
- State management: provider (simple), riverpod (medium), bloc (complex)
- HTTP: http (basic), dio (advanced)
- Local storage: shared_preferences (simple), hive/sqflite (complex)
- Navigation: go_router (modern), auto_route (advanced)
- UI: flutter_screenutil, cached_network_image, shimmer
- Auth: firebase_auth, flutter_secure_storage
- Forms: flutter_form_builder, validators
- Images: image_picker, photo_view, flutter_cache_manager

EXAMPLES:

For "a simple note-taking app":
{"packages":["provider","sqflite","intl","flutter_slidable"],"appFlow":["Home","AddNote","NoteDetail","Settings"],"folderStructure":{"pattern":"mvvm","folders":["models","views","viewmodels","services","utils"]},"notes":"Use provider for state, sqflite for local persistence, simple MVVM pattern"}

For "social media app with real-time chat":
{"packages":["firebase_core","firebase_auth","cloud_firestore","firebase_messaging","cached_network_image","image_picker","provider","go_router"],"appFlow":["Splash","Auth","Feed","Chat","Profile","CreatePost"],"folderStructure":{"pattern":"feature-first","folders":["features/auth","features/feed","features/chat","features/profile","core","shared"]},"notes":"Firebase for backend, feature-first for scalability, provider for state"}

For "e-commerce app":
{"packages":["riverpod","dio","flutter_secure_storage","cached_network_image","carousel_slider","razorpay_flutter","go_router"],"appFlow":["Splash","Home","Products","ProductDetail","Cart","Checkout","Orders","Profile"],"folderStructure":{"pattern":"clean","folders":["data/models","data/repositories","domain/entities","domain/usecases","presentation/screens","presentation/widgets","core"]},"notes":"Clean architecture for maintainability, Riverpod for complex state, Dio for API calls"}

Now analyze: "$userInput"

Remember: Return ONLY valid JSON, no additional text or formatting.
''';
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
          'temperature': 0.4, // Lower for more consistent JSON
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048, // Increased for detailed responses
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
        if (text != null) return text.toString();
        return response.body;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return null;
    }
  }

  GeminiResponse _parseResponse(String responseText) {
    try {
      String cleanedText = responseText.trim();

      // Remove markdown code blocks
      cleanedText = cleanedText.replaceAll(RegExp(r'```json\s*'), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'```\s*'), '');
      cleanedText = cleanedText.trim();

      // Find JSON object
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }

      final json = jsonDecode(cleanedText);
      return GeminiResponse.fromJson(json);
    } catch (e) {
      print('⚠️  Warning: Could not parse response. Using fallback...');
      return _fallbackParse(responseText);
    }
  }

  GeminiResponse _fallbackParse(String text) {
    final packages = <String>[];
    final appFlow = <String>[];
    var notes = 'Check the response above for more details.';

    // Extract package names
    final packageRegex = RegExp(r'`([a-z_][a-z0-9_]*)`');
    final matches = packageRegex.allMatches(text);
    for (var match in matches) {
      final pkg = match.group(1);
      if (pkg != null && !packages.contains(pkg)) {
        packages.add(pkg);
      }
    }

    // Extract screen names
    final flowRegex = RegExp(
      r'\b(Splash|Login|Home|Profile|Settings|Detail|List|Dashboard|Auth|Feed|Chat|Cart|Checkout|Orders|Products)\b',
      caseSensitive: false,
    );
    final flowMatches = flowRegex.allMatches(text);
    for (var match in flowMatches) {
      final screen = match.group(0);
      if (screen != null && !appFlow.contains(screen)) {
        appFlow.add(screen);
      }
    }

    return GeminiResponse(
      packages: packages.isEmpty ? ['provider', 'http'] : packages,
      appFlow: appFlow.isEmpty ? ['Splash', 'Home'] : appFlow,
      folderStructure: FolderStructure(
        pattern: 'mvvm',
        folders: ['models', 'views', 'viewmodels', 'services', 'utils'],
      ),
      notes: notes,
    );
  }

  /// Enhanced local fallback with architecture support
  GeminiResponse _localFallback(String userInput, String? architecture) {
    final lower = userInput.toLowerCase();
    final packages = <String>{'provider', 'http'};
    final flow = <String>[];
    var notes = 'Basic setup with common packages.';

    // Detect project type and add relevant packages
    if (lower.contains('e-commerce') || lower.contains('shop')) {
      packages.addAll([
        'dio',
        'cached_network_image',
        'flutter_secure_storage',
        'razorpay_flutter',
        'go_router',
      ]);
      flow.addAll(['Splash', 'Home', 'Products', 'Cart', 'Checkout', 'Profile']);
      notes = 'E-commerce setup with payment integration.';
    } else if (lower.contains('social') || lower.contains('chat')) {
      packages.addAll([
        'firebase_core',
        'firebase_auth',
        'cloud_firestore',
        'firebase_messaging',
        'cached_network_image',
        'image_picker',
      ]);
      flow.addAll(['Splash', 'Auth', 'Feed', 'Chat', 'Profile']);
      notes = 'Social app with real-time features.';
    } else if (lower.contains('firebase')) {
      packages.addAll([
        'firebase_core',
        'firebase_auth',
        'cloud_firestore',
        'firebase_messaging',
      ]);
      flow.addAll(['Splash', 'Auth', 'Home', 'Profile']);
      notes = 'Firebase-powered app setup.';
    } else if (lower.contains('camera') || lower.contains('photo')) {
      packages.addAll(['camera', 'image_picker', 'photo_view']);
      flow.addAll(['Home', 'Camera', 'Gallery', 'Preview']);
      notes = 'Camera and image handling app.';
    } else if (lower.contains('map') || lower.contains('location')) {
      packages.addAll(['google_maps_flutter', 'geolocator', 'geocoding']);
      flow.addAll(['Home', 'Map', 'LocationDetail', 'Settings']);
      notes = 'Location-based app with maps.';
    } else {
      flow.addAll(['Splash', 'Home', 'Detail', 'Settings']);
      notes = 'General app setup.';
    }

    // Determine folder structure based on architecture
    final folderStructure = _getFolderStructure(architecture ?? 'mvvm', lower);

    return GeminiResponse(
      packages: packages.toList(),
      appFlow: flow,
      folderStructure: folderStructure,
      notes: notes,
    );
  }

  /// Gets folder structure based on architecture pattern
  FolderStructure _getFolderStructure(String pattern, String projectType) {
    switch (pattern.toLowerCase()) {
      case 'clean':
      case 'clean architecture':
        return FolderStructure(
          pattern: 'clean',
          folders: [
            'data/models',
            'data/repositories',
            'data/datasources',
            'domain/entities',
            'domain/usecases',
            'domain/repositories',
            'presentation/screens',
            'presentation/widgets',
            'presentation/bloc',
            'core/utils',
            'core/constants',
            'core/errors',
          ],
        );
      case 'mvc':
        return FolderStructure(
          pattern: 'mvc',
          folders: [
            'models',
            'views/screens',
            'views/widgets',
            'controllers',
            'services',
            'utils',
            'constants',
          ],
        );
      case 'feature-first':
      case 'feature':
        return FolderStructure(
          pattern: 'feature-first',
          folders: [
            'features/auth/data',
            'features/auth/domain',
            'features/auth/presentation',
            'features/home/data',
            'features/home/domain',
            'features/home/presentation',
            'core/network',
            'core/utils',
            'shared/widgets',
            'shared/constants',
          ],
        );
      case 'mvvm':
      default:
        return FolderStructure(
          pattern: 'mvvm',
          folders: [
            'models',
            'views/screens',
            'views/widgets',
            'viewmodels',
            'services',
            'repositories',
            'utils',
            'constants',
          ],
        );
    }
  }
}