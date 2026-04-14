import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../utils/translator.dart'; // Importamos el traductor
import 'category_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MealService _service = MealService();
  List<MealCategory> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final cats = await _service.getCategories();
      setState(() {
        _categories = cats;
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
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverToBoxAdapter(
            child: _buildSearchButton(),
          ),
          SliverToBoxAdapter(
            child: _buildSectionTitle('Categorías'),
          ),
          if (_loading)
            SliverToBoxAdapter(child: _buildShimmerGrid())
          else if (_error != null)
            SliverToBoxAdapter(child: _buildError())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CategoryCard(
                    category: _categories[index],
                    onTap: () => _openCategory(_categories[index]),
                  ),
                  childCount: _categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: const Color(0xFFF8F4F0),
      elevation: 0,
      title: Row(
        children: [
          // Aplicamos tu icono personalizado Escudo_sabor.png
          Image.asset(
            'assets/images/Escudo_sabor.png',
            height: 32,
            errorBuilder: (context, error, stackTrace) {
              // Fallback en caso de que la imagen no cargue
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8490F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            // Aplicamos la traducción a "Recetario"
            Translator.category('RecipeBook'), 
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué cocinamos\nhoy?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora cientos de recetas del mundo entero',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
              const SizedBox(width: 10),
              Text(
                'Buscar receta...',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Error de conexión', style: GoogleFonts.nunito(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadCategories,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8490F),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _openCategory(MealCategory cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(category: cat),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MealCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: category.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  Translator.category(category.name),
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}