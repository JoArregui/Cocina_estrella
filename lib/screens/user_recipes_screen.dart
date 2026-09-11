import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal.dart';
import '../providers/providers.dart';
import '../widgets/meal_card.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

class UserRecipesScreen extends ConsumerWidget {
  const UserRecipesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userRecipesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F4F0), title: Text('Mis recetas', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Color(0xFF1A1A1A))),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen())), backgroundColor: const Color(0xFFE8490F), icon: const Icon(Icons.add, color: Colors.white), label: Text('Nueva', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (meals) {
          if (meals.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book, size: 64, color: Colors.grey[300]), const SizedBox(height: 12), Text('Aún no has creado recetas', style: GoogleFonts.nunito()), const SizedBox(height: 8), Text('Toca Nueva para añadir tu primera receta', style: GoogleFonts.nunito(color: Colors.grey))]));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.85),
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final m = meals[i];
              final summary = MealSummary(id: m.id, name: m.name, thumbnail: m.thumbnail);
              return Dismissible(
                key: ValueKey(m.id),
                direction: DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (_) async {
                  await ref.read(localRecipeServiceProvider).delete(m.id);
                  ref.invalidate(userRecipesProvider);
                },
                child: MealCard(meal: summary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(mealId: m.id, isLocal: true)))),
              );
            },
          );
        },
      ),
    );
  }
}
