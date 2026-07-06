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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final colors = ReaderColors.resolve(settings, scheme);

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
      body: Column(
        children: [
          _LivePreview(colors: colors),
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final (slot, label) = _rows[i];
                final current = _resolved(slot, colors);
                return ListTile(
                  title: Text(label),
                  trailing: _Swatch(color: current),
                  onTap: () => _pick(
                    context,
                    label,
                    current,
                    (c) => notifier.setColor(slot, c, isDark: isDark),
                  ),
                );
              },
            ),
          ),
        ],
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

class _LivePreview extends StatelessWidget {
  final ReaderColors colors;
  const _LivePreview({required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final focusTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: colors.currentWord,
      fontFamily: 'serif',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Focus section preview
          Container(
            color: colors.focusBackground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                // Top guide line
                Container(
                  width: 140,
                  height: 1.5,
                  color: colors.guideLine,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: RichText(
                    text: TextSpan(
                      style: focusTextStyle,
                      children: [
                        const TextSpan(text: 'Re'),
                        TextSpan(
                          text: 'a',
                          style: focusTextStyle.copyWith(color: colors.centralLetter),
                        ),
                        const TextSpan(text: 'der'),
                      ],
                    ),
                  ),
                ),
                // Bottom guide line
                Container(
                  width: 140,
                  height: 1.5,
                  color: colors.guideLine,
                ),
                const SizedBox(height: 16),
                // Progress bar preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      minHeight: 2,
                      backgroundColor: colors.progressBar.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.progressBar),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Helper section preview
          Container(
            color: colors.background,
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Helper text preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.currentWord.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.currentWord.withValues(alpha: 0.8),
                    ),
                    children: [
                      const TextSpan(text: 'This is a live '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.helperHighlight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'preview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' of your reader theme colors.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
    );
  }
}
