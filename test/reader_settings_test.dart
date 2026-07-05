import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/models/reader_settings.dart';

void main() {
  test('defaults match the spec', () {
    const s = ReaderSettings();
    expect(s.wordsPerMinute, 300);
    expect(s.fontSize, 32);
    expect(s.wordsPerEntry, 1);
    expect(s.showHelperText, true);
    expect(s.themeMode, ThemeMode.system);
  });

  test('round-trips through JSON including a non-default color', () {
    const original = ReaderSettings(
      wordsPerMinute: 550,
      fontType: ReaderFontType.serif,
      fontSize: 48,
      wordsPerEntry: 3,
      showHelperText: false,
      themeMode: ThemeMode.dark,
      currentWordColorLight: Color(0xFF123456),
      helperHighlightColorLight: Color(0xFF00FF00),
      progressBarColorLight: Color(0xFFFF00FF),
    );

    final restored = ReaderSettings.fromJson(original.toJson());

    expect(restored, original);
    expect(restored.currentWordColorLight, const Color(0xFF123456));
    expect(restored.progressBarColorLight, const Color(0xFFFF00FF));
  });

  test('nullable theme-dependent colors survive as null', () {
    const s = ReaderSettings(); // currentWordColorLight/backgroundColorLight/etc are null
    final restored = ReaderSettings.fromJson(s.toJson());
    expect(restored.currentWordColorLight, isNull);
    expect(restored.backgroundColorLight, isNull);
    expect(restored.progressBarColorLight, isNull);
    expect(restored, s);
  });

  test('color int encoding is stable (toARGB32 ↔ Color)', () {
    const c = Color(0xFFAB12CD);
    expect(Color(c.toARGB32()), c);
  });
}
