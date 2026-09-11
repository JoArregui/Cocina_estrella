import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../utils/api_key_service.dart';

/// Genera una receta COMPLETA (no solo sugerencias) vía IA.
/// Usa OpenRouter Muse Spark/Nemotron si hay OPENROUTER_API_KEY, si no Gemini.
/// Devuelve un Meal listo para guardar o cocinar.
class AiRecipeGenerator {
  final http.Client _client;
  AiRecipeGenerator({http.Client? client}) : _client = client ?? http.Client();

  static String get openRouterKey => const String.fromEnvironment('OPENROUTER_API_KEY');
  static bool get useOpenRouter => openRouterKey.isNotEmpty;

  static const _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _openRouterModel = 'meta-llama/llama-3.2-3b-instruct:free';

  Future<Meal> generateFromPrompt(String prompt, {String thumbnail = ''}) async {
    final jsonStr = await _callAi(prompt);
    return _parseToMeal(jsonStr, thumbnail: thumbnail);
  }

  Future<Meal> generateFromIngredients(List<String> ingredients) async {
    final prompt = '''
Tengo estos ingredientes: ${ingredients.join(', ')} (asume básicos: aceite, sal, pimienta, ajo).

Genera UNA receta completa y original que use esos ingredientes.
Responde SOLO con JSON (sin markdown):
{
  "name": "Nombre en español",
  "category": "Chicken|Beef|Seafood|Vegetarian|Pasta|Dessert...",
  "area": "Spanish|Italian|Mexican...",
  "instructions": "Paso 1.\\nPaso 2.\\nPaso 3.",
  "ingredients": [{"name": "pollo", "measure": "200g"}, {"name": "tomate", "measure": "2 unidades"}],
  "tags": "fácil,rápido"
}
''';
    final jsonStr = await _callAi(prompt);
    return _parseToMeal(jsonStr);
  }

  Future<String> _callAi(String prompt) async {
    if (useOpenRouter) {
      final res = await _client.post(
        Uri.parse(_openRouterUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $openRouterKey', 'HTTP-Referer': 'https://cocina-estrella.app', 'X-Title': 'Cocina Estrella'},
        body: jsonEncode({'model': _openRouterModel, 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.8, 'max_tokens': 1200}),
      ).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) throw Exception('IA HTTP ${res.statusCode}: ${res.body}');
      final data = jsonDecode(res.body);
      String content = data['choices'][0]['message']['content'].toString().trim();
      if (content.startsWith('```')) content = content.replaceAll(RegExp(r'^```(?:json)?\s*'), '').replaceAll(RegExp(r'\s*```$'), '');
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (m != null) content = m.group(0)!;
      return content;
    } else {
      final apiKey = ApiKeyService.getKey();
      if (!ApiKeyService.isValid(apiKey)) throw Exception('Configura OPENROUTER_API_KEY o GEMINI_API_KEY');
      final res = await _client.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': [{'parts': [{'text': prompt}]}], 'generationConfig': {'maxOutputTokens': 1200, 'temperature': 0.8}}),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('Gemini HTTP ${res.statusCode}');
      final data = jsonDecode(res.body);
      String content = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (m != null) content = m.group(0)!;
      return content;
    }
  }

  Meal _parseToMeal(String jsonStr, {String thumbnail = ''}) {
    final j = jsonDecode(jsonStr) as Map<String, dynamic>;
    final ings = (j['ingredients'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return MealIngredient(name: m['name']?.toString() ?? '', measure: m['measure']?.toString() ?? '');
    }).toList();
    return Meal(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      name: j['name']?.toString() ?? 'Receta IA',
      category: j['category']?.toString() ?? 'Varios',
      area: j['area']?.toString() ?? 'Internacional',
      instructions: j['instructions']?.toString() ?? '',
      thumbnail: thumbnail.isNotEmpty ? thumbnail : 'https://via.placeholder.com/400x300.png?text=IA+Recipe',
      ingredients: ings,
      tags: j['tags']?.toString(),
    );
  }
}
