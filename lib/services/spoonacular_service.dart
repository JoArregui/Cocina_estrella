import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

/// Fuente secundaria: Spoonacular (https://spoonacular.com/food-api)
/// Aporta ~5.000 recetas con info nutricional. Free 150 req/día.
/// Si no hay SPOONACULAR_API_KEY, el servicio queda deshabilitado (retorna []),
/// actuando como fallback sin romper la app.
class SpoonacularService {
  static const _baseUrl = 'https://api.spoonacular.com';
  static const _timeout = Duration(seconds: 10);
  final http.Client _client;

  SpoonacularService({http.Client? client}) : _client = client ?? http.Client();

  static String get apiKey => const String.fromEnvironment('SPOONACULAR_API_KEY');
  static bool get isConfigured => apiKey.isNotEmpty;

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Timeout Spoonacular');
    } on SocketException {
      throw Exception('Sin conexión');
    }
  }

  Future<List<MealSummary>> search(String query) async {
    if (!isConfigured) return [];
    final uri = Uri.parse('$_baseUrl/recipes/complexSearch?query=${Uri.encodeComponent(query)}&number=10&apiKey=$apiKey');
    final res = await _get(uri);
    if (res.statusCode == 402) throw Exception('Límite Spoonacular alcanzado (402)');
    if (res.statusCode != 200) throw Exception('Spoonacular HTTP ${res.statusCode}');
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      return results.map((r) => MealSummary(
            id: 'sp_${r['id']}',
            name: r['title'] ?? '',
            thumbnail: r['image'] ?? '',
          )).toList();
    } catch (_) {
      throw Exception('Respuesta Spoonacular inválida');
    }
  }

  Future<Meal?> getById(String id) async {
    if (!isConfigured) return null;
    final spoonId = id.replaceFirst('sp_', '');
    final uri = Uri.parse('$_baseUrl/recipes/$spoonId/information?apiKey=$apiKey&includeNutrition=false');
    final res = await _get(uri);
    if (res.statusCode != 200) return null;
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ingredients = <MealIngredient>[];
      for (final ing in (data['extendedIngredients'] as List? ?? [])) {
        ingredients.add(MealIngredient(
          name: ing['name']?.toString() ?? '',
          measure: '${ing['amount'] ?? ''} ${ing['unit'] ?? ''}'.trim(),
        ));
      }
      return Meal(
        id: 'sp_${data['id']}',
        name: data['title'] ?? '',
        category: (data['dishTypes'] as List?)?.firstOrNull?.toString() ?? 'Varios',
        area: (data['cuisines'] as List?)?.firstOrNull?.toString() ?? 'Internacional',
        instructions: (data['instructions'] ?? '').toString().replaceAll(RegExp(r'<[^>]*>'), ''),
        thumbnail: data['image'] ?? '',
        youtubeUrl: data['sourceUrl']?.toString(),
        ingredients: ingredients,
        tags: (data['diets'] as List?)?.join(','),
      );
    } catch (_) {
      return null;
    }
  }
}

extension _FirstOrNull on List {
  dynamic get firstOrNull => isEmpty ? null : first;
}
