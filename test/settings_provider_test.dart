import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/models/reader_settings.dart';
import 'package:speed_reading_app/providers/settings_provider.dart';
import 'package:speed_reading_app/services/settings_service.dart';

void main() {
  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        settingsServiceProvider.overrideWithValue(SettingsService.inMemory()),
      ]);

  test('granular setters update live state', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);

    n.setWordsPerMinute(450);
    n.setWordsPerEntry(3);
    n.setShowHelperText(false);
    n.setHelperFontSize(22);

    final s = c.read(settingsProvider);
    expect(s.wordsPerMinute, 450);
    expect(s.wordsPerEntry, 3);
    expect(s.showHelperText, false);
    expect(s.helperFontSize, 22);
  });

  test('setColor sets a concrete color; resetColors restores defaults only', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);

    n.setWordsPerMinute(700);
    n.setColor(ReaderColorSlot.currentWord, const Color(0xFF112233), isDark: false);
    expect(c.read(settingsProvider).currentWordColorLight, const Color(0xFF112233));

    n.resetColors();
    final s = c.read(settingsProvider);
    expect(s.currentWordColorLight, isNull); // back to theme-dependent default
    expect(s.wordsPerMinute, 700); // other settings preserved
  });

  test('themeMode provider derives from settings', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
    c.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(c.read(themeModeProvider), ThemeMode.dark);
  });
}
