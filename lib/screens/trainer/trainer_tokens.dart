import 'package:flutter/material.dart';

/// Design tokens for the Trainer/Progress screens.
///
/// **Static (accent) tokens** — same in light and dark — are accessible as
/// `T.primary`, `T.accentViolet`, etc.
///
/// **Adaptive (surface / text / border) tokens** depend on the theme.  Call
/// `T.of(context)` once at the top of a `build()` method and use the returned
/// object: `t.surface`, `t.textPrimary`, `t.card()`, etc.
///
/// For backwards compatibility with runtime screens, the old static surface/text
/// token names are kept but marked deprecated — they always return the light-theme
/// value. Migrate call sites to `T.of(context)` to get proper dark-mode support.
class T {
  T._();

  // ── Accent / semantic colors — theme-independent constants ─────────────────

  static const Color primary = Color(0xFF4C6EF5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2F9E44);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFE8590C);
  static const Color gold = Color(0xFFF59F00);
  static const Color accentViolet = Color(0xFF7048E8);
  static const Color accentTeal = Color(0xFF0CA678);

  // Reader-only accents (kept for any cross-file references)
  static const Color centralLetter = Color(0xFFE8590C);
  static const Color guideLine = Color(0xFF9E9E9E);
  static const Color helperHighlight = Color(0xFFFFEB3B);

  /// Blue→violet gradient used on hero/level surfaces.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [primary, accentViolet],
  );

  // ── Legacy light-theme static tokens — kept for runtime-screen compat ─────
  //
  // These always return the light-theme value. For proper dark-mode support use
  // `T.of(context).xxx` instead.

  /// @deprecated Use `T.of(context).surface`
  static const Color surface = Color(0xFFF8F9FA);
  /// @deprecated Use `T.of(context).surfaceLowest`
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  /// @deprecated Use `T.of(context).surfaceLow`
  static const Color surfaceLow = Color(0xFFF1F3F5);
  /// @deprecated Use `T.of(context).surfaceContainer`
  static const Color surfaceContainer = Color(0xFFE9ECEF);
  /// @deprecated Use `T.of(context).textPrimary`
  static const Color textPrimary = Color(0xFF1A1C1E);
  /// @deprecated Use `T.of(context).textSecondary`
  static const Color textSecondary = Color(0xFF5C5F66);
  /// @deprecated Use `T.of(context).border`
  static const Color border = Color(0xFFDEE2E6);
  /// @deprecated Use `T.of(context).borderStrong`
  static const Color borderStrong = Color(0xFFCED4DA);
  /// @deprecated Use `T.of(context).successBg`
  static const Color successBg = Color(0xFFEBFBEE);
  /// @deprecated Use `T.of(context).dangerBg`
  static const Color dangerBg = Color(0xFFFFF0F0);
  /// @deprecated Use `T.of(context).primaryBg`
  static const Color primaryBg = Color(0xFFEDF0FE);
  /// @deprecated Use `T.of(context).warningBg`
  static const Color warningBg = Color(0xFFFFF4E6);

  /// @deprecated Use `T.of(context).card()`
  static BoxDecoration card({double radius = 16, Color? fill, Color? borderColor}) =>
      BoxDecoration(
        color: fill ?? surfaceLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border, width: 0.8),
      );

  // ── Adaptive instance ──────────────────────────────────────────────────────

  /// Returns the adaptive token set for [context].  Call once per build.
  static TTheme of(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TTheme._(cs, isDark);
  }
}

/// Adaptive tokens — resolved from the current [ColorScheme].
class TTheme {
  final ColorScheme _cs;
  final bool isDark;

  const TTheme._(this._cs, this.isDark);

  // ── Surfaces ───────────────────────────────────────────────────────────────

  Color get surface => _cs.surface;
  Color get surfaceLowest => _cs.surfaceContainerLowest;
  Color get surfaceLow => _cs.surfaceContainerLow;
  Color get surfaceContainer => _cs.surfaceContainer;

  // ── Text ──────────────────────────────────────────────────────────────────

  Color get textPrimary => _cs.onSurface;
  Color get textSecondary => _cs.onSurfaceVariant;

  // ── Borders ───────────────────────────────────────────────────────────────

  Color get border => _cs.outlineVariant;
  Color get borderStrong => _cs.outline;

  // ── Tinted backgrounds ────────────────────────────────────────────────────

  Color get successBg =>
      isDark ? const Color(0xFF002211) : const Color(0xFFEBFBEE);
  Color get dangerBg =>
      isDark ? const Color(0xFF2D0000) : const Color(0xFFFFF0F0);
  Color get primaryBg =>
      isDark ? const Color(0xFF0D1540) : const Color(0xFFEDF0FE);
  Color get warningBg =>
      isDark ? const Color(0xFF2A1200) : const Color(0xFFFFF4E6);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// A neutral card decoration.
  BoxDecoration card({double radius = 16, Color? fill, Color? borderColor}) =>
      BoxDecoration(
        color: fill ?? surfaceLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border, width: 0.8),
      );
}
