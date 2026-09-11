import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meal.dart';
import '../providers/providers.dart';
import 'cooking_mode_screen.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String mealId;
  final bool isLocal;
  final Meal? localMeal;
  const RecipeDetailScreen({
    super.key,
    required this.mealId,
    this.isLocal = false,
    this.localMeal,
  });
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Future<void> _openYoutube(String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir: $url'),
              action: SnackBarAction(
                label: 'Copiar',
                onPressed: () => Clipboard.setData(ClipboardData(text: url)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            action: SnackBarAction(
              label: 'Copiar',
              onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.localMeal != null) return _buildContent(widget.localMeal!);
    if (widget.isLocal || widget.mealId.startsWith('user_')) {
      final localAsync = ref.watch(localMealProvider(widget.mealId));
      return localAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e.toString()),
        data: (meal) => meal == null
            ? _buildError('Receta local no encontrada')
            : _buildContent(meal),
      );
    }
    final mealAsync = ref.watch(mealDetailProvider(widget.mealId));
    return mealAsync.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (meal) => _buildContent(meal),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F4F0), elevation: 0),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(height: 280, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(
                  5,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      backgroundColor: const Color(0xFFF8F4F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar la receta',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (widget.isLocal) {
                    ref.invalidate(localMealProvider(widget.mealId));
                  } else {
                    ref.invalidate(mealDetailProvider(widget.mealId));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8490F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Meal meal) {
    final steps = _parseSteps(meal.instructions);
    final isFav = ref.watch(favoritesProvider).contains(meal.id);
    final isUserRecipe = meal.id.startsWith('user_') || widget.isLocal;
    final isYouTube =
        meal.youtubeUrl != null && meal.youtubeUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CookingModeScreen(
              meal: meal,
              steps: steps.isEmpty
                  ? ['Sigue los ingredientes y cocina a tu gusto.']
                  : steps,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE8490F),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.menu_book, size: 20),
        label: Text(
          'Modo Cocinero',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A1A),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (isUserRecipe)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeFormScreen(existing: meal),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.white,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(favoritesProvider.notifier).toggle(meal);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'Eliminado de favoritos'
                            : 'Añadido a favoritos',
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  meal.thumbnail.isNotEmpty &&
                          !meal.thumbnail.contains('placeholder.com')
                      ? CachedNetworkImage(
                          imageUrl: meal.thumbnail,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: const Color(0xFF2A2A2A)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.white38,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(
                            Icons.restaurant,
                            size: 64,
                            color: Colors.white38,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _Tag(meal.category),
                            _Tag(meal.area),
                            if (meal.tags != null &&
                                meal.tags!.trim().isNotEmpty)
                              ...meal.tags!
                                  .split(',')
                                  .take(2)
                                  .map((t) => _Tag(t.trim())),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          meal.name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isYouTube) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _openYoutube(meal.youtubeUrl!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ver video en YouTube',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ingredientes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_basket,
                    color: Color(0xFFE8490F),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ingredientes',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${meal.ingredients.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF888888),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (meal.ingredients.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _emptyCard(
                  'No hay ingredientes registrados para esta receta.',
                ),
              ),
            ),
          if (meal.ingredients.isNotEmpty)
            SliverList.separated(
              itemCount: meal.ingredients.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (context, index) {
                final ing = meal.ingredients[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8490F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFFE8490F),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          ing.name,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (ing.measure.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1A1A1A,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ing.measure,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555555),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          // Preparación
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt,
                    color: Color(0xFFE8490F),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Preparación',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  if (steps.isNotEmpty)
                    Text(
                      '${steps.length} pasos',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (steps.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 32,
                            color: Color(0xFFE8490F),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin pasos detallados',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usa el Modo Cocinero para cocinar con los ingredientes. Si hay video, ábrelo para ver la preparación completa.',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: const Color(0xFF888888),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (isYouTube) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openYoutube(meal.youtubeUrl!),
                          icon: const Icon(Icons.play_circle_fill),
                          label: Text(
                            'Ver video en YouTube',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (steps.isNotEmpty)
            SliverList.builder(
              itemCount: steps.length + (isYouTube ? 1 : 0),
              itemBuilder: (context, index) {
                if (isYouTube && index == steps.length) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openYoutube(meal.youtubeUrl!),
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Ver video completo',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    index == 0 ? 8 : 0,
                    20,
                    index == steps.length - 1 && !isYouTube ? 100 : 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8490F),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: const Color(0xFF333333),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (steps.isNotEmpty && !isYouTube)
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          // ── Enlaces relacionados (búsqueda web automática 5-10 resultados) ──
          SliverToBoxAdapter(child: _WebSearchSection(dishName: meal.name)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE8490F), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(color: const Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseSteps(String instructions) {
    if (instructions.trim().isEmpty) return [];
    final lines = instructions
        .split(RegExp(r'\r\n|\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isNotEmpty && RegExp(r'^\d+\.').hasMatch(lines.first)) {
      return lines
          .map((l) => l.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
          .toList();
    }
    if (lines.length == 1) {
      final byDot = lines.first
          .split(RegExp(r'\.\s+'))
          .map((s) => s.trim())
          .where((s) => s.length > 10)
          .toList();
      if (byDot.length > 1) return byDot;
    }
    return lines;
  }
}

class _WebSearchSection extends ConsumerWidget {
  final String dishName;
  const _WebSearchSection({required this.dishName});

  IconData _iconFor(String source) {
    switch (source) {
      case 'youtube':
        return Icons.play_circle_fill;
      case 'google':
        return Icons.search;
      case 'bing':
        return Icons.travel_explore;
      case 'wikipedia':
        return Icons.menu_book;
      case 'tasty':
      case 'allrecipes':
      case 'cookpad':
        return Icons.restaurant;
      default:
        return Icons.link;
    }
  }

  Color _colorFor(String source) {
    switch (source) {
      case 'youtube':
        return Colors.red;
      case 'google':
        return const Color(0xFF4285F4);
      case 'bing':
        return const Color(0xFF008373);
      case 'wikipedia':
        return const Color(0xFF636466);
      default:
        return const Color(0xFFE8490F);
    }
  }

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir: $url'),
              action: SnackBarAction(
                label: 'Copiar',
                onPressed: () => Clipboard.setData(ClipboardData(text: url)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            action: SnackBarAction(
              label: 'Copiar',
              onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(webSearchProvider(dishName));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore,
                color: Color(0xFFE8490F),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Más información',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              async.when(
                data: (list) => Text(
                  '${list.length} enlaces',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Resultados web sobre "$dishName"',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No se pudo cargar la búsqueda: $e',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF888888),
                  fontSize: 13,
                ),
              ),
            ),
            data: (results) {
              if (results.isEmpty) return const SizedBox.shrink();
              return Column(
                children: results
                    .take(8)
                    .map(
                      (r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _colorFor(
                                r.source,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _iconFor(r.source),
                              color: _colorFor(r.source),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            r.title,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            r.snippet,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: const Color(0xFF888888),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: Color(0xFFCCCCCC),
                          ),
                          onTap: () => _open(r.url, context),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
    ),
    child: Text(
      label,
      style: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
