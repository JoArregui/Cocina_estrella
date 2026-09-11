import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_app/services/meal_service.dart';

void main() {
  group('MealService', () {
    test('getCategories parses correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('categories.php'));
        return http.Response(jsonEncode({
          'categories': [
            {'strCategory': 'Beef', 'strCategoryThumb': 'https://example.com/beef.jpg', 'strCategoryDescription': 'Desc'},
            {'strCategory': 'Chicken', 'strCategoryThumb': 'https://example.com/chicken.jpg', 'strCategoryDescription': 'Desc2'},
          ]
        }), 200);
      });

      final service = MealService(client: mockClient);
      final cats = await service.getCategories();
      expect(cats.length, 2);
      expect(cats.first.name, 'Beef');
      expect(cats.last.name, 'Chicken');
    });

    test('searchMeals returns empty on null', () async {
      final mockClient = MockClient((_) async => http.Response(jsonEncode({'meals': null}), 200));
      final service = MealService(client: mockClient);
      final results = await service.searchMeals('nonexistent');
      expect(results, isEmpty);
    });

    test('getMealsByCategory handles error', () async {
      final mockClient = MockClient((_) async => http.Response('Error', 500));
      final service = MealService(client: mockClient);
      expect(() => service.getMealsByCategory('Beef'), throwsException);
    });

    test('timeout throws friendly message', () async {
      final mockClient = MockClient((_) async {
        throw const SocketException('Failed host lookup');
      });
      final service = MealService(client: mockClient);
      expect(() => service.getCategories(), throwsA(predicate((e) => e.toString().contains('Sin conexión'))));
    });
  });
}
