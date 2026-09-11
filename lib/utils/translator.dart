import 'package:translator/translator.dart';

class Translator {
  static final _googleTranslator = GoogleTranslator();
  static final Map<String, String> _cache = {};
  static const int _maxCacheSize = 500;

  /// Diccionario local para ingredientes comunes — evita llamada a red
  static const Map<String, String> _ingredientDict = {
    'chicken': 'pollo',
    'beef': 'ternera',
    'pork': 'cerdo',
    'fish': 'pescado',
    'salmon': 'salmón',
    'rice': 'arroz',
    'pasta': 'pasta',
    'tomato': 'tomate',
    'onion': 'cebolla',
    'garlic': 'ajo',
    'cheese': 'queso',
    'egg': 'huevo',
    'eggs': 'huevos',
    'milk': 'leche',
    'butter': 'mantequilla',
    'flour': 'harina',
    'sugar': 'azúcar',
    'salt': 'sal',
    'pepper': 'pimienta',
    'oil': 'aceite',
    'olive oil': 'aceite de oliva',
    'potato': 'patata',
    'potatoes': 'patatas',
    'carrot': 'zanahoria',
    'lemon': 'limón',
    'lime': 'lima',
    'basil': 'albahaca',
    'parsley': 'perejil',
    'cinnamon': 'canela',
    'honey': 'miel',
    'chocolate': 'chocolate',
    'cream': 'nata',
    'yogurt': 'yogur',
    'chilli': 'chile',
    'chili': 'chile',
  };

  static const Map<String, String> _measureDict = {
    'cup': 'taza',
    'cups': 'tazas',
    'tablespoon': 'cucharada',
    'tablespoons': 'cucharadas',
    'teaspoon': 'cucharadita',
    'teaspoons': 'cucharaditas',
    'tsp': 'cdta.',
    'tbsp': 'cda.',
    'gram': 'gramo',
    'grams': 'gramos',
    'g': 'g',
    'kg': 'kg',
    'ml': 'ml',
    'l': 'l',
    'oz': 'oz',
    'lb': 'lb',
    'pinch': 'pizca',
  };

  static String? _localLookup(String text) {
    final lower = text.toLowerCase().trim();
    if (_ingredientDict.containsKey(lower)) return _ingredientDict[lower];
    if (_measureDict.containsKey(lower)) return _measureDict[lower];
    return null;
  }

  // Traducción automática: 1) cache 2) diccionario local 3) Google Translate 4) fallback original
  static Future<String> translate(String text) async {
    if (text.isEmpty) return text;
    final key = text.trim();
    if (_cache.containsKey(key)) return _cache[key]!;
    final local = _localLookup(key);
    if (local != null) {
      _cache[key] = local;
      return local;
    }
    // Medidas como "1 cup" o "2 tbsp" se traducen por partes si es posible sin red
    if (RegExp(r'^[\d\/\.\s]+[a-zA-Z]+$').hasMatch(key)) {
      final parts = key.split(RegExp(r'\s+'));
      final translatedParts = parts.map((p) => _measureDict[p.toLowerCase()] ?? p).toList();
      if (translatedParts.join(' ') != key) {
        final joined = translatedParts.join(' ');
        _cache[key] = joined;
        return joined;
      }
    }
    try {
      final translation = await _googleTranslator
          .translate(key, from: 'en', to: 'es')
          .timeout(const Duration(seconds: 8));
      final result = translation.text;
      if (_cache.length >= _maxCacheSize) {
        final toRemove = _cache.keys.take(_maxCacheSize ~/ 2).toList();
        for (final k in toRemove) {
          _cache.remove(k);
        }
      }
      _cache[key] = result;
      return result;
    } catch (_) {
      return text;
    }
  }

  /// Traduce solo si no está en diccionario local — útil para tests
  static Future<String> translateWithLocalFirst(String text) => translate(text);

  static void clearCache() => _cache.clear();

  // Diccionarios estáticos para categorías
  static String category(String category) {
    const Map<String, String> categories = {
      'RecipeBook': 'Recetario',
      'Beef': 'Ternera',
      'Chicken': 'Pollo',
      'Dessert': 'Postres',
      'Lamb': 'Cordero',
      'Miscellaneous': 'Varios',
      'Pasta': 'Pasta',
      'Pork': 'Cerdo',
      'Seafood': 'Mariscos',
      'Side': 'Acompañamientos',
      'Starter': 'Entrantes',
      'Vegan': 'Vegano',
      'Vegetarian': 'Vegetariano',
      'Breakfast': 'Desayuno',
      'Goat': 'Cabra',
    };
    return categories[category] ?? category;
  }

  // Diccionarios estáticos para áreas geográficas
  static String area(String area) {
    const Map<String, String> areas = {
      'American': 'Americana',
      'British': 'Británica',
      'Canadian': 'Canadiense',
      'Chinese': 'China',
      'Croatian': 'Croata',
      'Dutch': 'Holandesa',
      'Egyptian': 'Egipcia',
      'French': 'Francesa',
      'Greek': 'Griega',
      'Indian': 'India',
      'Irish': 'Irlandesa',
      'Italian': 'Italiana',
      'Jamaican': 'Jamaicana',
      'Japanese': 'Japonesa',
      'Kenyan': 'Keniana',
      'Malaysian': 'Malaya',
      'Mexican': 'Mexicana',
      'Moroccan': 'Marroquí',
      'Polish': 'Polaca',
      'Portuguese': 'Portuguesa',
      'Russian': 'Rusa',
      'Spanish': 'Española',
      'Thai': 'Tailandesa',
      'Tunisian': 'Tunecina',
      'Turkish': 'Turca',
      'Unknown': 'Internacional',
      'Vietnamese': 'Vietnamita',
    };
    return areas[area] ?? area;
  }
}