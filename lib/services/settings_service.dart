import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reader_settings.dart';

/// Loads/saves [ReaderSettings] as a JSON blob in `shared_preferences`.
///
/// Keeps the current value in memory so reads are synchronous. Use [open] for
/// the real persistent service, or [inMemory] for tests / provider defaults
/// where no plugin binding exists.
class SettingsService {
  SettingsService._(this._prefs, this._current);

  static const String _key = 'reader_settings';

  final SharedPreferences? _prefs;
  ReaderSettings _current;

  ReaderSettings get current => _current;

  static Future<SettingsService> open() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final settings = raw != null
        ? ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>)
        : const ReaderSettings();
    return SettingsService._(prefs, settings);
  }

  /// Non-persistent service for tests and the pre-override provider default.
  factory SettingsService.inMemory(
          [ReaderSettings initial = const ReaderSettings()]) =>
      SettingsService._(null, initial);

  Future<void> save(ReaderSettings settings) async {
    _current = settings;
    await _prefs?.setString(_key, jsonEncode(settings.toJson()));
  }
}
