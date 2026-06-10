import 'package:flutter/material.dart';

/// Centralized light/dark themes for the app.
///
/// Reader-specific colors (current word, central letter, guide lines, helper
/// highlight, etc.) are NOT defined here — those live in [ReaderSettings] and
/// are user-configurable (spec §5E). This class only covers app chrome.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF4C6EF5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
