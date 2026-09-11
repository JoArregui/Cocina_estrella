import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../utils/translator.dart';

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  MealService({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      return response;
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión');
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on HandshakeException {
      throw Exception('Error de conexión segura');
    }
  }

  // Obtener todas las categorías
  Future<List<MealCategory>> getCategories() async {
    final response = await _get(Uri.parse('$_baseUrl/categories.php'));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List categories = data['categories'] ?? [];
        return categories.map((c) => MealCategory.fromJson(c)).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception('Error al cargar categorías (HTTP ${response.statusCode})');
  }

  // Buscar platos por categoría
  Future<List<MealSummary>> getMealsByCategory(String category) async {
    final response = await _get(
      Uri.parse('$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}'),
    );
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        return meals.map((m) => MealSummary.fromJson(m)).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception('Error al cargar platos (HTTP ${response.statusCode})');
  }

  // Buscar platos por nombre
  Future<List<MealSummary>> searchMeals(String query) async {
    final response = await _get(
      Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List? meals = data['meals'];
        if (meals == null) return [];
        return meals.map((m) => MealSummary.fromJson(m)).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception('Error en la búsqueda (HTTP ${response.statusCode})');
  }

  // Obtener detalle completo de un plato
  Future<Meal> getMealById(String id) async {
    final response = await _get(Uri.parse('$_baseUrl/lookup.php?i=$id'));

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        if (meals.isEmpty) throw Exception('Plato no encontrado');

        final meal = Meal.fromJson(meals.first);

        // Traducimos textos principales en paralelo
        final translatedNameFuture = Translator.translate(meal.name);
        final translatedInstructionsFuture = Translator.translate(
          meal.instructions,
        );

        final translatedIngredients = await Future.wait(
          meal.ingredients.map((ing) async {
            // Medidas como "1 cup" no se traducen para evitar ruido; solo nombre
            final tName = await Translator.translate(ing.name);
            return ing.copyWith(name: tName);
          }),
        );

        final translatedName = await translatedNameFuture;
        final translatedInstructions = await translatedInstructionsFuture;

        return meal.copyWith(
          name: translatedName,
          instructions: translatedInstructions,
          ingredients: translatedIngredients,
        );
      } catch (e) {
        if (e.toString().contains('Plato no encontrado')) rethrow;
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception('Error al cargar la receta (HTTP ${response.statusCode})');
  }

  // Obtener todas las áreas (for filter.php?a)
  Future<List<String>> getAreas() async {
    final response = await _get(Uri.parse('$_baseUrl/list.php?a=list'));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        return meals.map((e) => e['strArea'].toString()).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception('Error al cargar áreas (HTTP ${response.statusCode})');
  }

  // Buscar platos por área
  Future<List<MealSummary>> getMealsByArea(String area) async {
    final response = await _get(
      Uri.parse('$_baseUrl/filter.php?a=${Uri.encodeComponent(area)}'),
    );
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        return meals.map((m) => MealSummary.fromJson(m)).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception(
      'Error al cargar platos por área (HTTP ${response.statusCode})',
    );
  }

  // Buscar platos por ingrediente principal
  Future<List<MealSummary>> getMealsByIngredient(String ingredient) async {
    final response = await _get(
      Uri.parse('$_baseUrl/filter.php?i=${Uri.encodeComponent(ingredient)}'),
    );
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        return meals.map((m) => MealSummary.fromJson(m)).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception(
      'Error al cargar platos por ingrediente (HTTP ${response.statusCode})',
    );
  }

  // Obtener lista de ingredientes con imagen
  Future<List<String>> getIngredientList() async {
    final response = await _get(Uri.parse('$_baseUrl/list.php?i=list'));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        return meals.map((e) => e['strIngredient'].toString()).toList();
      } catch (_) {
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception(
      'Error al cargar ingredientes (HTTP ${response.statusCode})',
    );
  }

  // Obtener un plato aleatorio
  Future<Meal> getRandomMeal() async {
    final response = await _get(Uri.parse('$_baseUrl/random.php'));
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        final List meals = data['meals'] ?? [];
        if (meals.isEmpty) throw Exception('No se encontró receta');
        final meal = Meal.fromJson(meals.first);
        final tName = await Translator.translate(meal.name);
        final tInstr = await Translator.translate(meal.instructions);
        final tIngs = await Future.wait(
          meal.ingredients.map(
            (ing) async =>
                ing.copyWith(name: await Translator.translate(ing.name)),
          ),
        );
        return meal.copyWith(
          name: tName,
          instructions: tInstr,
          ingredients: tIngs,
        );
      } catch (e) {
        if (e.toString().contains('No se encontró')) rethrow;
        throw Exception('Respuesta inválida del servidor');
      }
    }
    throw Exception(
      'Error al cargar receta aleatoria (HTTP ${response.statusCode})',
    );
  }

  void dispose() => _client.close();
}
