// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Cocina Estrella';

  @override
  String get whatToCookToday => '¿Qué cocinamos\nhoy?';

  @override
  String get exploreRecipes => 'Explora cientos de recetas del mundo entero';

  @override
  String get searchRecipe => 'Buscar receta...';

  @override
  String get searchHint => 'Busca tu receta favorita';

  @override
  String get searchExample => 'Por ejemplo: pasta, pollo, sushi...';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get tryOtherKeyword => 'Prueba con otra palabra clave';

  @override
  String get categories => 'Categorías';

  @override
  String get favorites => 'Favoritos';

  @override
  String get noFavorites => 'Aún no tienes favoritos';

  @override
  String get tapHeart => 'Toca el corazón en cualquier receta';

  @override
  String get chefIA => 'Chef IA';

  @override
  String get photoOrList => 'Foto o lista → recetas al instante';

  @override
  String get whatInFridge => '¿Qué hay en\ntu nevera?';

  @override
  String get chefDescription =>
      'Haz una foto o escribe tus ingredientes y la IA te sugerirá platos deliciosos.';

  @override
  String get writeList => 'Escribir lista';

  @override
  String get photoIngredients => 'Foto ingredientes';

  @override
  String get ingredientsHint =>
      'Ej: pollo, tomate, cebolla, pimiento, arroz...';

  @override
  String get takePhoto => 'Toca para hacer una foto';

  @override
  String get aimIngredients => 'Apunta a tus ingredientes';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get suggestWithIA => 'Sugerir platos con IA';

  @override
  String get analyzing => 'Analizando...';

  @override
  String get geminiAnalyzing => 'Gemini está analizando\ntus ingredientes...';

  @override
  String get searchingCombos => 'Buscando las mejores combinaciones';

  @override
  String get ingredientsDetected => 'Ingredientes detectados';

  @override
  String get suggestedDishes => 'Platos sugeridos';

  @override
  String options(int count) {
    return '$count opciones';
  }

  @override
  String get viewRecipe => 'Ver receta →';

  @override
  String get cookingModeGuide => 'Modo Cocinero — guía paso a paso';

  @override
  String matchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Media';

  @override
  String get hard => 'Difícil';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get preparation => 'Preparación';

  @override
  String get cookingMode => 'Modo Cocinero';

  @override
  String stepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get checkAll => 'Comprueba que tienes todo';

  @override
  String get markIngredients =>
      'Marca cada ingrediente antes de empezar a cocinar.';

  @override
  String get allCheckedHint => 'Marca todos los ingredientes para continuar';

  @override
  String get letsCook => '¡A cocinar!';

  @override
  String get stepCompleted => '✓  Paso completado';

  @override
  String get completed => 'Completado';

  @override
  String progress(int done, int total) {
    return '$done de $total pasos completados';
  }

  @override
  String timeDone(int step) {
    return '¡Tiempo completado! Paso $step';
  }

  @override
  String get ready => '¡Listo!';

  @override
  String get dishReady => '¡Plato listo!';

  @override
  String get congrats =>
      '¡Enhorabuena! Has completado todos los pasos correctamente. ¡A disfrutar!';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get exitCookingMode => '¿Salir del Modo Cocinero?';

  @override
  String get loseProgress => 'Perderás el progreso actual de esta sesión.';

  @override
  String get continueCooking => 'Continuar';

  @override
  String get exit => 'Salir';

  @override
  String get errorConnection => 'Error de conexión';

  @override
  String get retry => 'Reintentar';

  @override
  String get invalidApiKey => 'API Key inválida';

  @override
  String get reviewEnv =>
      'Revisa que GEMINI_API_KEY esté definida vía --dart-define o .env';

  @override
  String get errorIA => 'Error al conectar con la IA';

  @override
  String get addedFavorite => 'Añadido a favoritos';

  @override
  String get removedFavorite => 'Eliminado de favoritos';

  @override
  String recipesCount(int count) {
    return '$count recetas';
  }
}
