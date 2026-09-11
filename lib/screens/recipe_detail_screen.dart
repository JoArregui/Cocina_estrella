import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/meal.dart';
import '../providers/providers.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String mealId;
  final bool isLocal;
  final Meal? localMeal; // for AI-generated ephemeral meals
  const RecipeDetailScreen({super.key, required this.mealId, this.isLocal = false, this.localMeal});
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.localMeal != null) return _buildContent(widget.localMeal!);
    if (widget.isLocal || widget.mealId.startsWith('user_')) {
      final localAsync = ref.watch(localMealProvider(widget.mealId));
      return localAsync.when(loading: () => _buildLoading(), error: (e, _) => _buildError(e.toString()), data: (meal) => meal == null ? _buildError('Receta local no encontrada') : _buildContent(meal));
    }
    if (widget.mealId.startsWith('sp_') || widget.mealId.startsWith('ai_')) {
      // Spoonacular/AI ids handled via unified may need direct fetch; fallback to mealDetail error
    }
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));
    return mealAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (meal) => _buildContent(meal),
    );
  }

  Widget _buildLoading() {
    return Scaffold(backgroundColor: const Color(0xFFF8F4F0), body: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column(children: [Container(height: 300, color: Colors.white), const SizedBox(height: 16), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: List.generate(5, (_) => Container(margin: const EdgeInsets.only(bottom: 12), height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))))) ])));
  }

  Widget _buildError(String error) {
    return Scaffold(appBar: AppBar(backgroundColor: const Color(0xFFF8F4F0), elevation: 0), backgroundColor: const Color(0xFFF8F4F0), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: Colors.grey), const SizedBox(height: 12), Text('No se pudo cargar la receta', style: GoogleFonts.nunito(fontSize: 16)), const SizedBox(height: 4), Text(error, style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: () => ref.invalidate(mealDetailProvider(widget.mealId)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8490F)), child: const Text('Reintentar'))])));
  }

  Widget _buildContent(Meal meal) {
    final steps = _parseSteps(meal.instructions);
    final isFav = ref.watch(favoritesProvider).contains(meal.id);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CookingModeScreen(meal: meal, steps: steps))), backgroundColor: const Color(0xFFE8490F), foregroundColor: Colors.white, elevation: 4, icon: const Icon(Icons.menu_book, size: 20), label: Text('Modo Cocinero', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14))),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(expandedHeight: 280, pinned: true, backgroundColor: const Color(0xFF1A1A1A), iconTheme: const IconThemeData(color: Colors.white), actions: [IconButton(icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white), onPressed: () async { await ref.read(favoritesProvider.notifier).toggle(meal); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFav ? 'Eliminado de favoritos' : 'Añadido a favoritos'))); })], flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [CachedNetworkImage(imageUrl: meal.thumbnail, fit: BoxFit.cover), Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)], stops: const [0.4, 1.0]))), Positioned(bottom: 20, left: 20, right: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_Tag(meal.category), const SizedBox(width: 8), _Tag(meal.area)]), const SizedBox(height: 8), Text(meal.name, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))]))]))),
          SliverPersistentHeader(pinned: true, delegate: _TabBarDelegate(TabBar(controller: _tabController, tabs: const [Tab(text: 'Ingredientes'), Tab(text: 'Preparación')], labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15), unselectedLabelStyle: GoogleFonts.nunito(fontSize: 15), labelColor: const Color(0xFFE8490F), unselectedLabelColor: const Color(0xFF888888), indicatorColor: const Color(0xFFE8490F), indicatorWeight: 3))),
        ],
        body: TabBarView(controller: _tabController, children: [_buildIngredientsTab(meal), _buildStepsTab(steps)]),
      ),
    );
  }

  Widget _buildIngredientsTab(Meal meal) {
    return ListView.separated(padding: const EdgeInsets.all(20), itemCount: meal.ingredients.length, separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)), itemBuilder: (context, index) {
      final ing = meal.ingredients[index];
      return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8490F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${index + 1}', style: GoogleFonts.nunito(color: const Color(0xFFE8490F), fontWeight: FontWeight.bold, fontSize: 14)))), const SizedBox(width: 14), Expanded(child: Text(ing.name, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)))), if (ing.measure.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)), child: Text(ing.measure, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555))))]));
    });
  }

  Widget _buildStepsTab(List<String> steps) {
    return Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), itemCount: steps.length, itemBuilder: (context, index) { final isActive = index == _currentStep; return GestureDetector(onTap: () => setState(() => _currentStep = index), child: AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isActive ? const Color(0xFFE8490F) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: isActive ? const Color(0xFFE8490F).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 30, height: 30, decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE8490F).withValues(alpha: 0.1), shape: BoxShape.circle), child: Center(child: Text('${index + 1}', style: GoogleFonts.nunito(color: isActive ? Colors.white : const Color(0xFFE8490F), fontWeight: FontWeight.bold, fontSize: 13)))), const SizedBox(width: 12), Expanded(child: Text(steps[index], style: GoogleFonts.nunito(fontSize: 14, color: isActive ? Colors.white : const Color(0xFF333333), height: 1.55)))]))); })), _buildStepNavigation(steps)]);
  }

  Widget _buildStepNavigation(List<String> steps) {
    return Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))]), child: Row(children: [Expanded(child: OutlinedButton(onPressed: _currentStep > 0 ? () => setState(() => _currentStep--) : null, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE8490F), side: const BorderSide(color: Color(0xFFE8490F)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('← Anterior'))), const SizedBox(width: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${_currentStep + 1}/${steps.length}', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: const Color(0xFF888888)))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _currentStep < steps.length - 1 ? () => setState(() => _currentStep++) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8490F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text('Siguiente →')))]));
  }

  List<String> _parseSteps(String instructions) {
    final lines = instructions.split(RegExp(r'\r\n|\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isNotEmpty && RegExp(r'^\d+\.').hasMatch(lines.first)) return lines.map((l) => l.replaceFirst(RegExp(r'^\d+\.\s*'), '')).toList();
    return lines;
  }
}

class _Tag extends StatelessWidget {
  final String label; const _Tag(this.label);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.4))), child: Text(label, style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)));
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar; const _TabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height + 1; @override double get maxExtent => tabBar.preferredSize.height + 1;
  @override Widget build(context, shrinkOffset, overlapsContent) => Container(color: const Color(0xFFF8F4F0), child: tabBar);
  @override bool shouldRebuild(_TabBarDelegate old) => false;
}
