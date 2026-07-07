import 'package:flutter/material.dart';

/// Static design tokens for the Trainer mock screens.
///
/// These mirror the light-theme palette used in the Pencil design file
/// (`designs/app.pen`). The trainer screens are UI-only mocks — no logic —
/// so colors are hardcoded here rather than resolved from the app theme.
class T {
  T._();

  // Core surfaces & text
  static const primary = Color(0xFF4C6EF5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF1F3F5);
  static const surfaceContainer = Color(0xFFE9ECEF);
  static const textPrimary = Color(0xFF1A1C1E);
  static const textSecondary = Color(0xFF5C5F66);
  static const border = Color(0xFFDEE2E6);
  static const borderStrong = Color(0xFFCED4DA);
  static const error = Color(0xFFBA1A1A);

  // Reader accents
  static const centralLetter = Color(0xFFE8590C);
  static const guideLine = Color(0xFF9E9E9E);
  static const helperHighlight = Color(0xFFFFEB3B);

  // Status
  static const success = Color(0xFF2F9E44);
  static const successBg = Color(0xFFEBFBEE);
  static const warning = Color(0xFFE8590C);
  static const warningBg = Color(0xFFFFF4E6);
  static const dangerBg = Color(0xFFFFF0F0);
  static const primaryBg = Color(0xFFEDF0FE);
  static const accentViolet = Color(0xFF7048E8);
  static const accentTeal = Color(0xFF0CA678);
  static const gold = Color(0xFFF59F00);

  /// Blue→violet gradient used on hero/level surfaces.
  static const heroGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [primary, accentViolet],
  );

  /// A neutral card decoration (white, 0.8px border, radius 16).
  static BoxDecoration card({double radius = 16, Color? fill, Color? borderColor}) =>
      BoxDecoration(
        color: fill ?? surfaceLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border, width: 0.8),
      );
}
