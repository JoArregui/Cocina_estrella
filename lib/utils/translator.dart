import 'package:translator/translator.dart';

class Translator {
  static final _googleTranslator = GoogleTranslator();

  // Traducción automática para textos largos (Nombres, Instrucciones, Ingredientes)
  static Future<String> translate(String text) async {
    if (text.isEmpty) return text;
    try {
      // Traduce de inglés (en) a español (es)
      final translation = await _googleTranslator.translate(text, from: 'en', to: 'es');
      return translation.text;
    } catch (e) {
      return text; // Si falla la red, devolvemos el original
    }
  }

  // Diccionarios estáticos (tus mapas actuales se mantienen igual)
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