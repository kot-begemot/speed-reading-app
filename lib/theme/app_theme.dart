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
    final isDark = brightness == Brightness.dark;
    
    var scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    if (isDark) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF101010),
        surfaceContainerHigh: const Color(0xFF181818),
        surfaceContainerHighest: const Color(0xFF222222),
        onSurface: Colors.white,
        onSurfaceVariant: const Color(0xFF9E9E9E),
        outline: const Color(0xFF424242),
        outlineVariant: const Color(0xFF202020),
      );
    } else {
      scheme = scheme.copyWith(
        surface: const Color(0xFFF8F9FA),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF1F3F5),
        surfaceContainer: const Color(0xFFE9ECEF),
        surfaceContainerHigh: const Color(0xFFDEE2E6),
        surfaceContainerHighest: const Color(0xFFCED4DA),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.6 : 0.8),
            width: 0.8,
          ),
        ),
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(isDark ? 0.6 : 0.8),
        thickness: 0.8,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          side: WidgetStateProperty.all(BorderSide(
            color: scheme.outlineVariant.withOpacity(isDark ? 0.6 : 0.8),
            width: 0.8,
          )),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
