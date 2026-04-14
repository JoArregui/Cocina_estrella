import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../utils/translator.dart'; // Importación necesaria para traducir
import 'recipe_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final MealCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final MealService _service = MealService();
  List<MealSummary> _meals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final meals = await _service.getMealsByCategory(widget.category.name);
      setState(() {
        _meals = meals;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFE8490F),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                // Traducimos el nombre de la categoría en el AppBar
                Translator.category(widget.category.name),
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.category.thumbnail,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${_meals.length} recetas',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  childCount: 6,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadMeals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8490F),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MealCard(
                    meal: _meals[index],
                    onTap: () => _openMeal(_meals[index]),
                  ),
                  childCount: _meals.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openMeal(MealSummary meal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(mealId: meal.id),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealSummary meal;
  final VoidCallback onTap;

  const _MealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: '${meal.thumbnail}/medium',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    imageUrl: meal.thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                meal.name,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}