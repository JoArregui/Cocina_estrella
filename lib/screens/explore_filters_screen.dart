import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/translator.dart';
import '../widgets/meal_card.dart';
import 'recipe_detail_screen.dart';

class ExploreFiltersScreen extends ConsumerStatefulWidget {
  const ExploreFiltersScreen({super.key});
  @override
  ConsumerState<ExploreFiltersScreen> createState() => _ExploreFiltersScreenState();
}

class _ExploreFiltersScreenState extends ConsumerState<ExploreFiltersScreen> {
  String? _selectedArea;
  String? _selectedIngredient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F4F0), title: Text('Explorar', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), iconTheme: const IconThemeData(color: Color(0xFF1A1A1A))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filtrar por origen', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _AreaChips(selected: _selectedArea, onSelected: (a) => setState(() => _selectedArea = a)),
          const SizedBox(height: 20),
          Text('Filtrar por ingrediente', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _IngredientChips(selected: _selectedIngredient, onSelected: (i) => setState(() => _selectedIngredient = i)),
          const SizedBox(height: 24),
          if (_selectedArea != null || _selectedIngredient != null)
            _ResultsGrid(area: _selectedArea, ingredient: _selectedIngredient),
        ]),
      ),
    );
  }
}

class _AreaChips extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _AreaChips({required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider);
    return areasAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (areas) => Wrap(spacing: 8, runSpacing: 8, children: areas.take(20).map((a) => ChoiceChip(label: Text(Translator.area(a)), selected: selected == a, onSelected: (v) => onSelected(v ? a : null), selectedColor: const Color(0xFFE8490F).withValues(alpha: 0.2))).toList()),
    );
  }
}

class _IngredientChips extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _IngredientChips({required this.selected, required this.onSelected});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingsAsync = ref.watch(ingredientsProvider);
    return ingsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (ings) => Wrap(spacing: 8, runSpacing: 8, children: ings.take(20).map((i) => ChoiceChip(label: Text(i), selected: selected == i, onSelected: (v) => onSelected(v ? i : null), selectedColor: const Color(0xFFE8490F).withValues(alpha: 0.2))).toList()),
    );
  }
}

class _ResultsGrid extends ConsumerWidget {
  final String? area;
  final String? ingredient;
  const _ResultsGrid({this.area, this.ingredient});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ingredient != null ? ref.watch(mealsByIngredientProvider(ingredient!)) : ref.watch(mealsByAreaProvider(area!));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(e.toString()),
      data: (meals) {
        if (meals.isEmpty) return Text('Sin resultados', style: GoogleFonts.nunito());
        return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.85), itemCount: meals.length, itemBuilder: (_, i) => MealCard(meal: meals[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(mealId: meals[i].id)))));
      },
    );
  }
}
