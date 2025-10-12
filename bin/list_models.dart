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
    print('GEMINI_API_KEY not found in .env or environment');
    exit(1);
  }

  final masked = apiKey.length > 4 ? '${apiKey.substring(0, 4)}****' : '****';
  print('Using GEMINI_API_KEY: $masked');

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1/models?key=$apiKey',
  );

  try {
    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    print('HTTP ${resp.statusCode}');
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final models = (json['models'] as List<dynamic>?) ?? [];
      if (models.isEmpty) {
        print('No models returned');
      } else {
        print('Available models:');
        for (var m in models) {
          final name = m['name'];
          final displayName = m['displayName'] ?? '';
          print(' - $name ${displayName.isNotEmpty ? '($displayName)' : ''}');
        }
      }
    } else {
      print('Response body: ${resp.body}');
    }
  } catch (e) {
    print('Network error: $e');
  }
}
