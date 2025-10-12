#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

String _loadApiKey() {
  var apiKey = '';
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
          apiKey = value;
          break;
        }
      }
    }
  } catch (_) {}
  if (apiKey.isEmpty) apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  return apiKey;
}

Future<void> main() async {
  final apiKey = _loadApiKey();
  if (apiKey.isEmpty) {
    print('GEMINI_API_KEY not found');
    exit(1);
  }

  final endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-pro:generateContent?key=$apiKey';
  final url = Uri.parse(endpoint);

  final prompt =
      'Give me 3 recommended packages for a todo app with firebase and camera in Flutter.';

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
      'maxOutputTokens': 512,
    },
  });

  try {
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('HTTP ${resp.statusCode}');
    print('BODY: ${resp.body}');
  } catch (e) {
    print('Network error: $e');
  }
}
