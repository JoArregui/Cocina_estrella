import 'dart:io';
import 'gemini_service.dart';

/// Interfaz común para todos los proveedores IA (Gemini, OpenRouter/Muse Spark, Nemotron, proxy).
/// Permite cambiar de proveedor sin tocar UI ni providers.
abstract class AIService {
  Future<GeminiResult> analyze({File? image, String? textIngredients});
  String get providerName;
  bool get isConfigured;
}
