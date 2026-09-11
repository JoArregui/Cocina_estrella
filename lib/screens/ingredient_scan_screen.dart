import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import '../providers/providers.dart';
import '../widgets/suggestion_card.dart';
import 'recipe_detail_screen.dart';
import 'cooking_mode_screen.dart';

class IngredientScanScreen extends ConsumerStatefulWidget {
  const IngredientScanScreen({super.key});
  @override
  ConsumerState<IngredientScanScreen> createState() => _IngredientScanScreenState();
}

class _IngredientScanScreenState extends ConsumerState<IngredientScanScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _inputMode = 'text';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (file == null) return;
    setState(() {
      _image = File(file.path);
    });
    ref.read(chefIaProvider.notifier).clear();
  }

  Future<void> _analyze() async {
    if (_inputMode == 'camera' && _image != null) {
      await ref.read(chefIaProvider.notifier).analyzeImage(ImageFileWrapper(_image!));
    } else if (_inputMode == 'text' && _textController.text.trim().isNotEmpty) {
      await ref.read(chefIaProvider.notifier).analyzeText(_textController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chefIaProvider);
    final ai = ref.watch(aiServiceProvider);
    final providerLabel = ai.providerName.contains('muse-spark')
        ? 'Muse Spark'
        : ai.providerName.contains('nemotron')
            ? 'Nemotron'
            : ai.providerName.contains('proxy')
                ? 'Proxy'
                : 'Gemini';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F4F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Text('Chef IA', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8490F).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE8490F)),
                const SizedBox(width: 4),
                Text(providerLabel, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFE8490F)))
              ])),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildInputToggle(),
          const SizedBox(height: 16),
          if (_inputMode == 'text') _buildTextInput(),
          if (_inputMode == 'camera') _buildCameraInput(),
          const SizedBox(height: 20),
          _buildAnalyzeButton(state),
          if (state.analyzing) ...[const SizedBox(height: 32), _buildLoadingState()],
          if (state.error != null) ...[const SizedBox(height: 20), _buildError(state.error!)],
          if (state.ingredients.isNotEmpty) ...[const SizedBox(height: 28), _buildIngredientsFound(state.ingredients)],
          if (state.suggestions.isNotEmpty) ...[const SizedBox(height: 28), _buildSuggestions(state)],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('¿Qué hay en\ntu nevera?', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), height: 1.2)), const SizedBox(height: 8), Text('Haz una foto o escribe tus ingredientes y la IA te sugerirá platos deliciosos.', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF888888), height: 1.5))]);

  Widget _buildInputToggle() => Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]), child: Row(children: [ToggleTab(icon: Icons.edit_note, label: 'Escribir lista', selected: _inputMode == 'text', onTap: () => setState(() => _inputMode = 'text')), ToggleTab(icon: Icons.camera_alt, label: 'Foto ingredientes', selected: _inputMode == 'camera', onTap: () => setState(() => _inputMode = 'camera'))]));

  Widget _buildTextInput() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]), child: TextField(controller: _textController, maxLines: 4, style: GoogleFonts.nunito(fontSize: 15), decoration: InputDecoration(hintText: 'Ej: pollo, tomate, cebolla, pimiento, arroz...', hintStyle: GoogleFonts.nunito(color: const Color(0xFFBBBBBB), fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.all(16), prefixIcon: const Padding(padding: EdgeInsets.only(left: 12, right: 8, top: 14), child: Icon(Icons.restaurant_menu, color: Color(0xFFE8490F), size: 22)), prefixIconConstraints: const BoxConstraints())));

  Widget _buildCameraInput() => Column(children: [_image != null ? Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image!, width: double.infinity, height: 220, fit: BoxFit.cover)), Positioned(top: 10, right: 10, child: GestureDetector(onTap: () => setState(() { _image = null; ref.read(chefIaProvider.notifier).clear(); }), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18))))]) : GestureDetector(onTap: () => _pickImage(ImageSource.camera), child: Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8490F).withValues(alpha: 0.3), width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE8490F).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Color(0xFFE8490F), size: 32)), const SizedBox(height: 12), Text('Toca para hacer una foto', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF555555))), const SizedBox(height: 4), Text('Apunta a tus ingredientes', style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFFAAAAAA)))]))), const SizedBox(height: 12), Row(children: [Expanded(child: ImageSourceButton(icon: Icons.camera_alt, label: 'Cámara', onTap: () => _pickImage(ImageSource.camera))), const SizedBox(width: 12), Expanded(child: ImageSourceButton(icon: Icons.photo_library, label: 'Galería', onTap: () => _pickImage(ImageSource.gallery)))])]);

  Widget _buildAnalyzeButton(ChefIaState state) {
    final canAnalyze = _inputMode == 'text' ? _textController.text.trim().isNotEmpty : _image != null;
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: canAnalyze && !state.analyzing ? _analyze : null, icon: const Icon(Icons.auto_awesome, size: 20), label: Text(state.analyzing ? 'Analizando...' : 'Sugerir platos con IA', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8490F), foregroundColor: Colors.white, disabledBackgroundColor: const Color(0xFFE8490F).withValues(alpha: 0.4), disabledForegroundColor: Colors.white70, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0)));
  }

  Widget _buildLoadingState() => Center(child: Column(children: [ScaleTransition(scale: _pulseAnimation, child: Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFE8490F).withValues(alpha: 0.12), shape: BoxShape.circle), child: const Center(child: Icon(Icons.auto_awesome, color: Color(0xFFE8490F), size: 34)))), const SizedBox(height: 16), Text('La IA está analizando\ntus ingredientes...', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 18, color: const Color(0xFF333333), height: 1.4)), const SizedBox(height: 8), Text('Buscando las mejores combinaciones', style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFFAAAAAA)))]));
  Widget _buildError(String error) {
    final isKeyError = error.contains('403') || error.contains('401') || error.contains('inválida') || error.contains('.env') || error.contains('API Key') || error.contains('OPENROUTER');
    final ai = ref.read(aiServiceProvider);
    final hint = ai.providerName.contains('openrouter')
        ? 'Revisa OPENROUTER_API_KEY en https://openrouter.ai/keys o usa --dart-define=OPENROUTER_API_KEY=sk-or-...'
        : 'Revisa GEMINI_API_KEY vía --dart-define o .env, o configura GEMINI_PROXY_URL';
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withValues(alpha: 0.2))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isKeyError ? 'API Key inválida (${ai.providerName})' : 'Error al conectar con la IA', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.red[700], fontSize: 14)), const SizedBox(height: 4), Text(isKeyError ? hint : error, style: GoogleFonts.nunito(color: Colors.red[600], fontSize: 13))]))]));
  }

  Widget _buildIngredientsFound(List<String> ingredients) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ingredientes detectados', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: ingredients.map((ing) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE8490F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8490F).withValues(alpha: 0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, size: 14, color: Color(0xFFE8490F)), const SizedBox(width: 5), Text(ing, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFE8490F)))]))).toList())]);

  Widget _buildSuggestions(ChefIaState state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('Platos sugeridos', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))), const Spacer(), Text('${state.suggestions.length} opciones', style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF888888)))]), const SizedBox(height: 14), ...state.suggestions.asMap().entries.map((entry) { final index = entry.key; final s = entry.value; final meal = index < state.matchedMeals.length ? state.matchedMeals[index] : null; return SuggestionCard(suggestion: s, meal: meal, onTap: () { if (meal != null && meal.id.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(mealId: meal.id))); }, onCookingMode: () => _openCookingMode(s, meal, state.ingredients)); })]);

  void _openCookingMode(suggestion, MealSummary? mealSummary, List<String> ingredients) {
    final fakeMeal = Meal(id: mealSummary?.id ?? '', name: suggestion.nameEs, category: suggestion.difficulty, area: suggestion.time, instructions: '', thumbnail: mealSummary?.thumbnail ?? '', ingredients: ingredients.map((ing) => MealIngredient(name: ing, measure: '')).toList());
    final steps = ['Prepara y lava todos los ingredientes: ${ingredients.join(', ')}.', 'Corta y trocea los ingredientes según sea necesario.', 'Calienta la sartén o cacerola a fuego medio con un poco de aceite.', 'Añade los ingredientes en orden según la receta de ${suggestion.nameEs}.', 'Cocina durante aproximadamente ${suggestion.time} hasta que esté listo.', 'Sazona al gusto con sal, pimienta y las especias que prefieras.', '¡Sirve caliente y disfruta tu ${suggestion.nameEs}!'];
    Navigator.push(context, MaterialPageRoute(builder: (_) => CookingModeScreen(meal: fakeMeal, steps: steps)));
  }
}
