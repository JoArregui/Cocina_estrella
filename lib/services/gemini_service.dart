import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_key_service.dart';
import 'ai_service.dart';

class GeminiResult {
  final List<String> ingredients;
  final List<RecipeSuggestion> suggestions;
  GeminiResult({required this.ingredients, required this.suggestions});
}

class RecipeSuggestion {
  final String name;
  final String nameEs;
  final String description;
  final String difficulty;
  final String time;
  final int matchPercent;

  RecipeSuggestion({
    required this.name,
    required this.nameEs,
    required this.description,
    required this.difficulty,
    required this.time,
    required this.matchPercent,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> j) {
    return RecipeSuggestion(
      name: j['name'] ?? '',
      nameEs: j['name_es'] ?? j['name'] ?? '',
      description: j['description'] ?? '',
      difficulty: j['difficulty'] ?? 'Media',
      time: j['time'] ?? '30 min',
      matchPercent: (j['match_percent'] is int)
          ? j['match_percent'] as int
          : int.tryParse(j['match_percent'].toString()) ?? 80,
    );
  }
}

class GeminiService implements AIService {
  static const _model = 'gemini-2.0-flash';
  static const _timeout = Duration(seconds: 20);
  final http.Client _client;
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get providerName => _useProxy ? 'gemini:proxy' : 'gemini:$_model';

  @override
  bool get isConfigured => _useProxy || ApiKeyService.isValid(ApiKeyService.getKey());

  /// Si se define GEMINI_PROXY_URL vía --dart-define, todas las llamadas
  /// van al backend proxy (Cloud Functions / Cloud Run) que custodia la key.
  /// Ejemplo: --dart-define=GEMINI_PROXY_URL=https://api.tuapp.com/gemini
  /// El proxy debe exponer POST /analyze con {parts, generationConfig}
  /// y devolver el mismo JSON que Gemini.
  static String get proxyUrl => const String.fromEnvironment('GEMINI_PROXY_URL');

  bool get _useProxy => proxyUrl.isNotEmpty;

  @override
  Future<GeminiResult> analyze({
    File? image,
    String? textIngredients,
  }) async {
    if (!_useProxy) {
      final apiKey = ApiKeyService.getKey();
      if (!ApiKeyService.isValid(apiKey)) {
        throw Exception('API Key no configurada. Define GEMINI_API_KEY vía --dart-define o .env, o configura GEMINI_PROXY_URL');
      }
    }

    final parts = <Map<String, dynamic>>[];

    if (image != null) {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': b64}
      });
      parts.add({
        'text': '''Analiza la imagen y detecta todos los ingredientes de cocina que ves.
Luego sugiere 5 platos que se puedan cocinar con esos ingredientes.

Responde SOLO con este JSON (sin markdown, sin texto extra):
{
  "ingredients": ["ingrediente1", "ingrediente2"],
  "suggestions": [
    {
      "name": "Dish name in English for TheMealDB search",
      "name_es": "Nombre en español",
      "description": "Descripción apetitosa en 1-2 frases",
      "difficulty": "Fácil",
      "time": "30 min",
      "match_percent": 90
    }
  ]
}'''
      });
    } else if (textIngredients != null && textIngredients.trim().isNotEmpty) {
      parts.add({
        'text': '''Tengo estos ingredientes: ${textIngredients.trim()}

Sugiere 5 platos deliciosos que pueda cocinar con ellos (asume básicos de despensa: aceite, sal, pimienta, ajo).

Responde SOLO con este JSON (sin markdown, sin texto extra):
{
  "ingredients": ["ingrediente1", "ingrediente2"],
  "suggestions": [
    {
      "name": "Dish name in English for TheMealDB search",
      "name_es": "Nombre en español",
      "description": "Descripción apetitosa en 1-2 frases",
      "difficulty": "Fácil",
      "time": "30 min",
      "match_percent": 90
    }
  ]
}'''
      });
    } else {
      throw Exception('Debes proporcionar imagen o lista de ingredientes');
    }

    final Uri uri;
    final Map<String, String> headers;
    final String body;

    if (_useProxy) {
      // Modo proxy: la key no sale del backend
      uri = Uri.parse('$proxyUrl/analyze');
      headers = {'Content-Type': 'application/json'};
      body = jsonEncode({'parts': parts, 'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7}});
    } else {
      final apiKey = ApiKeyService.getKey()!;
      uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey');
      headers = {'Content-Type': 'application/json'};
      body = jsonEncode({'contents': [{'parts': parts}], 'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7}});
    }

    final response = await _client.post(uri, headers: headers, body: body).timeout(_timeout);

    if (response.statusCode == 400 || response.statusCode == 403) {
      throw Exception('API Key inválida (HTTP ${response.statusCode})');
    }
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error']?['message'] ?? 'HTTP ${response.statusCode}');
      } catch (_) {
        throw Exception('Error Gemini HTTP ${response.statusCode}');
      }
    }

    final data = jsonDecode(response.body);
    // Proxy devuelve directamente {ingredients, suggestions} o formato Gemini
    if (data is Map && data.containsKey('ingredients') && data.containsKey('suggestions')) {
      final ingredients = (data['ingredients'] as List).map((e) => e.toString()).toList();
      final suggestions = (data['suggestions'] as List).map((s) => RecipeSuggestion.fromJson(s as Map<String, dynamic>)).toList();
      return GeminiResult(ingredients: ingredients, suggestions: suggestions);
    }
    final rawText = data['candidates'][0]['content']['parts'][0]['text'] as String;
    String clean = rawText.trim();
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (jsonMatch != null) clean = jsonMatch.group(0)!;
    final parsed = jsonDecode(clean);

    final ingredients = (parsed['ingredients'] as List).map((e) => e.toString()).toList();
    final suggestions = (parsed['suggestions'] as List).map((s) => RecipeSuggestion.fromJson(s as Map<String, dynamic>)).toList();

    return GeminiResult(ingredients: ingredients, suggestions: suggestions);
  }
}
