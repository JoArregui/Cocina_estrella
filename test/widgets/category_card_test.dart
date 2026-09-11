import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/meal.dart';
import 'package:recipe_app/widgets/category_card.dart';

void main() {
  testWidgets('CategoryCard shows translated name', (tester) async {
    final cat = MealCategory(name: 'Beef', thumbnail: 'https://via.placeholder.com/150', description: 'desc');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CategoryCard(category: cat, onTap: () {}))));
    await tester.pump();
    // Debe mostrar "Ternera" (traducción de Beef)
    expect(find.text('Ternera'), findsOneWidget);
  });

  testWidgets('CategoryCard onTap fires', (tester) async {
    bool tapped = false;
    final cat = MealCategory(name: 'Chicken', thumbnail: 'https://via.placeholder.com/150', description: 'desc');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CategoryCard(category: cat, onTap: () => tapped = true))));
    await tester.tap(find.byType(CategoryCard));
    expect(tapped, isTrue);
  });
}
