import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/services/gemini_service.dart';

void main() {
  group('GeminiService proxy parsing', () {
    test('parses direct ingredients/suggestions JSON', () async {
      // Testea RecipeSuggestion.fromJson directamente (proxy no requiere API key real)
      final suggestion = RecipeSuggestion.fromJson({
        'name': 'Pasta',
        'name_es': 'Pasta',
        'description': 'Yummy',
        'difficulty': 'Media',
        'time': '20 min',
        'match_percent': '85',
      });
      expect(suggestion.matchPercent, 85);
      expect(suggestion.nameEs, 'Pasta');
    });

    test('RecipeSuggestion handles int match_percent', () {
      final s = RecipeSuggestion.fromJson({'name': 'A', 'match_percent': 90});
      expect(s.matchPercent, 90);
    });
  });
}
