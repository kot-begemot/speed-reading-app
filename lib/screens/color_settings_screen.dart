import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../providers/settings_provider.dart';
import '../theme/reader_colors.dart';

/// Dedicated reader-color screen (spec §5E): one row per color, each opens a
/// picker; plus reset-to-default.
class ColorSettingsScreen extends ConsumerWidget {
  const ColorSettingsScreen({super.key});

  static const List<(ReaderColorSlot, String)> _rows = [
    (ReaderColorSlot.currentWord, 'Current word color'),
    (ReaderColorSlot.centralLetter, 'Central letter color'),
    (ReaderColorSlot.guideLine, 'Guide lines color'),
    (ReaderColorSlot.helperHighlight, 'Helper highlight color'),
    (ReaderColorSlot.background, 'Background color'),
    (ReaderColorSlot.focusBackground, 'Focus section background'),
    (ReaderColorSlot.progressBar, 'Progress bar color'),
  ];

  Color _resolved(ReaderColorSlot slot, ReaderColors c) {
    switch (slot) {
      case ReaderColorSlot.currentWord:
        return c.currentWord;
      case ReaderColorSlot.centralLetter:
        return c.centralLetter;
      case ReaderColorSlot.guideLine:
        return c.guideLine;
      case ReaderColorSlot.helperHighlight:
        return c.helperHighlight;
      case ReaderColorSlot.background:
        return c.background;
      case ReaderColorSlot.focusBackground:
        return c.focusBackground;
      case ReaderColorSlot.progressBar:
        return c.progressBar;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors =
        ReaderColors.resolve(settings, Theme.of(context).colorScheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Settings'),
        actions: [
          TextButton(
            onPressed: notifier.resetColors,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (slot, label) = _rows[i];
          final current = _resolved(slot, colors);
          return ListTile(
            title: Text(label),
            trailing: _Swatch(color: current),
            onTap: () => _pick(context, label, current,
                (c) => notifier.setColor(slot, c)),
          );
        },
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    String label,
    Color initial,
    ValueChanged<Color> onPicked,
  ) async {
    var selected = initial;
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initial,
            enableAlpha: false,
            labelTypes: const [],
            onColorChanged: (c) => selected = c,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: const Text('Select')),
        ],
      ),
    );
    if (result != null) onPicked(result);
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
