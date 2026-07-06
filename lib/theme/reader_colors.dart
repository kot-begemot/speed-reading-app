import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/reader_settings.dart';

/// Resolves the reader's effective colors, falling back theme-dependent ones
/// (null in [ReaderSettings]) to the active [ColorScheme].
class ReaderColors {
  final Color currentWord;
  final Color centralLetter;
  final Color guideLine;
  final Color helperHighlight;
  final Color background;
  final Color focusBackground;
  final Color progressBar;

  const ReaderColors({
    required this.currentWord,
    required this.centralLetter,
    required this.guideLine,
    required this.helperHighlight,
    required this.background,
    required this.focusBackground,
    required this.progressBar,
  });

  factory ReaderColors.resolve(ReaderSettings s, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return ReaderColors(
        currentWord: s.currentWordColorDark ?? scheme.onSurface,
        centralLetter: s.centralLetterColorDark,
        guideLine: s.guideLineColorDark,
        helperHighlight: s.helperHighlightColorDark,
        background: s.backgroundColorDark ?? scheme.surface,
        focusBackground: s.focusBackgroundColorDark ?? scheme.surfaceContainerHighest,
        progressBar: s.progressBarColorDark ?? scheme.primary,
      );
    } else {
      return ReaderColors(
        currentWord: s.currentWordColorLight ?? scheme.onSurface,
        centralLetter: s.centralLetterColorLight,
        guideLine: s.guideLineColorLight,
        helperHighlight: s.helperHighlightColorLight,
        background: s.backgroundColorLight ?? scheme.surface,
        focusBackground: s.focusBackgroundColorLight ?? scheme.surfaceContainerHighest,
        progressBar: s.progressBarColorLight ?? scheme.primary,
      );
    }
  }
}

/// Maps a [ReaderFontType] to a platform font family (null = system default).
String? readerFontFamily(ReaderFontType type) {
  switch (type) {
    case ReaderFontType.system:
      return null;
    case ReaderFontType.serif:
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return 'Georgia';
      }
      return 'serif';
    case ReaderFontType.sans:
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return 'Helvetica';
      }
      return 'sans-serif';
    case ReaderFontType.monospace:
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        return 'Courier';
      }
      return 'monospace';
  }
}
