import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyService {
  /// Orden de prioridad:
  /// 1. --dart-define=GEMINI_API_KEY (recomendado, no se empaqueta)
  /// 2. .env local (solo desarrollo, no incluir como asset en release)
  static String? getKey() {
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    try {
      return dotenv.maybeGet('GEMINI_API_KEY');
    } catch (_) {
      return null;
    }
  }

  static bool isValid(String? key) {
    return key != null && key.startsWith('AIza') && key.length > 20;
  }

  /// Mensaje útil para debug sin exponer la key
  static String getKeySource() {
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) return 'dart-define';
    if (dotenv.maybeGet('GEMINI_API_KEY') != null) return '.env (dev only)';
    return 'no configurada';
  }
}
