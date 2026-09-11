import '../models/meal.dart';
import '../services/meal_service.dart';
import '../services/spoonacular_service.dart';
import 'meal_repository.dart';

/// Repositorio unificado: agrega TheMealDB (primario), Spoonacular (secundario) y cache.
/// Si TheMealDB no tiene resultados y Spoonacular está configurado, hace fallback.
/// Mantiene interfaz idéntica a MealRepository para no romper UI.
class UnifiedRecipeRepository {
  final MealRepository _mealRepo;
  final MealService _mealService;
  final SpoonacularService _spoon;

  UnifiedRecipeRepository(this._mealRepo, this._mealService, this._spoon);

  Future<List<MealCategory>> getCategories() => _mealRepo.getCategories();

  Future<List<String>> getAreas() => _mealService.getAreas();
  Future<List<String>> getIngredientList() => _mealService.getIngredientList();

  Future<List<MealSummary>> getMealsByCategory(String c) =>
      _mealRepo.getMealsByCategory(c);
  Future<List<MealSummary>> getMealsByArea(String a) =>
      _mealService.getMealsByArea(a);
  Future<List<MealSummary>> getMealsByIngredient(String i) =>
      _mealService.getMealsByIngredient(i);

  Future<List<MealSummary>> search(String query) async {
    final local = await _mealRepo.searchMeals(query);
    if (local.isNotEmpty || !SpoonacularService.isConfigured) return local;
    try {
      final remote = await _spoon.search(query);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    return local;
  }

  Future<Meal> getById(String id) async {
    if (id.startsWith('sp_')) {
      final spoonMeal = await _spoon.getById(id);
      if (spoonMeal != null) return spoonMeal;
      throw Exception('Receta Spoonacular no encontrada');
    }
    if (id.startsWith('user_')) {
      throw Exception('Usa LocalRecipeRepository para ids user_');
    }
    if (id.startsWith('ai_')) {
      throw Exception('Receta IA efímera, ya está en memoria');
    }
    return _mealRepo.getMealById(id);
  }

  Future<Meal> getRandom() => _mealService.getRandomMeal();
}
