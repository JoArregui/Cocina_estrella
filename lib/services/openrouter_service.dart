import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'gemini_service.dart';

/// Proveedor Free vía OpenRouter (https://openrouter.ai)
/// Soporta modelos 100% free sin tarjeta: Muse Spark family, Nemotron, Llama Vision.
///
/// Configuración:
///   --dart-define=OPENROUTER_API_KEY=sk-or-...
///   --dart-define=AI_PROVIDER=muse-spark  (o nemotron, auto)
///   --dart-define=AI_MODEL=meta-llama/llama-3.2-3b-instruct:free  (override)
///
/// Modelos óptimos seleccionados para este proyecto:
/// - Texto (lista ingredientes): Muse Spark family -> meta-llama/llama-3.2-3b-instruct:free (rápido, español nativo, JSON fiable)
/// - Visión (foto): meta-llama/llama-3.2-11b-vision-instruct:free (soporta image_url, free)
/// - Alternativa Nemotron: nvidia/llama-3.1-nemotron-70b-instruct:free (más reasoning, más lento)
///
/// Ambos son :free en OpenRouter (sin coste, rate-limit 50 req/día por IP sin key, 1000/día con key free).
class OpenRouterService implements AIService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _timeout = Duration(seconds: 25);
  final http.Client _client;

  // Modelos free óptimos para Cocina Estrella
  static const _museSparkModel = 'meta-llama/llama-3.2-3b-instruct:free';
  static const _visionModel = 'meta-llama/llama-3.2-11b-vision-instruct:free';
  static const _nemotronModel = 'nvidia/llama-3.1-nemotron-70b-instruct:free';

  OpenRouterService({http.Client? client}) : _client = client ?? http.Client();

  static String get apiKey {
    const dartDefine = String.fromEnvironment('OPENROUTER_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    try {
      final env = dotenv.maybeGet('OPENROUTER_API_KEY');
      if (env != null && env.isNotEmpty) return env;
    } catch (_) {}
    return '';
  }

  static String get aiProvider =>
      const String.fromEnvironment('AI_PROVIDER', defaultValue: 'muse-spark');
  static String get customModel => const String.fromEnvironment('AI_MODEL');

  @override
  String get providerName {
    if (customModel.isNotEmpty) return 'openrouter:$customModel';
    if (aiProvider == 'nemotron') return 'openrouter:nemotron';
    return 'openrouter:muse-spark';
  }

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  String _textModel() {
    if (customModel.isNotEmpty) return customModel;
    if (aiProvider == 'nemotron') return _nemotronModel;
    return _museSparkModel; // default óptimo: Muse Spark family
  }

  String _imageModel() {
    if (customModel.isNotEmpty && customModel.contains('vision'))
      return customModel;
    return _visionModel;
  }

  @override
  Future<GeminiResult> analyze({File? image, String? textIngredients}) async {
    if (!isConfigured) {
      throw Exception(
        'OPENROUTER_API_KEY no configurada. Define --dart-define=OPENROUTER_API_KEY=sk-or-... o usa GEMINI_API_KEY',
      );
    }
    if (image != null) {
      return _analyzeImage(image);
    } else if (textIngredients != null && textIngredients.trim().isNotEmpty) {
      return _analyzeText(textIngredients.trim());
    } else {
      throw Exception('Debes proporcionar imagen o lista de ingredientes');
    }
  }

  Future<GeminiResult> _analyzeText(String text) async {
    final prompt = '''Tengo estos ingredientes: $text

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
}''';

    final body = jsonEncode({
      'model': _textModel(),
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    return _postAndParse(body);
  }

  Future<GeminiResult> _analyzeImage(File image) async {
    final bytes = await image.readAsBytes();
    final b64 = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$b64';

    const prompt =
        '''Analiza la imagen y detecta todos los ingredientes de cocina que ves.
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
}''';

    final body = jsonEncode({
      'model': _imageModel(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    return _postAndParse(body);
  }

  Future<GeminiResult> _postAndParse(String body) async {
    final response = await _client
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://cocina-estrella.app',
            'X-Title': 'Cocina Estrella',
          },
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw Exception(
        'OPENROUTER_API_KEY inválida (401). Revisa https://openrouter.ai/keys',
      );
    }
    if (response.statusCode == 429) {
      throw Exception(
        'Rate limit OpenRouter (429). Prueba en unos segundos o usa GEMINI_PROXY_URL',
      );
    }
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(
          err['error']?['message'] ?? 'OpenRouter HTTP ${response.statusCode}',
        );
      } catch (_) {
        throw Exception(
          'Error OpenRouter HTTP ${response.statusCode}: ${response.body}',
        );
      }
    }

    final data = jsonDecode(response.body);
    final rawText = data['choices'][0]['message']['content'] as String;
    String clean = rawText.trim();
    // Limpia markdown ```json ``` si el modelo lo añade
    if (clean.startsWith('```')) {
      clean = clean
          .replaceAll(RegExp(r'^```(?:json)?\s*'), '')
          .replaceAll(RegExp(r'\s*```$'), '');
    }
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (jsonMatch != null) clean = jsonMatch.group(0)!;
    final parsed = jsonDecode(clean);

    final ingredients = (parsed['ingredients'] as List)
        .map((e) => e.toString())
        .toList();
    final suggestions = (parsed['suggestions'] as List)
        .map((s) => RecipeSuggestion.fromJson(s as Map<String, dynamic>))
        .toList();

    return GeminiResult(ingredients: ingredients, suggestions: suggestions);
  }
}
