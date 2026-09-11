import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal.dart';
import '../providers/providers.dart';
import '../services/local_recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipeFormScreen extends ConsumerStatefulWidget {
  final Meal? existing;
  const RecipeFormScreen({super.key, this.existing});
  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _category, _area, _instructions, _thumbnail;
  final List<TextEditingController> _ingNames = [];
  final List<TextEditingController> _ingMeasures = [];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _category = TextEditingController(text: m?.category ?? 'Varios');
    _area = TextEditingController(text: m?.area ?? 'Internacional');
    _instructions = TextEditingController(text: m?.instructions ?? '');
    _thumbnail = TextEditingController(text: m?.thumbnail ?? '');
    if (m != null) {
      for (final ing in m.ingredients) {
        _ingNames.add(TextEditingController(text: ing.name));
        _ingMeasures.add(TextEditingController(text: ing.measure));
      }
    } else {
      _ingNames.add(TextEditingController());
      _ingMeasures.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _area.dispose();
    _instructions.dispose();
    _thumbnail.dispose();
    for (final c in _ingNames) {
      c.dispose();
    }
    for (final c in _ingMeasures) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() => setState(() { _ingNames.add(TextEditingController()); _ingMeasures.add(TextEditingController()); });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ings = <MealIngredient>[];
    for (int i=0;i<_ingNames.length;i++) {
      if (_ingNames[i].text.trim().isEmpty) continue;
      ings.add(MealIngredient(name: _ingNames[i].text.trim(), measure: _ingMeasures[i].text.trim()));
    }
    final meal = Meal(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      category: _category.text.trim(),
      area: _area.text.trim(),
      instructions: _instructions.text.trim(),
      thumbnail: _thumbnail.text.trim().isEmpty ? 'https://via.placeholder.com/400x300.png?text=Mi+Receta' : _thumbnail.text.trim(),
      ingredients: ings,
    );
    final svc = LocalRecipeService();
    String id;
    if (widget.existing != null) {
      await svc.update(widget.existing!.id, meal);
      id = widget.existing!.id;
    } else {
      id = await svc.create(meal);
    }
    ref.invalidate(userRecipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receta guardada')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(mealId: id, isLocal: true)));
    }
  }

  Future<void> _generateWithAI() async {
    final prompt = _name.text.trim().isEmpty ? 'Receta original con ${_ingNames.where((c)=>c.text.isNotEmpty).map((c)=>c.text).join(', ')}' : _name.text.trim();
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final ai = ref.read(aiRecipeGeneratorProvider);
      final generated = await ai.generateFromPrompt(prompt, thumbnail: _thumbnail.text.trim());
      if (mounted) Navigator.pop(context);
      setState(() {
        _name.text = generated.name;
        _category.text = generated.category;
        _area.text = generated.area;
        _instructions.text = generated.instructions;
        for (final c in _ingNames) {
          c.dispose();
        }
        for (final c in _ingMeasures) {
          c.dispose();
        }
        _ingNames.clear();
        _ingMeasures.clear();
        for (final ing in generated.ingredients) {
          _ingNames.add(TextEditingController(text: ing.name));
          _ingMeasures.add(TextEditingController(text: ing.measure));
        }
      });
    } catch (e) {
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IA: ${e.toString()}'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F4F0), title: Text(widget.existing==null?'Nueva receta':'Editar receta', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)), actions: [TextButton.icon(onPressed: _generateWithAI, icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFE8490F)), label: Text('IA', style: GoogleFonts.nunito(color: const Color(0xFFE8490F), fontWeight: FontWeight.bold)))]),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v)=>v!.isEmpty?'Requerido':null),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Categoría'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _area, decoration: const InputDecoration(labelText: 'Origen')))]),
        const SizedBox(height: 12),
        TextFormField(controller: _thumbnail, decoration: const InputDecoration(labelText: 'URL imagen (opcional)')),
        const SizedBox(height: 16),
        Row(children: [Text('Ingredientes', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 16)), const Spacer(), IconButton(onPressed: _addIngredient, icon: const Icon(Icons.add_circle, color: Color(0xFFE8490F)))]),
        ...List.generate(_ingNames.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(flex: 3, child: TextFormField(controller: _ingNames[i], decoration: InputDecoration(labelText: 'Ingrediente ${i+1}'))), const SizedBox(width: 8), Expanded(flex: 2, child: TextFormField(controller: _ingMeasures[i], decoration: const InputDecoration(labelText: 'Medida'))), IconButton(onPressed: ()=> setState(() { _ingNames.removeAt(i); _ingMeasures.removeAt(i); }), icon: const Icon(Icons.close, size: 18))]))),
        const SizedBox(height: 16),
        TextFormField(controller: _instructions, decoration: const InputDecoration(labelText: 'Instrucciones (un paso por línea)'), maxLines: 6, validator: (v)=>v!.isEmpty?'Requerido':null),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(widget.existing==null?'Guardar receta':'Actualizar', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8490F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16))),
      ])),
    );
  }
}
