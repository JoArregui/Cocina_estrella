import 'package:flutter/material.dart';

/// Paleta centralizada — evita duplicar hex literals en cada archivo.
/// Reemplaza usos directos de `Color(0xFF...)` dispersos.
abstract class AppColors {
  // Primary
  static const primary = Color(0xFFE8490F);
  static const primaryLight = Color(0xFFFF7A45);
  static const primaryAlpha12 = Color(0x1FE8490F); // 12%
  static const primaryAlpha10 = Color(0x1AE8490F);
  static const primaryAlpha08 = Color(0x14E8490F);

  // Neutrals
  static const background = Color(0xFFF8F4F0);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF555555);
  static const textTertiary = Color(0xFF888888);
  static const textHint = Color(0xFFAAAAAA);
  static const textMuted = Color(0xFFCCCCCC);
  static const divider = Color(0xFFEEEEEE);

  // Semantic
  static const success = Colors.green;
  static const warning = Colors.orange;
  static const error = Colors.red;

  // Overlays
  static Color blackOverlay(double opacity) =>
      Colors.black.withValues(alpha: opacity);
  static Color whiteOverlay(double opacity) =>
      Colors.white.withValues(alpha: opacity);
  static Color primaryOverlay(double opacity) =>
      primary.withValues(alpha: opacity);
}
