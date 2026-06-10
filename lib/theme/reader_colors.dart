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
    return ReaderColors(
      currentWord: s.currentWordColor ?? scheme.onSurface,
      centralLetter: s.centralLetterColor,
      guideLine: s.guideLineColor,
      helperHighlight: s.helperHighlightColor,
      background: s.backgroundColor ?? scheme.surface,
      focusBackground: s.focusBackgroundColor ?? scheme.surfaceContainerHighest,
      progressBar: s.progressBarColor ?? scheme.primary,
    );
  }
}

/// Maps a [ReaderFontType] to a platform font family (null = system default).
String? readerFontFamily(ReaderFontType type) {
  switch (type) {
    case ReaderFontType.system:
      return null;
    case ReaderFontType.serif:
      return 'serif';
    case ReaderFontType.sans:
      return 'sans-serif';
    case ReaderFontType.monospace:
      return 'monospace';
  }
}
