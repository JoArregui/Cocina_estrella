import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';

class MealRepository {
  final MealService _service;
  final Box<String> _cacheBox;

  static const _keyCategories = 'categories';
  static const _keyCategoryPrefix = 'category_';
  static const _keyMealPrefix = 'meal_';

  MealRepository(this._service, this._cacheBox);

  Future<List<MealCategory>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheBox.containsKey(_keyCategories)) {
      try {
        final raw = _cacheBox.get(_keyCategories)!;
        final List decoded = jsonDecode(raw) as List;
        return decoded
            .map((e) => MealCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // cache corrupt -> fetch fresh
      }
    }
    final categories = await _service.getCategories();
    try {
      final encoded = jsonEncode(
        categories
            .map(
              (c) => {
                'strCategory': c.name,
                'strCategoryThumb': c.thumbnail,
                'strCategoryDescription': c.description,
              },
            )
            .toList(),
      );
      await _cacheBox.put(_keyCategories, encoded);
    } catch (_) {}
    return categories;
  }

  Future<List<MealSummary>> getMealsByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    final key = '$_keyCategoryPrefix$category';
    if (!forceRefresh && _cacheBox.containsKey(key)) {
      try {
        final raw = _cacheBox.get(key)!;
        final List decoded = jsonDecode(raw) as List;
        return decoded
            .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final meals = await _service.getMealsByCategory(category);
    try {
      final encoded = jsonEncode(
        meals
            .map(
              (m) => {
                'idMeal': m.id,
                'strMeal': m.name,
                'strMealThumb': m.thumbnail,
              },
            )
            .toList(),
      );
      await _cacheBox.put(key, encoded);
    } catch (_) {}
    return meals;
  }

  Future<List<MealSummary>> searchMeals(String query) {
    // Búsqueda no cacheada (query variable)
    return _service.searchMeals(query);
  }

  Future<Meal> getMealById(String id, {bool forceRefresh = false}) async {
    final key = '$_keyMealPrefix$id';
    if (!forceRefresh && _cacheBox.containsKey(key)) {
      try {
        final raw = _cacheBox.get(key)!;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return Meal.fromJson(decoded);
      } catch (_) {}
    }
    final meal = await _service.getMealById(id);
    try {
      // Guardamos raw serializado (reconstruimos mapa desde Meal)
      // Para no perder campos originales, serializamos el Meal ya traducido
      // usando su JSON inverso mínimo
      final encoded = jsonEncode({
        'idMeal': meal.id,
        'strMeal': meal.name,
        'strCategory': meal.category,
        'strArea': meal.area,
        'strInstructions': meal.instructions,
        'strMealThumb': meal.thumbnail,
        'strYoutube': meal.youtubeUrl,
        'strTags': meal.tags,
        for (int i = 0; i < meal.ingredients.length; i++) ...{
          'strIngredient${i + 1}': meal.ingredients[i].name,
          'strMeasure${i + 1}': meal.ingredients[i].measure,
        },
      });
      await _cacheBox.put(key, encoded);
    } catch (_) {}
    return meal;
  }

  Future<Meal> getRandomMeal() => _service.getRandomMeal();
}
