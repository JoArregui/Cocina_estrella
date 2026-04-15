import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import 'recipe_detail_screen.dart';

// ─────────────────────────────────────────────
// CONSTANTE: pon aquí tu API key de Anthropic
// https://console.anthropic.com/
// ─────────────────────────────────────────────
final String _claudeApiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';

class IngredientScanScreen extends StatefulWidget {
  const IngredientScanScreen({super.key});

  @override
  State<IngredientScanScreen> createState() => _IngredientScanScreenState();
}

class _IngredientScanScreenState extends State<IngredientScanScreen>
    with SingleTickerProviderStateMixin {
  final MealService _mealService = MealService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _analyzing = false;
  List<String> _detectedIngredients = [];
  List<_RecipeSuggestion> _suggestions = [];
  List<MealSummary> _matchedMeals = [];
  String? _error;
  String _inputMode = 'text'; // 'text' | 'camera'

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ── PICK IMAGE ──────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (file == null) return;
    setState(() {
      _image = File(file.path);
      _suggestions = [];
      _detectedIngredients = [];
      _matchedMeals = [];
      _error = null;
    });
    await _analyzeWithClaude();
  }

  // ── ANALYZE ─────────────────────────────────
  Future<void> _analyzeWithClaude() async {
    if (_inputMode == 'camera' && _image == null) return;
    if (_inputMode == 'text' && _textController.text.trim().isEmpty) return;

    setState(() {
      _analyzing = true;
      _error = null;
      _suggestions = [];
      _detectedIngredients = [];
      _matchedMeals = [];
    });

    try {
      List<Map<String, dynamic>> content = [];

      if (_inputMode == 'camera' && _image != null) {
        final bytes = await _image!.readAsBytes();
        final b64 = base64Encode(bytes);
        content.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': 'image/jpeg',
            'data': b64,
          },
        });
        content.add({
          'type': 'text',
          'text':
              '''Analiza la imagen y detecta todos los ingredientes de cocina que ves.
Luego sugiere 5 platos que se puedan cocinar con esos ingredientes.

Responde SOLO con este JSON sin ningún texto adicional ni markdown:
{
  "ingredients": ["ingrediente1", "ingrediente2", ...],
  "suggestions": [
    {
      "name": "Nombre del plato en inglés (para buscar en TheMealDB)",
      "name_es": "Nombre en español",
      "description": "Descripción breve apetitosa (1-2 frases)",
      "difficulty": "Fácil|Media|Difícil",
      "time": "XX min",
      "match_percent": 90
    }
  ]
}''',
        });
      } else {
        content.add({
          'type': 'text',
          'text':
              '''Tengo estos ingredientes disponibles: ${_textController.text.trim()}

Sugiere 5 platos deliciosos que se puedan cocinar con ellos (pueden usarse ingredientes básicos de despensa como aceite, sal, pimienta, ajo aunque no los mencione).

Responde SOLO con este JSON sin ningún texto adicional ni markdown:
{
  "ingredients": ["ingrediente1", "ingrediente2", ...],
  "suggestions": [
    {
      "name": "Nombre del plato en inglés (para buscar en TheMealDB)",
      "name_es": "Nombre en español",
      "description": "Descripción breve apetitosa (1-2 frases)",
      "difficulty": "Fácil|Media|Difícil",
      "time": "XX min",
      "match_percent": 90
    }
  ]
}''',
        });
      }

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-opus-4-5',
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': content},
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error API: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final text = (data['content'] as List)
          .firstWhere((c) => c['type'] == 'text')['text'] as String;

      // Limpiar posibles bloques markdown
      final clean = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(clean);

      final ingredients = (parsed['ingredients'] as List)
          .map((e) => e.toString())
          .toList();

      final suggestions = (parsed['suggestions'] as List)
          .map((s) => _RecipeSuggestion.fromJson(s))
          .toList();

      setState(() {
        _detectedIngredients = ingredients;
        _suggestions = suggestions;
        _analyzing = false;
      });

      // Buscar en TheMealDB para obtener fotos reales
      await _fetchMealPhotos(suggestions);
    } catch (e) {
      setState(() {
        _error = 'Error al analizar: ${e.toString()}';
        _analyzing = false;
      });
    }
  }

  // ── FETCH PHOTOS FROM MEALDB ─────────────────
  Future<void> _fetchMealPhotos(List<_RecipeSuggestion> suggestions) async {
    final meals = <MealSummary>[];
    for (final s in suggestions) {
      try {
        final results = await _mealService.searchMeals(s.name);
        if (results.isNotEmpty) {
          meals.add(results.first);
        } else {
          // Intentar con nombre en español
          final results2 = await _mealService.searchMeals(s.nameEs);
          if (results2.isNotEmpty) meals.add(results2.first);
          else meals.add(MealSummary(id: '', name: s.nameEs, thumbnail: ''));
        }
      } catch (_) {
        meals.add(MealSummary(id: '', name: s.nameEs, thumbnail: ''));
      }
    }
    setState(() => _matchedMeals = meals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Text(
          'Chef IA',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8490F).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: Color(0xFFE8490F)),
                const SizedBox(width: 4),
                Text(
                  'Powered by Claude',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE8490F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInputToggle(),
            const SizedBox(height: 16),
            if (_inputMode == 'text') _buildTextInput(),
            if (_inputMode == 'camera') _buildCameraInput(),
            const SizedBox(height: 20),
            _buildAnalyzeButton(),
            if (_analyzing) ...[
              const SizedBox(height: 32),
              _buildLoadingState(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildError(),
            ],
            if (_detectedIngredients.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildIngredientsFound(),
            ],
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildSuggestions(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué hay en\ntu nevera?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Haz una foto o escribe tus ingredientes y la IA te sugerirá platos deliciosos.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFF888888),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _ToggleTab(
            icon: Icons.edit_note,
            label: 'Escribir lista',
            selected: _inputMode == 'text',
            onTap: () => setState(() => _inputMode = 'text'),
          ),
          _ToggleTab(
            icon: Icons.camera_alt,
            label: 'Foto ingredientes',
            selected: _inputMode == 'camera',
            onTap: () => setState(() => _inputMode = 'camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        maxLines: 4,
        style: GoogleFonts.nunito(fontSize: 15),
        decoration: InputDecoration(
          hintText:
              'Ej: pollo, tomate, cebolla, pimiento, arroz, queso...',
          hintStyle: GoogleFonts.nunito(
              color: const Color(0xFFBBBBBB), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8, top: 14),
            child: Icon(Icons.restaurant_menu,
                color: Color(0xFFE8490F), size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildCameraInput() {
    return Column(
      children: [
        if (_image != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _image!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _image = null;
                    _suggestions = [];
                    _detectedIngredients = [];
                    _matchedMeals = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8490F).withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8490F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Color(0xFFE8490F), size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toca para hacer una foto',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apunta a tus ingredientes',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImageSourceButton(
                icon: Icons.camera_alt,
                label: 'Cámara',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImageSourceButton(
                icon: Icons.photo_library,
                label: 'Galería',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final canAnalyze = _inputMode == 'text'
        ? _textController.text.trim().isNotEmpty
        : _image != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAnalyze && !_analyzing ? _analyzeWithClaude : null,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: Text(
          _analyzing ? 'Analizando...' : 'Sugerir platos con IA',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8490F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8490F).withOpacity(0.4),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8490F).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome,
                    color: Color(0xFFE8490F), size: 34),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Claude está analizando\ntus ingredientes...',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              color: const Color(0xFF333333),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buscando las mejores combinaciones',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final isApiKey = _error!.contains('401') || _error!.contains('API key');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApiKey
                      ? 'API Key no configurada'
                      : 'Error al conectar con la IA',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isApiKey
                      ? 'Edita el archivo ingredient_scan_screen.dart y reemplaza TU_API_KEY_AQUI por tu clave de console.anthropic.com'
                      : _error!,
                  style: GoogleFonts.nunito(
                    color: Colors.red[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsFound() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredientes detectados',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _detectedIngredients
              .map((ing) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8490F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8490F).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Color(0xFFE8490F)),
                        const SizedBox(width: 5),
                        Text(
                          ing,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE8490F),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Platos sugeridos',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Text(
              '${_suggestions.length} opciones',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          final meal = index < _matchedMeals.length
              ? _matchedMeals[index]
              : null;

          return _SuggestionCard(
            suggestion: s,
            meal: meal,
            onTap: () {
              if (meal != null && meal.id.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecipeDetailScreen(mealId: meal.id),
                  ),
                );
              }
            },
          );
        }),
      ],
    );
  }
}

// ── WIDGETS AUXILIARES ───────────────────────────────────────────

class _RecipeSuggestion {
  final String name;
  final String nameEs;
  final String description;
  final String difficulty;
  final String time;
  final int matchPercent;

  _RecipeSuggestion({
    required this.name,
    required this.nameEs,
    required this.description,
    required this.difficulty,
    required this.time,
    required this.matchPercent,
  });

  factory _RecipeSuggestion.fromJson(Map<String, dynamic> j) {
    return _RecipeSuggestion(
      name: j['name'] ?? '',
      nameEs: j['name_es'] ?? j['name'] ?? '',
      description: j['description'] ?? '',
      difficulty: j['difficulty'] ?? 'Media',
      time: j['time'] ?? '30 min',
      matchPercent: (j['match_percent'] ?? 80) as int,
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8490F) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : const Color(0xFF888888)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? Colors.white : const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE8490F)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _RecipeSuggestion suggestion;
  final MealSummary? meal;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.suggestion,
    required this.meal,
    required this.onTap,
  });

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Fácil':
        return Colors.green;
      case 'Difícil':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = meal != null && meal!.thumbnail.isNotEmpty;
    final hasRecipe = meal != null && meal!.id.isNotEmpty;

    return GestureDetector(
      onTap: hasRecipe ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Foto o placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: meal!.thumbnail,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match %
                    Row(
                      children: [
                        _MatchBadge(percent: suggestion.matchPercent),
                        const Spacer(),
                        if (hasRecipe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8490F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ver receta →',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE8490F),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      suggestion.nameEs,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.description,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: suggestion.time,
                        ),
                        const SizedBox(width: 6),
                        _InfoChip(
                          icon: Icons.bar_chart,
                          label: suggestion.difficulty,
                          color: _difficultyColor(suggestion.difficulty),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 110,
      color: const Color(0xFFE8490F).withOpacity(0.08),
      child: const Center(
        child: Icon(Icons.restaurant, color: Color(0xFFE8490F), size: 32),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int percent;
  const _MatchBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? Colors.green
        : percent >= 60
            ? Colors.orange
            : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '$percent% match',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF888888);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}