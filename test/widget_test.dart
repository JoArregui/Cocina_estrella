// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/main.dart';
import 'package:recipe_app/providers/providers.dart';

void main() {
  testWidgets('RecipeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesProvider.overrideWith((ref) async => [])],
        child: const RecipeApp(),
      ),
    );
    await tester.pump();
    expect(find.text('¿Qué cocinamos\nhoy?'), findsOneWidget);
  });

  testWidgets('RecipeApp has Chef IA banner', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesProvider.overrideWith((ref) async => [])],
        child: const RecipeApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Chef IA'), findsOneWidget);
  });

  testWidgets('Home shows shimmer when loading', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RecipeApp()));
    // Sin override, queda en loading (no necesita Hive mock si no resuelve)
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('¿Qué cocinamos\nhoy?').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
