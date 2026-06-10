import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../services/settings_service.dart';

/// Provides the [SettingsService]. Defaults to a non-persistent in-memory
/// instance so settings always resolve (tests, first frame). `main` overrides
/// this with the persistent service loaded from `shared_preferences`.
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService.inMemory(),
);

/// Live reading settings. Mutations update state immediately and persist
/// through the service.
class SettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() => ref.watch(settingsServiceProvider).current;

  void update(ReaderSettings settings) {
    state = settings;
    ref.read(settingsServiceProvider).save(settings);
  }

  void setWordsPerMinute(int value) =>
      update(state.copyWith(wordsPerMinute: value));
  void setFontType(ReaderFontType value) =>
      update(state.copyWith(fontType: value));
  void setFontSize(double value) => update(state.copyWith(fontSize: value));
  void setWordsPerEntry(int value) =>
      update(state.copyWith(wordsPerEntry: value));
  void setShowHelperText(bool value) =>
      update(state.copyWith(showHelperText: value));
  void setThemeMode(ThemeMode value) =>
      update(state.copyWith(themeMode: value));

  void setColor(ReaderColorSlot slot, Color color) {
    switch (slot) {
      case ReaderColorSlot.currentWord:
        update(state.copyWith(currentWordColor: color));
      case ReaderColorSlot.centralLetter:
        update(state.copyWith(centralLetterColor: color));
      case ReaderColorSlot.guideLine:
        update(state.copyWith(guideLineColor: color));
      case ReaderColorSlot.helperHighlight:
        update(state.copyWith(helperHighlightColor: color));
      case ReaderColorSlot.background:
        update(state.copyWith(backgroundColor: color));
      case ReaderColorSlot.focusBackground:
        update(state.copyWith(focusBackgroundColor: color));
      case ReaderColorSlot.progressBar:
        update(state.copyWith(progressBarColor: color));
    }
  }

  /// Resets only the colors to defaults, preserving all other settings.
  /// (Rebuilds via the constructor so theme-dependent colors return to null.)
  void resetColors() => update(ReaderSettings(
        wordsPerMinute: state.wordsPerMinute,
        fontType: state.fontType,
        fontSize: state.fontSize,
        wordsPerEntry: state.wordsPerEntry,
        showHelperText: state.showHelperText,
        themeMode: state.themeMode,
      ));

  void resetToDefaults() => update(const ReaderSettings());
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, ReaderSettings>(SettingsNotifier.new);

/// App theme mode, derived from settings (spec: light/dark/system switch).
final themeModeProvider =
    Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
