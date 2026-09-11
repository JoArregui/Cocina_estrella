import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/providers.dart';
import 'recipe_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: GoogleFonts.nunito(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Buscar receta...',
            hintStyle: GoogleFonts.nunito(color: const Color(0xFFAAAAAA)),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFFAAAAAA)), onPressed: () { _controller.clear(); ref.read(searchQueryProvider.notifier).state = ''; setState(() {}); })
                : null,
          ),
        ),
      ),
      body: query.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Busca tu receta favorita', style: GoogleFonts.playfairDisplay(fontSize: 20, color: const Color(0xFF888888))),
                const SizedBox(height: 8),
                Text('Por ejemplo: pasta, pollo, sushi...', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFAAAAAA))),
              ]),
            )
          : resultsAsync.when(
              loading: () => ListView.builder(padding: const EdgeInsets.all(16), itemCount: 5, itemBuilder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(margin: const EdgeInsets.only(bottom: 12), height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))))),
              error: (e, _) => Center(child: Text(e.toString(), style: GoogleFonts.nunito())),
              data: (results) {
                if (results.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.no_meals, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Text('Sin resultados', style: GoogleFonts.playfairDisplay(fontSize: 20, color: const Color(0xFF888888))), const SizedBox(height: 8), Text('Prueba con otra palabra clave', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFFAAAAAA)))]));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final meal = results[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(mealId: meal.id))),
                      child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]), child: Row(children: [ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)), child: CachedNetworkImage(imageUrl: '${meal.thumbnail}/small', width: 80, height: 80, fit: BoxFit.cover, errorWidget: (_, __, ___) => CachedNetworkImage(imageUrl: meal.thumbnail, width: 80, height: 80, fit: BoxFit.cover))), const SizedBox(width: 14), Expanded(child: Text(meal.name, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)), maxLines: 2, overflow: TextOverflow.ellipsis)), const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)))])),
                    );
                  },
                );
              },
            ),
    );
  }
}
