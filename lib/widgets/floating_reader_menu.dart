import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../providers/settings_provider.dart';
import '../services/reader_engine.dart';
import '../theme/reader_colors.dart';

class FloatingReaderMenu extends ConsumerStatefulWidget {
  final ReaderEngine engine;
  final bool visible;
  final VoidCallback onUserInteraction;

  const FloatingReaderMenu({
    super.key,
    required this.engine,
    required this.visible,
    required this.onUserInteraction,
  });

  @override
  ConsumerState<FloatingReaderMenu> createState() => _FloatingReaderMenuState();
}

class _FloatingReaderMenuState extends ConsumerState<FloatingReaderMenu> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant FloatingReaderMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible && oldWidget.visible) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final colors = ReaderColors.resolve(settings, scheme);

    final containerBg = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExpanded) ...[
                // Title
                Text(
                  'Text & Speed Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.currentWord,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF333333)
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                // WPM Speed
                _buildAdjustmentRow(
                  label: 'Speed',
                  valueText: '${settings.wordsPerMinute} WPM',
                  colors: colors,
                  theme: theme,
                  onDecrement: () {
                    widget.onUserInteraction();
                    final currentWpm = settings.wordsPerMinute;
                    if (currentWpm > ReaderSettings.minWpm) {
                      final targetWpm = (((currentWpm - 1) ~/ 5) * 5).clamp(ReaderSettings.minWpm, ReaderSettings.maxWpm);
                      ref.read(settingsProvider.notifier).setWordsPerMinute(targetWpm);
                    }
                  },
                  onIncrement: () {
                    widget.onUserInteraction();
                    final currentWpm = settings.wordsPerMinute;
                    if (currentWpm < ReaderSettings.maxWpm) {
                      final targetWpm = (((currentWpm + 5) ~/ 5) * 5).clamp(ReaderSettings.minWpm, ReaderSettings.maxWpm);
                      ref.read(settingsProvider.notifier).setWordsPerMinute(targetWpm);
                    }
                  },
                ),
                // Focus Text Font Size
                _buildAdjustmentRow(
                  label: 'Focus Size',
                  valueText: '${settings.fontSize.round()} pt',
                  colors: colors,
                  theme: theme,
                  onDecrement: () {
                    widget.onUserInteraction();
                    final currentSize = settings.fontSize;
                    if (currentSize > ReaderSettings.minFontSize) {
                      ref.read(settingsProvider.notifier).setFontSize(currentSize - 1);
                    }
                  },
                  onIncrement: () {
                    widget.onUserInteraction();
                    final currentSize = settings.fontSize;
                    if (currentSize < ReaderSettings.maxFontSize) {
                      ref.read(settingsProvider.notifier).setFontSize(currentSize + 1);
                    }
                  },
                ),
                // Helper Text Font Size
                _buildAdjustmentRow(
                  label: 'Helper Size',
                  valueText: '${settings.helperFontSize.round()} pt',
                  colors: colors,
                  theme: theme,
                  onDecrement: () {
                    widget.onUserInteraction();
                    final currentSize = settings.helperFontSize;
                    if (currentSize > ReaderSettings.minHelperFontSize) {
                      ref.read(settingsProvider.notifier).setHelperFontSize(currentSize - 1);
                    }
                  },
                  onIncrement: () {
                    widget.onUserInteraction();
                    final currentSize = settings.helperFontSize;
                    if (currentSize < ReaderSettings.maxHelperFontSize) {
                      ref.read(settingsProvider.notifier).setHelperFontSize(currentSize + 1);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF333333)
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
              ],
              _buildBottomRow(context, ref, colors, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustmentRow({
    required String label,
    required String valueText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ReaderColors colors,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.currentWord,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_rounded, color: colors.currentWord, size: 20),
              onPressed: onDecrement,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 75,
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.currentWord,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_rounded, color: colors.currentWord, size: 20),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomRow(
    BuildContext context,
    WidgetRef ref,
    ReaderColors colors,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final engine = widget.engine;
    final settings = ref.watch(settingsProvider);

    final buttonBg = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFE5E5E5);

    if (_isExpanded) {
      // Expanded State bottom row: [Play Button] [Spacer] [Chevron Down]
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder(
            valueListenable: engine.state,
            builder: (context, state, _) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: buttonBg,
                ),
                child: IconButton(
                  iconSize: 22,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: colors.currentWord,
                  ),
                  onPressed: () {
                    widget.onUserInteraction();
                    engine.toggle();
                  },
                ),
              );
            },
          ),
          IconButton(
            tooltip: settings.showHelperText ? 'Fullscreen' : 'Exit fullscreen',
            icon: Icon(
              settings.showHelperText ? Icons.fullscreen_rounded : Icons.fullscreen_exit_rounded,
              color: colors.currentWord,
            ),
            onPressed: () {
              widget.onUserInteraction();
              ref.read(settingsProvider.notifier).setShowHelperText(!settings.showHelperText);
            },
          ),
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.currentWord),
            onPressed: () {
              widget.onUserInteraction();
              setState(() {
                _isExpanded = false;
              });
            },
          ),
        ],
      );
    } else {
      // Collapsed State bottom row: [⏮️] [⏪] [▶️/⏸️] [⏩] [⏭️] [^]
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Previous sentence',
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: () {
              widget.onUserInteraction();
              engine.prevSentence();
            },
          ),
          IconButton(
            tooltip: 'Back 5 seconds',
            icon: Icon(
              Icons.fast_rewind_rounded,
              size: 26,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: () {
              widget.onUserInteraction();
              engine.back5s();
            },
          ),
          ValueListenableBuilder(
            valueListenable: engine.state,
            builder: (context, state, _) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: buttonBg,
                ),
                child: IconButton(
                  iconSize: 22,
                  icon: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: colors.currentWord,
                  ),
                  onPressed: () {
                    widget.onUserInteraction();
                    engine.toggle();
                  },
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Forward 5 seconds',
            icon: Icon(
              Icons.fast_forward_rounded,
              size: 26,
              color: scheme.onSurfaceVariant,
            ),
            onPressed: () {
              widget.onUserInteraction();
              engine.forward5s();
            },
          ),
          IconButton(
            tooltip: 'Next sentence',
            icon: Icon(
              Icons.skip_next_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: () {
              widget.onUserInteraction();
              engine.nextSentence();
            },
          ),
          IconButton(
            tooltip: settings.showHelperText ? 'Fullscreen' : 'Exit fullscreen',
            icon: Icon(
              settings.showHelperText ? Icons.fullscreen_rounded : Icons.fullscreen_exit_rounded,
              color: colors.currentWord,
            ),
            onPressed: () {
              widget.onUserInteraction();
              ref.read(settingsProvider.notifier).setShowHelperText(!settings.showHelperText);
            },
          ),
          IconButton(
            tooltip: 'Expand controls',
            icon: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: colors.currentWord,
            ),
            onPressed: () {
              widget.onUserInteraction();
              setState(() {
                _isExpanded = true;
              });
            },
          ),
        ],
      );
    }
  }
}
