import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local — reemplazo progresivo de Hive para favoritos/cache.
/// Sin codegen: usa sqflite directo. Migrable a Drift cuando meta pin se libere.
class AppDatabase {
  static const _dbName = 'cocina_estrella.db';
  static const _dbVersion = 3;
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            thumbnail TEXT NOT NULL,
            category TEXT,
            area TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_meals(
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_categories(
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE user_recipes(
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('CREATE TABLE IF NOT EXISTS cached_categories(id TEXT PRIMARY KEY, json TEXT NOT NULL, updated_at INTEGER NOT NULL)');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE TABLE IF NOT EXISTS user_recipes(id TEXT PRIMARY KEY, json TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
        }
      },
    );
  }

  // ── Favorites ────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return db.query('favorites', orderBy: 'created_at DESC');
  }

  static Future<bool> isFavorite(String id) async {
    final db = await database;
    final res = await db.query('favorites', where: 'id = ?', whereArgs: [id], limit: 1);
    return res.isNotEmpty;
  }

  static Future<void> insertFavorite(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('favorites', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteFavorite(String id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearFavorites() async {
    final db = await database;
    await db.delete('favorites');
  }

  // ── Cache ────────────────────────────────────────────────────────
  static Future<String?> getCachedMeal(String id) async {
    final db = await database;
    final res = await db.query('cached_meals', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first['json'] as String;
  }

  static Future<void> putCachedMeal(String id, String json) async {
    final db = await database;
    await db.insert('cached_meals', {'id': id, 'json': json, 'updated_at': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getCachedCategories() async {
    final db = await database;
    final res = await db.query('cached_categories', where: 'id = ?', whereArgs: ['categories'], limit: 1);
    if (res.isEmpty) return null;
    return res.first['json'] as String;
  }

  static Future<void> putCachedCategories(String json) async {
    final db = await database;
    await db.insert('cached_categories', {'id': 'categories', 'json': json, 'updated_at': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── User Recipes ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getUserRecipes() async {
    final db = await database;
    return db.query('user_recipes', orderBy: 'updated_at DESC');
  }

  static Future<void> insertUserRecipe(String id, String json) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('user_recipes', {'id': id, 'json': json, 'created_at': now, 'updated_at': now}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateUserRecipe(String id, String json) async {
    final db = await database;
    await db.update('user_recipes', {'json': json, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteUserRecipe(String id) async {
    final db = await database;
    await db.delete('user_recipes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, dynamic>?> getUserRecipe(String id) async {
    final db = await database;
    final res = await db.query('user_recipes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
