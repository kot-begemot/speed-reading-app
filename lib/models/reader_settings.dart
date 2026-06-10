import 'package:flutter/material.dart';

/// Font family choice for the reader (spec §5B). Mapped to an actual font at
/// render time so the model stays platform-agnostic.
enum ReaderFontType { system, serif, sans, monospace }

/// The editable reader colors (spec §5E).
enum ReaderColorSlot {
  currentWord,
  centralLetter,
  guideLine,
  helperHighlight,
  background,
  focusBackground,
  progressBar,
}

/// User-configurable reading settings (spec §5).
///
/// Persisted as JSON in `shared_preferences`. Colors serialize as `int` (ARGB)
/// and rebuild via `Color(value)`. Color fields that are theme-dependent in the
/// spec (current word, backgrounds, progress accent) are nullable: `null` means
/// "resolve from the active theme at render time".
@immutable
class ReaderSettings {
  final int wordsPerMinute;
  final ReaderFontType fontType;
  final double fontSize;
  final int wordsPerEntry;
  final bool showHelperText;
  final ThemeMode themeMode;

  /// null → theme `onSurface`.
  final Color? currentWordColor;
  final Color centralLetterColor;
  final Color guideLineColor;
  final Color helperHighlightColor;

  /// null → theme `surface`.
  final Color? backgroundColor;

  /// null → a neutral derived from theme.
  final Color? focusBackgroundColor;

  /// null → theme `primary` (accent).
  final Color? progressBarColor;

  const ReaderSettings({
    this.wordsPerMinute = 300,
    this.fontType = ReaderFontType.system,
    this.fontSize = 32,
    this.wordsPerEntry = 1,
    this.showHelperText = true,
    this.themeMode = ThemeMode.system,
    this.currentWordColor,
    this.centralLetterColor = const Color(0xFFE8590C), // red-orange
    this.guideLineColor = const Color(0xFF9E9E9E), // grey
    this.helperHighlightColor = const Color(0xFFFFEB3B), // yellow
    this.backgroundColor,
    this.focusBackgroundColor,
    this.progressBarColor,
  });

  /// Spec bounds (§5A, §5C, §5D).
  static const int minWpm = 100;
  static const int maxWpm = 1000;
  static const double minFontSize = 16;
  static const double maxFontSize = 72;
  static const int minWordsPerEntry = 1;
  static const int maxWordsPerEntry = 5;

  ReaderSettings copyWith({
    int? wordsPerMinute,
    ReaderFontType? fontType,
    double? fontSize,
    int? wordsPerEntry,
    bool? showHelperText,
    ThemeMode? themeMode,
    Color? currentWordColor,
    Color? centralLetterColor,
    Color? guideLineColor,
    Color? helperHighlightColor,
    Color? backgroundColor,
    Color? focusBackgroundColor,
    Color? progressBarColor,
  }) {
    return ReaderSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      fontType: fontType ?? this.fontType,
      fontSize: fontSize ?? this.fontSize,
      wordsPerEntry: wordsPerEntry ?? this.wordsPerEntry,
      showHelperText: showHelperText ?? this.showHelperText,
      themeMode: themeMode ?? this.themeMode,
      currentWordColor: currentWordColor ?? this.currentWordColor,
      centralLetterColor: centralLetterColor ?? this.centralLetterColor,
      guideLineColor: guideLineColor ?? this.guideLineColor,
      helperHighlightColor: helperHighlightColor ?? this.helperHighlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      focusBackgroundColor: focusBackgroundColor ?? this.focusBackgroundColor,
      progressBarColor: progressBarColor ?? this.progressBarColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'wordsPerMinute': wordsPerMinute,
        'fontType': fontType.name,
        'fontSize': fontSize,
        'wordsPerEntry': wordsPerEntry,
        'showHelperText': showHelperText,
        'themeMode': themeMode.name,
        'currentWordColor': currentWordColor?.toARGB32(),
        'centralLetterColor': centralLetterColor.toARGB32(),
        'guideLineColor': guideLineColor.toARGB32(),
        'helperHighlightColor': helperHighlightColor.toARGB32(),
        'backgroundColor': backgroundColor?.toARGB32(),
        'focusBackgroundColor': focusBackgroundColor?.toARGB32(),
        'progressBarColor': progressBarColor?.toARGB32(),
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ReaderSettings();
    Color? colorOrNull(Object? v) => v == null ? null : Color(v as int);
    Color colorOr(Object? v, Color fallback) =>
        v == null ? fallback : Color(v as int);
    return ReaderSettings(
      wordsPerMinute: json['wordsPerMinute'] as int? ?? defaults.wordsPerMinute,
      fontType: ReaderFontType.values.byName(
          json['fontType'] as String? ?? defaults.fontType.name),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      wordsPerEntry: json['wordsPerEntry'] as int? ?? defaults.wordsPerEntry,
      showHelperText: json['showHelperText'] as bool? ?? defaults.showHelperText,
      themeMode: ThemeMode.values
          .byName(json['themeMode'] as String? ?? defaults.themeMode.name),
      currentWordColor: colorOrNull(json['currentWordColor']),
      centralLetterColor:
          colorOr(json['centralLetterColor'], defaults.centralLetterColor),
      guideLineColor: colorOr(json['guideLineColor'], defaults.guideLineColor),
      helperHighlightColor:
          colorOr(json['helperHighlightColor'], defaults.helperHighlightColor),
      backgroundColor: colorOrNull(json['backgroundColor']),
      focusBackgroundColor: colorOrNull(json['focusBackgroundColor']),
      progressBarColor: colorOrNull(json['progressBarColor']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.wordsPerMinute == wordsPerMinute &&
      other.fontType == fontType &&
      other.fontSize == fontSize &&
      other.wordsPerEntry == wordsPerEntry &&
      other.showHelperText == showHelperText &&
      other.themeMode == themeMode &&
      other.currentWordColor == currentWordColor &&
      other.centralLetterColor == centralLetterColor &&
      other.guideLineColor == guideLineColor &&
      other.helperHighlightColor == helperHighlightColor &&
      other.backgroundColor == backgroundColor &&
      other.focusBackgroundColor == focusBackgroundColor &&
      other.progressBarColor == progressBarColor;

  @override
  int get hashCode => Object.hash(
        wordsPerMinute,
        fontType,
        fontSize,
        wordsPerEntry,
        showHelperText,
        themeMode,
        currentWordColor,
        centralLetterColor,
        guideLineColor,
        helperHighlightColor,
        backgroundColor,
        focusBackgroundColor,
        progressBarColor,
      );
}
