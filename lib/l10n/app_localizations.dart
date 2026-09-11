import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Cocina Estrella'**
  String get appTitle;

  /// No description provided for @whatToCookToday.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cocinamos\nhoy?'**
  String get whatToCookToday;

  /// No description provided for @exploreRecipes.
  ///
  /// In es, this message translates to:
  /// **'Explora cientos de recetas del mundo entero'**
  String get exploreRecipes;

  /// No description provided for @searchRecipe.
  ///
  /// In es, this message translates to:
  /// **'Buscar receta...'**
  String get searchRecipe;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Busca tu receta favorita'**
  String get searchHint;

  /// No description provided for @searchExample.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: pasta, pollo, sushi...'**
  String get searchExample;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @tryOtherKeyword.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra palabra clave'**
  String get tryOtherKeyword;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @favorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favorites;

  /// No description provided for @noFavorites.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes favoritos'**
  String get noFavorites;

  /// No description provided for @tapHeart.
  ///
  /// In es, this message translates to:
  /// **'Toca el corazón en cualquier receta'**
  String get tapHeart;

  /// No description provided for @chefIA.
  ///
  /// In es, this message translates to:
  /// **'Chef IA'**
  String get chefIA;

  /// No description provided for @photoOrList.
  ///
  /// In es, this message translates to:
  /// **'Foto o lista → recetas al instante'**
  String get photoOrList;

  /// No description provided for @whatInFridge.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hay en\ntu nevera?'**
  String get whatInFridge;

  /// No description provided for @chefDescription.
  ///
  /// In es, this message translates to:
  /// **'Haz una foto o escribe tus ingredientes y la IA te sugerirá platos deliciosos.'**
  String get chefDescription;

  /// No description provided for @writeList.
  ///
  /// In es, this message translates to:
  /// **'Escribir lista'**
  String get writeList;

  /// No description provided for @photoIngredients.
  ///
  /// In es, this message translates to:
  /// **'Foto ingredientes'**
  String get photoIngredients;

  /// No description provided for @ingredientsHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: pollo, tomate, cebolla, pimiento, arroz...'**
  String get ingredientsHint;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Toca para hacer una foto'**
  String get takePhoto;

  /// No description provided for @aimIngredients.
  ///
  /// In es, this message translates to:
  /// **'Apunta a tus ingredientes'**
  String get aimIngredients;

  /// No description provided for @camera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get gallery;

  /// No description provided for @suggestWithIA.
  ///
  /// In es, this message translates to:
  /// **'Sugerir platos con IA'**
  String get suggestWithIA;

  /// No description provided for @analyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando...'**
  String get analyzing;

  /// No description provided for @geminiAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Gemini está analizando\ntus ingredientes...'**
  String get geminiAnalyzing;

  /// No description provided for @searchingCombos.
  ///
  /// In es, this message translates to:
  /// **'Buscando las mejores combinaciones'**
  String get searchingCombos;

  /// No description provided for @ingredientsDetected.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes detectados'**
  String get ingredientsDetected;

  /// No description provided for @suggestedDishes.
  ///
  /// In es, this message translates to:
  /// **'Platos sugeridos'**
  String get suggestedDishes;

  /// No description provided for @options.
  ///
  /// In es, this message translates to:
  /// **'{count} opciones'**
  String options(int count);

  /// No description provided for @viewRecipe.
  ///
  /// In es, this message translates to:
  /// **'Ver receta →'**
  String get viewRecipe;

  /// No description provided for @cookingModeGuide.
  ///
  /// In es, this message translates to:
  /// **'Modo Cocinero — guía paso a paso'**
  String get cookingModeGuide;

  /// No description provided for @matchPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent}% match'**
  String matchPercent(int percent);

  /// No description provided for @easy.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get hard;

  /// No description provided for @ingredients.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes'**
  String get ingredients;

  /// No description provided for @preparation.
  ///
  /// In es, this message translates to:
  /// **'Preparación'**
  String get preparation;

  /// No description provided for @cookingMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Cocinero'**
  String get cookingMode;

  /// No description provided for @stepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String stepOf(int current, int total);

  /// No description provided for @checkAll.
  ///
  /// In es, this message translates to:
  /// **'Comprueba que tienes todo'**
  String get checkAll;

  /// No description provided for @markIngredients.
  ///
  /// In es, this message translates to:
  /// **'Marca cada ingrediente antes de empezar a cocinar.'**
  String get markIngredients;

  /// No description provided for @allCheckedHint.
  ///
  /// In es, this message translates to:
  /// **'Marca todos los ingredientes para continuar'**
  String get allCheckedHint;

  /// No description provided for @letsCook.
  ///
  /// In es, this message translates to:
  /// **'¡A cocinar!'**
  String get letsCook;

  /// No description provided for @stepCompleted.
  ///
  /// In es, this message translates to:
  /// **'✓  Paso completado'**
  String get stepCompleted;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get completed;

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} pasos completados'**
  String progress(int done, int total);

  /// No description provided for @timeDone.
  ///
  /// In es, this message translates to:
  /// **'¡Tiempo completado! Paso {step}'**
  String timeDone(int step);

  /// No description provided for @ready.
  ///
  /// In es, this message translates to:
  /// **'¡Listo!'**
  String get ready;

  /// No description provided for @dishReady.
  ///
  /// In es, this message translates to:
  /// **'¡Plato listo!'**
  String get dishReady;

  /// No description provided for @congrats.
  ///
  /// In es, this message translates to:
  /// **'¡Enhorabuena! Has completado todos los pasos correctamente. ¡A disfrutar!'**
  String get congrats;

  /// No description provided for @backToHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get backToHome;

  /// No description provided for @exitCookingMode.
  ///
  /// In es, this message translates to:
  /// **'¿Salir del Modo Cocinero?'**
  String get exitCookingMode;

  /// No description provided for @loseProgress.
  ///
  /// In es, this message translates to:
  /// **'Perderás el progreso actual de esta sesión.'**
  String get loseProgress;

  /// No description provided for @continueCooking.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueCooking;

  /// No description provided for @exit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get exit;

  /// No description provided for @errorConnection.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get errorConnection;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @invalidApiKey.
  ///
  /// In es, this message translates to:
  /// **'API Key inválida'**
  String get invalidApiKey;

  /// No description provided for @reviewEnv.
  ///
  /// In es, this message translates to:
  /// **'Revisa que GEMINI_API_KEY esté definida vía --dart-define o .env'**
  String get reviewEnv;

  /// No description provided for @errorIA.
  ///
  /// In es, this message translates to:
  /// **'Error al conectar con la IA'**
  String get errorIA;

  /// No description provided for @addedFavorite.
  ///
  /// In es, this message translates to:
  /// **'Añadido a favoritos'**
  String get addedFavorite;

  /// No description provided for @removedFavorite.
  ///
  /// In es, this message translates to:
  /// **'Eliminado de favoritos'**
  String get removedFavorite;

  /// No description provided for @recipesCount.
  ///
  /// In es, this message translates to:
  /// **'{count} recetas'**
  String recipesCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
