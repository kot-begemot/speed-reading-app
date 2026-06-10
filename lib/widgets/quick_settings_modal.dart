import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../providers/settings_provider.dart';

/// In-reader quick settings (spec §6 QuickReaderSettingsModal): a subset that
/// applies live. Full settings live in [SettingsScreen].
Future<void> showQuickReaderSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _QuickSettingsSheet(),
  );
}

class _QuickSettingsSheet extends ConsumerWidget {
  const _QuickSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick settings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _label(theme, 'Speed', '${settings.wordsPerMinute} WPM'),
            Slider(
              min: ReaderSettings.minWpm.toDouble(),
              max: ReaderSettings.maxWpm.toDouble(),
              divisions: ReaderSettings.maxWpm - ReaderSettings.minWpm,
              value: settings.wordsPerMinute.toDouble(),
              label: '${settings.wordsPerMinute}',
              onChanged: (v) => notifier.setWordsPerMinute(v.round()),
            ),
            _label(theme, 'Font size', '${settings.fontSize.round()}'),
            Slider(
              min: ReaderSettings.minFontSize,
              max: ReaderSettings.maxFontSize,
              divisions:
                  (ReaderSettings.maxFontSize - ReaderSettings.minFontSize)
                      .round(),
              value: settings.fontSize,
              label: settings.fontSize.round().toString(),
              onChanged: notifier.setFontSize,
            ),
            const SizedBox(height: 8),
            _label(theme, 'Words per entry', '${settings.wordsPerEntry}'),
            const SizedBox(height: 6),
            Align(
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
                onSelectionChanged: (s) => notifier.setWordsPerEntry(s.first),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show helper text'),
              value: settings.showHelperText,
              onChanged: notifier.setShowHelperText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ThemeData theme, String title, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      );
}
