import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../repositories/meal_repository.dart';
import '../repositories/unified_recipe_repository.dart';
import '../services/ai_recipe_generator.dart';
import '../services/ai_service.dart';
import '../services/favorites_service.dart';
import '../services/gemini_service.dart';
import '../services/local_recipe_service.dart';
import '../services/meal_service.dart';
import '../services/openrouter_service.dart';
import '../services/spoonacular_service.dart';

// ── Core ──────────────────────────────────────────────────────────
final mealServiceProvider = Provider<MealService>((ref) => MealService());

final cacheBoxProvider = Provider<Box<String>>((ref) {
  // abierto en main()
  return Hive.box<String>('cache');
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.read(mealServiceProvider), ref.read(cacheBoxProvider));
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) => FavoritesService());

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

/// Factory inteligente: elige el proveedor más óptimo según dart-define.
/// Prioridad: OPENROUTER_API_KEY (Muse Spark/Nemotron free) > GEMINI_PROXY_URL > GEMINI_API_KEY (Gemini)
final aiServiceProvider = Provider<AIService>((ref) {
  const openRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');
  if (openRouterKey.isNotEmpty) {
    return OpenRouterService();
  }
  // GeminiService ya maneja proxy internamente
  return GeminiService();
});

// Alias para compatibilidad con código existente
final openRouterServiceProvider = Provider<OpenRouterService>((ref) => OpenRouterService());

final spoonacularServiceProvider = Provider<SpoonacularService>((ref) => SpoonacularService());
final unifiedRecipeRepositoryProvider = Provider<UnifiedRecipeRepository>((ref) {
  return UnifiedRecipeRepository(ref.read(mealRepositoryProvider), ref.read(mealServiceProvider), ref.read(spoonacularServiceProvider));
});

final localRecipeServiceProvider = Provider<LocalRecipeService>((ref) => LocalRecipeService());
final aiRecipeGeneratorProvider = Provider<AiRecipeGenerator>((ref) => AiRecipeGenerator());

final userRecipesProvider = FutureProvider<List<Meal>>((ref) async {
  return ref.read(localRecipeServiceProvider).getAll();
});

final randomMealProvider = FutureProvider<Meal>((ref) {
  return ref.read(mealServiceProvider).getRandomMeal();
});

final areasProvider = FutureProvider<List<String>>((ref) {
  return ref.read(mealServiceProvider).getAreas();
});

final ingredientsProvider = FutureProvider<List<String>>((ref) {
  return ref.read(mealServiceProvider).getIngredientList();
});

final mealsByAreaProvider = FutureProvider.family<List<MealSummary>, String>((ref, area) {
  return ref.read(mealServiceProvider).getMealsByArea(area);
});

final mealsByIngredientProvider = FutureProvider.family<List<MealSummary>, String>((ref, ing) {
  return ref.read(mealServiceProvider).getMealsByIngredient(ing);
});

// ── Categorías ────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<MealCategory>>((ref) {
  return ref.read(mealRepositoryProvider).getCategories();
});

// ── Platos por categoría ──────────────────────────────────────────
final mealsByCategoryProvider = FutureProvider.family<List<MealSummary>, String>((ref, category) {
  return ref.read(mealRepositoryProvider).getMealsByCategory(category);
});

// ── Detalle ───────────────────────────────────────────────────────
final mealDetailProvider = FutureProvider.family<Meal, String>((ref, id) {
  return ref.read(mealRepositoryProvider).getMealById(id);
});

final localMealProvider = FutureProvider.family<Meal?, String>((ref, id) {
  return ref.read(localRecipeServiceProvider).getById(id);
});

// ── Búsqueda ──────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<MealSummary>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return [];
  return ref.read(mealRepositoryProvider).searchMeals(query);
});

// ── Favoritos ─────────────────────────────────────────────────────
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  final svc = ref.read(favoritesServiceProvider);
  return FavoritesNotifier(svc);
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final FavoritesService _svc;
  FavoritesNotifier(this._svc) : super(_svc.ids);

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(Meal meal) async {
    await _svc.toggleFavorite(meal);
    state = _svc.ids;
  }

  List<MealSummary> get summaries => _svc.favoritesSummaries;
}

// ── Chef IA ───────────────────────────────────────────────────────
class ChefIaState {
  final bool analyzing;
  final String? error;
  final List<String> ingredients;
  final List<RecipeSuggestion> suggestions;
  final List<MealSummary> matchedMeals;
  ChefIaState({
    this.analyzing = false,
    this.error,
    this.ingredients = const [],
    this.suggestions = const [],
    this.matchedMeals = const [],
  });
  ChefIaState copyWith({
    bool? analyzing,
    String? error,
    List<String>? ingredients,
    List<RecipeSuggestion>? suggestions,
    List<MealSummary>? matchedMeals,
  }) => ChefIaState(
        analyzing: analyzing ?? this.analyzing,
        error: error,
        ingredients: ingredients ?? this.ingredients,
        suggestions: suggestions ?? this.suggestions,
        matchedMeals: matchedMeals ?? this.matchedMeals,
      );
}

final chefIaProvider = StateNotifierProvider<ChefIaNotifier, ChefIaState>((ref) {
  return ChefIaNotifier(ref.read(aiServiceProvider), ref.read(mealRepositoryProvider));
});

class ChefIaNotifier extends StateNotifier<ChefIaState> {
  final AIService _ai;
  final MealRepository _repo;
  ChefIaNotifier(this._ai, this._repo) : super(ChefIaState());

  Future<void> analyzeText(String text) async {
    state = state.copyWith(analyzing: true, error: null);
    try {
      final result = await _ai.analyze(textIngredients: text);
      state = state.copyWith(analyzing: false, ingredients: result.ingredients, suggestions: result.suggestions, matchedMeals: []);
      await _fetchPhotos(result.suggestions);
    } catch (e) {
      state = state.copyWith(analyzing: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> analyzeImage(ImageFileWrapper file) async {
    state = state.copyWith(analyzing: true, error: null);
    try {
      final result = await _ai.analyze(image: file.file);
      state = state.copyWith(analyzing: false, ingredients: result.ingredients, suggestions: result.suggestions, matchedMeals: []);
      await _fetchPhotos(result.suggestions);
    } catch (e) {
      state = state.copyWith(analyzing: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _fetchPhotos(List<RecipeSuggestion> suggestions) async {
    final meals = <MealSummary>[];
    for (final s in suggestions) {
      try {
        final r = await _repo.searchMeals(s.name);
        if (r.isNotEmpty) { meals.add(r.first); continue; }
        final r2 = await _repo.searchMeals(s.nameEs);
        meals.add(r2.isNotEmpty ? r2.first : MealSummary(id: '', name: s.nameEs, thumbnail: ''));
      } catch (_) {
        meals.add(MealSummary(id: '', name: s.nameEs, thumbnail: ''));
      }
    }
    state = state.copyWith(matchedMeals: meals);
  }

  void clear() => state = ChefIaState();
}

// Wrapper para evitar exponer dart:io File en provider si se testea en web
class ImageFileWrapper {
  final File file;
  ImageFileWrapper(this.file);
}
