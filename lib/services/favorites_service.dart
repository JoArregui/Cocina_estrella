import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/app_database.dart';
import '../models/meal.dart';

class FavoritesService {
  static const _boxName = 'favorites';
  static const _keyList = 'fav_ids';
  static bool _useSqlite = true;

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  // Intenta SQLite, fallback a Hive si falla (tests/web)
  Future<List<String>> getIdsAsync() async {
    if (_useSqlite) {
      try {
        final rows = await AppDatabase.getFavorites();
        return rows.map((r) => r['id'] as String).toList();
      } catch (_) {
        _useSqlite = false;
      }
    }
    final raw = _box.get(_keyList);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> get ids {
    // Sincrónico para compatibilidad con StateNotifier (lee Hive cache)
    // La fuente de verdad async es getIdsAsync; ids es snapshot rápido
    final raw = _box.get(_keyList);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveIds(List<String> list) async {
    await _box.put(_keyList, jsonEncode(list));
  }

  bool isFavorite(String mealId) => ids.contains(mealId);

  Future<void> toggleFavorite(Meal meal) async {
    if (_useSqlite) {
      try {
        final isFav = await AppDatabase.isFavorite(meal.id);
        if (isFav) {
          await AppDatabase.deleteFavorite(meal.id);
        } else {
          await AppDatabase.insertFavorite({
            'id': meal.id,
            'name': meal.name,
            'thumbnail': meal.thumbnail,
            'category': meal.category,
            'area': meal.area,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
        // Mantén Hive espejo para lecturas síncronas rápidas
        final current = ids;
        if (isFav) {
          current.remove(meal.id);
          await _box.delete('meal_${meal.id}');
        } else {
          current.add(meal.id);
          await _box.put(
            'meal_${meal.id}',
            jsonEncode({
              'idMeal': meal.id,
              'strMeal': meal.name,
              'strMealThumb': meal.thumbnail,
              'strCategory': meal.category,
              'strArea': meal.area,
            }),
          );
        }
        await _saveIds(current);
        return;
      } catch (_) {
        _useSqlite = false;
      }
    }
    final current = ids;
    if (current.contains(meal.id)) {
      current.remove(meal.id);
      await _box.delete('meal_${meal.id}');
    } else {
      current.add(meal.id);
      await _box.put(
        'meal_${meal.id}',
        jsonEncode({
          'idMeal': meal.id,
          'strMeal': meal.name,
          'strMealThumb': meal.thumbnail,
          'strCategory': meal.category,
          'strArea': meal.area,
        }),
      );
    }
    await _saveIds(current);
  }

  List<MealSummary> get favoritesSummaries {
    return ids.map((id) {
      final raw = _box.get('meal_$id');
      if (raw == null) return MealSummary(id: id, name: id, thumbnail: '');
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        return MealSummary.fromJson(m);
      } catch (_) {
        return MealSummary(id: id, name: id, thumbnail: '');
      }
    }).toList();
  }

  Future<void> clearAll() async {
    if (_useSqlite) {
      try {
        await AppDatabase.clearFavorites();
      } catch (_) {}
    }
    final currentIds = List<String>.from(ids);
    for (final id in currentIds) {
      await _box.delete('meal_$id');
    }
    await _box.delete(_keyList);
  }
}
