import 'dart:io';
import '../models/meal.dart';
import '../services/meal_service.dart';
import 'ai_service.dart';
import 'gemini_service.dart';

/// Fallback 100% free y offline-parcial: no requiere API key.
/// Genera sugerencias usando TheMealDB (búsqueda por ingrediente).
/// Útil para que Chef IA funcione "out of the box" sin configurar nada.
class LocalAIService implements AIService {
  final MealService _mealService;
  LocalAIService({MealService? mealService})
    : _mealService = mealService ?? MealService();

  @override
  String get providerName => 'local:themealdb';

  @override
  bool get isConfigured => true;

  @override
  Future<GeminiResult> analyze({File? image, String? textIngredients}) async {
    if (image != null) {
      throw Exception(
        'Análisis de foto requiere IA (configura OPENROUTER_API_KEY o GEMINI_API_KEY). Por ahora usa "Escribir lista".',
      );
    }
    if (textIngredients == null || textIngredients.trim().isEmpty) {
      throw Exception('Escribe al menos un ingrediente');
    }

    final parts = textIngredients
        .split(RegExp(r'[,;\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) throw Exception('No se detectaron ingredientes');

    final normalized = parts.map((p) => p.toLowerCase()).toList();

    // Busca en TheMealDB por el primer ingrediente (el más relevante)
    List<MealSummary> candidates = [];
    for (final ing in normalized.take(2)) {
      try {
        final res = await _mealService.getMealsByIngredient(ing);
        if (res.isNotEmpty) {
          candidates = res;
          break;
        }
      } catch (_) {}
    }
    // Fallback: búsqueda por nombre si no hay por ingrediente
    if (candidates.isEmpty) {
      for (final ing in normalized.take(2)) {
        try {
          final res = await _mealService.searchMeals(ing);
          if (res.isNotEmpty) {
            candidates = res;
            break;
          }
        } catch (_) {}
      }
    }
    // Último fallback: categorías aleatorias
    if (candidates.isEmpty) {
      try {
        final cats = await _mealService.getCategories();
        if (cats.isNotEmpty) {
          final randomCat = (cats..shuffle()).first;
          candidates = await _mealService.getMealsByCategory(randomCat.name);
        }
      } catch (_) {}
    }

    final take = candidates.take(5).toList();
    final suggestions = take
        .map(
          (m) => RecipeSuggestion(
            name: m.name,
            nameEs: m.name,
            description:
                'Receta con ${parts.join(', ')} (sugerencia local TheMealDB)',
            difficulty: 'Fácil',
            time: '30 min',
            matchPercent: 70,
          ),
        )
        .toList();

    // Si aún vacío, devuelve sugerencias genéricas
    if (suggestions.isEmpty) {
      suggestions.addAll([
        RecipeSuggestion(
          name: 'Chicken Handi',
          nameEs: 'Pollo Handi',
          description: 'Pollo cremoso con especias',
          difficulty: 'Media',
          time: '45 min',
          matchPercent: 60,
        ),
        RecipeSuggestion(
          name: 'Pasta Primavera',
          nameEs: 'Pasta Primavera',
          description: 'Pasta con verduras',
          difficulty: 'Fácil',
          time: '25 min',
          matchPercent: 55,
        ),
      ]);
    }

    return GeminiResult(ingredients: parts, suggestions: suggestions);
  }
}
