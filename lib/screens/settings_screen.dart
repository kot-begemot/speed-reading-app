import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/setting_row.dart';
import 'color_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _WpmControl(
            value: settings.wordsPerMinute,
            onChanged: notifier.setWordsPerMinute,
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Font',
            trailing: DropdownButton<ReaderFontType>(
              value: settings.fontType,
              underline: const SizedBox.shrink(),
              onChanged: (v) =>
                  v == null ? null : notifier.setFontType(v),
              items: const [
                DropdownMenuItem(
                    value: ReaderFontType.system, child: Text('System')),
                DropdownMenuItem(
                    value: ReaderFontType.serif, child: Text('Serif')),
                DropdownMenuItem(
                    value: ReaderFontType.sans, child: Text('Sans')),
                DropdownMenuItem(
                    value: ReaderFontType.monospace, child: Text('Mono')),
              ],
            ),
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Font size',
            subtitle: '${settings.fontSize.round()}',
            below: Slider(
              min: ReaderSettings.minFontSize,
              max: ReaderSettings.maxFontSize,
              divisions:
                  (ReaderSettings.maxFontSize - ReaderSettings.minFontSize)
                      .round(),
              value: settings.fontSize,
              label: settings.fontSize.round().toString(),
              onChanged: notifier.setFontSize,
            ),
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Words per entry',
            subtitle: 'Words shown at once',
            below: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {settings.wordsPerEntry},
                onSelectionChanged: (s) =>
                    notifier.setWordsPerEntry(s.first),
              ),
            ),
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Helper text',
            subtitle: 'Show the full-text panel below the reader',
            trailing: Switch(
              value: settings.showHelperText,
              onChanged: notifier.setShowHelperText,
            ),
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Theme',
            below: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => notifier.setThemeMode(s.first),
              ),
            ),
          ),
          const Divider(height: 1),
          SettingTile(
            title: 'Colors',
            subtitle: 'Reader colors',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ColorSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// WPM control: slider + exact numeric input (spec §5A), kept in sync.
class _WpmControl extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _WpmControl({required this.value, required this.onChanged});

  @override
  State<_WpmControl> createState() => _WpmControlState();
}

class _WpmControlState extends State<_WpmControl> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(_WpmControl old) {
    super.didUpdateWidget(old);
    final text = widget.value.toString();
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _controller.text = widget.value.toString();
      return;
    }
    final clamped =
        parsed.clamp(ReaderSettings.minWpm, ReaderSettings.maxWpm);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      title: 'Reading speed',
      subtitle: 'Words per minute',
      trailing: SizedBox(
        width: 84,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(),
          ),
          onSubmitted: _commit,
          onEditingComplete: () => _commit(_controller.text),
        ),
      ),
      below: Slider(
        min: ReaderSettings.minWpm.toDouble(),
        max: ReaderSettings.maxWpm.toDouble(),
        divisions: ReaderSettings.maxWpm - ReaderSettings.minWpm,
        value: widget.value.toDouble(),
        label: '${widget.value} WPM',
        onChanged: (v) => widget.onChanged(v.round()),
      ),
    );
  }
}
