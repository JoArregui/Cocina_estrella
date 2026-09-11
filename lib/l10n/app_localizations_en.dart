// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Star Kitchen';

  @override
  String get whatToCookToday => 'What are we\ncooking today?';

  @override
  String get exploreRecipes =>
      'Explore hundreds of recipes from around the world';

  @override
  String get searchRecipe => 'Search recipe...';

  @override
  String get searchHint => 'Search your favorite recipe';

  @override
  String get searchExample => 'E.g.: pasta, chicken, sushi...';

  @override
  String get noResults => 'No results';

  @override
  String get tryOtherKeyword => 'Try another keyword';

  @override
  String get categories => 'Categories';

  @override
  String get favorites => 'Favorites';

  @override
  String get noFavorites => 'No favorites yet';

  @override
  String get tapHeart => 'Tap the heart on any recipe';

  @override
  String get chefIA => 'Chef AI';

  @override
  String get photoOrList => 'Photo or list → instant recipes';

  @override
  String get whatInFridge => 'What\'s in\nyour fridge?';

  @override
  String get chefDescription =>
      'Take a photo or write your ingredients and AI will suggest delicious dishes.';

  @override
  String get writeList => 'Write list';

  @override
  String get photoIngredients => 'Photo ingredients';

  @override
  String get ingredientsHint => 'E.g.: chicken, tomato, onion, pepper, rice...';

  @override
  String get takePhoto => 'Tap to take a photo';

  @override
  String get aimIngredients => 'Point at your ingredients';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get suggestWithIA => 'Suggest dishes with AI';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get geminiAnalyzing => 'Gemini is analyzing\nyour ingredients...';

  @override
  String get searchingCombos => 'Looking for the best combinations';

  @override
  String get ingredientsDetected => 'Detected ingredients';

  @override
  String get suggestedDishes => 'Suggested dishes';

  @override
  String options(int count) {
    return '$count options';
  }

  @override
  String get viewRecipe => 'View recipe →';

  @override
  String get cookingModeGuide => 'Cooking Mode — step by step';

  @override
  String matchPercent(int percent) {
    return '$percent% match';
  }

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get preparation => 'Preparation';

  @override
  String get cookingMode => 'Cooking Mode';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get checkAll => 'Check you have everything';

  @override
  String get markIngredients =>
      'Check each ingredient before you start cooking.';

  @override
  String get allCheckedHint => 'Check all ingredients to continue';

  @override
  String get letsCook => 'Let\'s cook!';

  @override
  String get stepCompleted => '✓  Step completed';

  @override
  String get completed => 'Completed';

  @override
  String progress(int done, int total) {
    return '$done of $total steps completed';
  }

  @override
  String timeDone(int step) {
    return 'Time\'s up! Step $step';
  }

  @override
  String get ready => 'Ready!';

  @override
  String get dishReady => 'Dish ready!';

  @override
  String get congrats =>
      'Congratulations! You completed all steps correctly. Enjoy!';

  @override
  String get backToHome => 'Back to home';

  @override
  String get exitCookingMode => 'Exit Cooking Mode?';

  @override
  String get loseProgress => 'You will lose current session progress.';

  @override
  String get continueCooking => 'Continue';

  @override
  String get exit => 'Exit';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get retry => 'Retry';

  @override
  String get invalidApiKey => 'Invalid API Key';

  @override
  String get reviewEnv =>
      'Check that GEMINI_API_KEY is set via --dart-define or .env';

  @override
  String get errorIA => 'Error connecting to AI';

  @override
  String get addedFavorite => 'Added to favorites';

  @override
  String get removedFavorite => 'Removed from favorites';

  @override
  String recipesCount(int count) {
    return '$count recipes';
  }
}
