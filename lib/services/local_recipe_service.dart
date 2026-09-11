import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../data/app_database.dart';
import '../models/meal.dart';

class LocalRecipeService {
  static const _uuid = Uuid();

  Future<List<Meal>> getAll() async {
    final rows = await AppDatabase.getUserRecipes();
    return rows
        .map((r) {
          try {
            return Meal.fromJson(
              jsonDecode(r['json'] as String) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Meal>()
        .toList();
  }

  Future<List<MealSummary>> getSummaries() async {
    final meals = await getAll();
    return meals
        .map((m) => MealSummary(id: m.id, name: m.name, thumbnail: m.thumbnail))
        .toList();
  }

  Future<Meal?> getById(String id) async {
    final row = await AppDatabase.getUserRecipe(id);
    if (row == null) return null;
    try {
      return Meal.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> create(Meal meal) async {
    final id = meal.id.isNotEmpty ? meal.id : 'user_${_uuid.v4()}';
    final toSave = Meal(
      id: id,
      name: meal.name,
      category: meal.category,
      area: meal.area,
      instructions: meal.instructions,
      thumbnail: meal.thumbnail,
      youtubeUrl: meal.youtubeUrl,
      ingredients: meal.ingredients,
      tags: meal.tags,
    );
    final json = jsonEncode({
      'idMeal': toSave.id,
      'strMeal': toSave.name,
      'strCategory': toSave.category,
      'strArea': toSave.area,
      'strInstructions': toSave.instructions,
      'strMealThumb': toSave.thumbnail,
      'strYoutube': toSave.youtubeUrl,
      'strTags': toSave.tags,
      for (int i = 0; i < toSave.ingredients.length; i++) ...{
        'strIngredient${i + 1}': toSave.ingredients[i].name,
        'strMeasure${i + 1}': toSave.ingredients[i].measure,
      },
    });
    await AppDatabase.insertUserRecipe(id, json);
    return id;
  }

  Future<void> update(String id, Meal meal) async {
    final json = jsonEncode({
      'idMeal': id,
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
    await AppDatabase.updateUserRecipe(id, json);
  }

  Future<void> delete(String id) async => AppDatabase.deleteUserRecipe(id);
}
