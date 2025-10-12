import 'dart:convert';
import 'dart:io';

import 'package:flutterforge/model_gemini.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // Use a model that the API key has access to (discovered via ListModels)
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-pro:generateContent';
  String _apiKey = '';

  /// Constructor - loads API key from .env
  GeminiService() {
    _loadApiKey();
  }

  void _loadApiKey() {
    // Try to read GEMINI_API_KEY from a local .env file (simple parser)
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
    } catch (_) {
      // ignore parse errors and fall back to environment variables
    }

    // Fallback to environment variable if not found in .env
    if (_apiKey.isEmpty) {
      _apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    }

    // Debug: print masked API key source (do not reveal full key)
    if (_apiKey.isNotEmpty) {
      final masked = _apiKey.length > 4
          ? '${_apiKey.substring(0, 4)}****'
          : '****';
      print('🔑 GEMINI_API_KEY loaded: $masked');
    } else {
      print('⚠️ GEMINI_API_KEY not found in .env or environment variables');
    }
  }

  /// Analyzes project requirements using Gemini API
  Future<GeminiResponse?> analyzeProjectRequirements(String userInput) async {
    if (_apiKey.isEmpty) {
      print(
        '❌ API key not configured. Please set GEMINI_API_KEY in .env file.',
      );
      return null;
    }

    try {
      final prompt = _buildPrompt(userInput);
      final response = await _callGeminiApi(prompt);

      if (response != null) {
        final parsed = _parseResponse(response);

        // If parsed result is empty or not useful, use deterministic local fallback
        if ((parsed.packages.isEmpty && parsed.appFlow.isEmpty) ||
            parsed.notes.isEmpty) {
          return _localFallback(userInput);
        }

        return parsed;
      }

      // If API failed, return a local deterministic suggestion
      return _localFallback(userInput);
    } catch (e) {
      print('❌ Error calling Gemini API: $e');
      return null;
    }
  }

  /// Builds the prompt for Gemini
  String _buildPrompt(String userInput) {
    return '''
You are a Flutter development expert. A developer wants to build: "$userInput"

Analyze this requirement and provide recommendations in VALID JSON format only. Do not include any markdown formatting, code blocks, or extra text. Return ONLY the JSON object.

Response format:
{
  "packages": ["package1", "package2", "package3"],
  "appFlow": ["Screen1", "Screen2", "Screen3"],
  "notes": "Brief implementation guidance"
}

Rules:
- "packages": List of Flutter package names (without version numbers)
- "appFlow": List of screen names showing navigation flow (3-5 screens)
- "notes": One concise sentence about implementation (max 100 chars)
- Return ONLY valid JSON, no markdown, no code blocks, no extra text
- Use real Flutter package names from pub.dev
- Be specific and practical

Example for "a todo app":
{"packages":["provider","sqflite","intl"],"appFlow":["Splash","Home","AddTask","TaskDetail"],"notes":"Use provider for state management and sqflite for local storage"}

Now analyze: "$userInput"
''';
  }

  /// Calls Gemini API
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
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
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

        // If the structured 'text' field is missing, return the whole body
        // so the fallback parser can try to extract useful info.
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

  /// Parses Gemini response into GeminiResponse object
  GeminiResponse _parseResponse(String responseText) {
    try {
      // Clean the response - remove markdown code blocks if present
      String cleanedText = responseText.trim();

      // Remove markdown code blocks
      cleanedText = cleanedText.replaceAll(RegExp(r'```json\s*'), '');
      cleanedText = cleanedText.replaceAll(RegExp(r'```\s*'), '');
      cleanedText = cleanedText.trim();

      // Find JSON object in the text
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }

      final json = jsonDecode(cleanedText);
      return GeminiResponse.fromJson(json);
    } catch (e) {
      print(
        '⚠️  Warning: Could not parse structured response. Using fallback...',
      );
      // Fallback: try to extract information from plain text
      return _fallbackParse(responseText);
    }
  }

  GeminiResponse _fallbackParse(String text) {
    final packages = <String>[];
    final appFlow = <String>[];
    var notes = 'Check the response above for more details.';

    // Try to extract package names
    final packageRegex = RegExp(r'`([a-z_]+)`');
    final matches = packageRegex.allMatches(text);
    for (var match in matches) {
      final pkg = match.group(1);
      if (pkg != null && !packages.contains(pkg)) {
        packages.add(pkg);
      }
    }

    // Try to extract screen flow
    final flowRegex = RegExp(
      r'(Splash|Login|Home|Profile|Settings|Detail|List|Dashboard)',
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
      notes: notes,
    );
  }

  /// Deterministic local fallback to produce concrete recommendations
  GeminiResponse _localFallback(String userInput) {
    final lower = userInput.toLowerCase();
    final packages = <String>{'provider', 'http'};
    final flow = <String>[];
    var notes = 'Use provider for state management.';

    if (lower.contains('firebase')) {
      packages.addAll([
        'firebase_core',
        'firebase_auth',
        'cloud_firestore',
        'firebase_messaging',
      ]);
      notes = 'Integrate Firebase for backend and notifications.';
    }
    if (lower.contains('camera')) {
      packages.add('camera');
      packages.add('image_picker');
      notes = '${notes} Use camera/image_picker for photo capture.';
    }
    if (lower.contains('notification')) {
      packages.add('flutter_local_notifications');
      packages.add('firebase_messaging');
      notes = '${notes} Add local and push notifications.';
    }

    flow.addAll(['Splash', 'Onboarding', 'Home']);

    flow.add('HomeTabs: Tasks, Camera, Notifications, Profile');

    return GeminiResponse(
      packages: packages.toList(),
      appFlow: flow,
      notes: notes,
    );
  }
}
