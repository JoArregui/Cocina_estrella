import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import '../utils/translator.dart';

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Obtener todas las categorías
  Future<List<MealCategory>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List categories = data['categories'] ?? [];
      return categories.map((c) => MealCategory.fromJson(c)).toList();
    }
    throw Exception('Error al cargar categorías');
  }

  // Buscar platos por categoría
  Future<List<MealSummary>> getMealsByCategory(String category) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List meals = data['meals'] ?? [];
      return meals.map((m) => MealSummary.fromJson(m)).toList();
    }
    throw Exception('Error al cargar platos');
  }

  // Buscar platos por nombre
  Future<List<MealSummary>> searchMeals(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List? meals = data['meals'];
      if (meals == null) return [];
      return meals.map((m) => MealSummary.fromJson(m)).toList();
    }
    throw Exception('Error en la búsqueda');
  }

  // Obtener detalle completo de un plato
  Future<Meal> getMealById(String id) async {
  final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List meals = data['meals'] ?? [];
    if (meals.isEmpty) throw Exception('Plato no encontrado');

    final meal = Meal.fromJson(meals.first);

    // 2. Traducimos textos principales
    final translatedName = await Translator.translate(meal.name);
    final translatedInstructions = await Translator.translate(meal.instructions);

    // 3. Traducimos ingredientes usando copyWith (ya no dará error de setter)
    final translatedIngredients = await Future.wait(
      meal.ingredients.map((ing) async {
        final tName = await Translator.translate(ing.name);
        final tMeasure = await Translator.translate(ing.measure);
        return ing.copyWith(name: tName, measure: tMeasure); 
      }),
    );

    // 4. Devolvemos la copia traducida
    return meal.copyWith(
      name: translatedName,
      instructions: translatedInstructions,
      ingredients: translatedIngredients,
    );
  }
  throw Exception('Error al cargar la receta');
}

  // Obtener un plato aleatorio
  Future<Meal> getRandomMeal() async {
    final response = await http.get(Uri.parse('$_baseUrl/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List meals = data['meals'] ?? [];
      if (meals.isEmpty) throw Exception('No se encontró receta');
      return Meal.fromJson(meals.first);
    }
    throw Exception('Error al cargar receta aleatoria');
  }
}