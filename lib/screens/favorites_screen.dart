import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../widgets/meal_card.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha cambios para rebuild cuando se añade/quita favorito
    ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    final meals = notifier.summaries;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        title: Text(
          'Favoritos',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: meals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes favoritos',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      color: const Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el corazón en cualquier receta',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemCount: meals.length,
              itemBuilder: (context, i) => MealCard(
                meal: meals[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(mealId: meals[i].id),
                  ),
                ),
              ),
            ),
    );
  }
}
