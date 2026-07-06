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
  final double helperFontSize;
  final int wordsPerEntry;
  final bool showHelperText;
  final ThemeMode themeMode;

  // --- Light Theme Colors ---
  final Color? currentWordColorLight;
  final Color centralLetterColorLight;
  final Color guideLineColorLight;
  final Color helperHighlightColorLight;
  final Color? backgroundColorLight;
  final Color? focusBackgroundColorLight;
  final Color? progressBarColorLight;

  // --- Dark Theme Colors ---
  final Color? currentWordColorDark;
  final Color centralLetterColorDark;
  final Color guideLineColorDark;
  final Color helperHighlightColorDark;
  final Color? backgroundColorDark;
  final Color? focusBackgroundColorDark;
  final Color? progressBarColorDark;

  const ReaderSettings({
    this.wordsPerMinute = 300,
    this.fontType = ReaderFontType.system,
    this.fontSize = 32,
    this.helperFontSize = 20,
    this.wordsPerEntry = 1,
    this.showHelperText = true,
    this.themeMode = ThemeMode.system,
    
    // Light Defaults
    this.currentWordColorLight,
    this.backgroundColorLight,
    this.focusBackgroundColorLight,
    this.progressBarColorLight,
    this.centralLetterColorLight = const Color(0xFFE8590C), // orange
    this.guideLineColorLight = const Color(0xFF9E9E9E), // grey
    this.helperHighlightColorLight = const Color(0xFFFFEB3B), // yellow
    
    // Dark Defaults
    this.currentWordColorDark,
    this.backgroundColorDark,
    this.focusBackgroundColorDark,
    this.progressBarColorDark,
    this.centralLetterColorDark = const Color(0xFFE8590C), // orange
    this.guideLineColorDark = const Color(0xFF757575), // darker grey
    this.helperHighlightColorDark = const Color(0xFFF1C40F), // yellow
  });


  /// Spec bounds (§5A, §5C, §5D).
  static const int minWpm = 100;
  static const int maxWpm = 1000;
  static const double minFontSize = 16;
  static const double maxFontSize = 72;
  static const double minHelperFontSize = 12;
  static const double maxHelperFontSize = 48;
  static const int minWordsPerEntry = 1;
  static const int maxWordsPerEntry = 5;

  ReaderSettings copyWith({
    int? wordsPerMinute,
    ReaderFontType? fontType,
    double? fontSize,
    double? helperFontSize,
    int? wordsPerEntry,
    bool? showHelperText,
    ThemeMode? themeMode,
    
    // Light
    Color? currentWordColorLight,
    Color? backgroundColorLight,
    Color? focusBackgroundColorLight,
    Color? progressBarColorLight,
    Color? centralLetterColorLight,
    Color? guideLineColorLight,
    Color? helperHighlightColorLight,

    // Dark
    Color? currentWordColorDark,
    Color? backgroundColorDark,
    Color? focusBackgroundColorDark,
    Color? progressBarColorDark,
    Color? centralLetterColorDark,
    Color? guideLineColorDark,
    Color? helperHighlightColorDark,
  }) {
    return ReaderSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      fontType: fontType ?? this.fontType,
      fontSize: fontSize ?? this.fontSize,
      helperFontSize: helperFontSize ?? this.helperFontSize,
      wordsPerEntry: wordsPerEntry ?? this.wordsPerEntry,
      showHelperText: showHelperText ?? this.showHelperText,
      themeMode: themeMode ?? this.themeMode,
      
      // Light
      currentWordColorLight: currentWordColorLight ?? this.currentWordColorLight,
      backgroundColorLight: backgroundColorLight ?? this.backgroundColorLight,
      focusBackgroundColorLight: focusBackgroundColorLight ?? this.focusBackgroundColorLight,
      progressBarColorLight: progressBarColorLight ?? this.progressBarColorLight,
      centralLetterColorLight: centralLetterColorLight ?? this.centralLetterColorLight,
      guideLineColorLight: guideLineColorLight ?? this.guideLineColorLight,
      helperHighlightColorLight: helperHighlightColorLight ?? this.helperHighlightColorLight,

      // Dark
      currentWordColorDark: currentWordColorDark ?? this.currentWordColorDark,
      backgroundColorDark: backgroundColorDark ?? this.backgroundColorDark,
      focusBackgroundColorDark: focusBackgroundColorDark ?? this.focusBackgroundColorDark,
      progressBarColorDark: progressBarColorDark ?? this.progressBarColorDark,
      centralLetterColorDark: centralLetterColorDark ?? this.centralLetterColorDark,
      guideLineColorDark: guideLineColorDark ?? this.guideLineColorDark,
      helperHighlightColorDark: helperHighlightColorDark ?? this.helperHighlightColorDark,
    );
  }

  Map<String, dynamic> toJson() => {
        'wordsPerMinute': wordsPerMinute,
        'fontType': fontType.name,
        'fontSize': fontSize,
        'helperFontSize': helperFontSize,
        'wordsPerEntry': wordsPerEntry,
        'showHelperText': showHelperText,
        'themeMode': themeMode.name,
        
        // Light
        'currentWordColorLight': currentWordColorLight?.toARGB32(),
        'backgroundColorLight': backgroundColorLight?.toARGB32(),
        'focusBackgroundColorLight': focusBackgroundColorLight?.toARGB32(),
        'progressBarColorLight': progressBarColorLight?.toARGB32(),
        'centralLetterColorLight': centralLetterColorLight.toARGB32(),
        'guideLineColorLight': guideLineColorLight.toARGB32(),
        'helperHighlightColorLight': helperHighlightColorLight.toARGB32(),

        // Dark
        'currentWordColorDark': currentWordColorDark?.toARGB32(),
        'backgroundColorDark': backgroundColorDark?.toARGB32(),
        'focusBackgroundColorDark': focusBackgroundColorDark?.toARGB32(),
        'progressBarColorDark': progressBarColorDark?.toARGB32(),
        'centralLetterColorDark': centralLetterColorDark.toARGB32(),
        'guideLineColorDark': guideLineColorDark.toARGB32(),
        'helperHighlightColorDark': helperHighlightColorDark.toARGB32(),
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    const defaults = ReaderSettings();
    Color? colorOrNull(Object? v) => v == null ? null : Color(v as int);
    Color colorOr(Object? v, Color fallback) =>
        v == null ? fallback : Color(v as int);

    final legacyCurrentWord = json['currentWordColor'];
    final legacyBackground = json['backgroundColor'];
    final legacyFocusBackground = json['focusBackgroundColor'];
    final legacyProgressBar = json['progressBarColor'];
    final legacyCentralLetter = json['centralLetterColor'];
    final legacyGuideLine = json['guideLineColor'];
    final legacyHelperHighlight = json['helperHighlightColor'];

    return ReaderSettings(
      wordsPerMinute: json['wordsPerMinute'] as int? ?? defaults.wordsPerMinute,
      fontType: ReaderFontType.values.byName(
          json['fontType'] as String? ?? defaults.fontType.name),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? defaults.fontSize,
      helperFontSize: (json['helperFontSize'] as num?)?.toDouble() ?? defaults.helperFontSize,
      wordsPerEntry: json['wordsPerEntry'] as int? ?? defaults.wordsPerEntry,
      showHelperText: json['showHelperText'] as bool? ?? defaults.showHelperText,
      themeMode: ThemeMode.values
          .byName(json['themeMode'] as String? ?? defaults.themeMode.name),
      
      // Light
      currentWordColorLight: colorOrNull(json['currentWordColorLight'] ?? legacyCurrentWord),
      backgroundColorLight: colorOrNull(json['backgroundColorLight'] ?? legacyBackground),
      focusBackgroundColorLight: colorOrNull(json['focusBackgroundColorLight'] ?? legacyFocusBackground),
      progressBarColorLight: colorOrNull(json['progressBarColorLight'] ?? legacyProgressBar),
      centralLetterColorLight: colorOr(
          json['centralLetterColorLight'] ?? legacyCentralLetter, defaults.centralLetterColorLight),
      guideLineColorLight: colorOr(
          json['guideLineColorLight'] ?? legacyGuideLine, defaults.guideLineColorLight),
      helperHighlightColorLight: colorOr(
          json['helperHighlightColorLight'] ?? legacyHelperHighlight, defaults.helperHighlightColorLight),

      // Dark
      currentWordColorDark: colorOrNull(json['currentWordColorDark'] ?? legacyCurrentWord),
      backgroundColorDark: colorOrNull(json['backgroundColorDark'] ?? legacyBackground),
      focusBackgroundColorDark: colorOrNull(json['focusBackgroundColorDark'] ?? legacyFocusBackground),
      progressBarColorDark: colorOrNull(json['progressBarColorDark'] ?? legacyProgressBar),
      centralLetterColorDark: colorOr(
          json['centralLetterColorDark'] ?? legacyCentralLetter, defaults.centralLetterColorDark),
      guideLineColorDark: colorOr(
          json['guideLineColorDark'] ?? legacyGuideLine, defaults.guideLineColorDark),
      helperHighlightColorDark: colorOr(
          json['helperHighlightColorDark'] ?? legacyHelperHighlight, defaults.helperHighlightColorDark),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.wordsPerMinute == wordsPerMinute &&
      other.fontType == fontType &&
      other.fontSize == fontSize &&
      other.helperFontSize == helperFontSize &&
      other.wordsPerEntry == wordsPerEntry &&
      other.showHelperText == showHelperText &&
      other.themeMode == themeMode &&
      
      // Light
      other.currentWordColorLight == currentWordColorLight &&
      other.backgroundColorLight == backgroundColorLight &&
      other.focusBackgroundColorLight == focusBackgroundColorLight &&
      other.progressBarColorLight == progressBarColorLight &&
      other.centralLetterColorLight == centralLetterColorLight &&
      other.guideLineColorLight == guideLineColorLight &&
      other.helperHighlightColorLight == helperHighlightColorLight &&

      // Dark
      other.currentWordColorDark == currentWordColorDark &&
      other.backgroundColorDark == backgroundColorDark &&
      other.focusBackgroundColorDark == focusBackgroundColorDark &&
      other.progressBarColorDark == progressBarColorDark &&
      other.centralLetterColorDark == centralLetterColorDark &&
      other.guideLineColorDark == guideLineColorDark &&
      other.helperHighlightColorDark == helperHighlightColorDark;

  @override
  int get hashCode => Object.hashAll([
        wordsPerMinute,
        fontType,
        fontSize,
        helperFontSize,
        wordsPerEntry,
        showHelperText,
        themeMode,
        currentWordColorLight,
        backgroundColorLight,
        focusBackgroundColorLight,
        progressBarColorLight,
        centralLetterColorLight,
        guideLineColorLight,
        helperHighlightColorLight,
        currentWordColorDark,
        backgroundColorDark,
        focusBackgroundColorDark,
        progressBarColorDark,
        centralLetterColorDark,
        guideLineColorDark,
        helperHighlightColorDark,
      ]);
}
