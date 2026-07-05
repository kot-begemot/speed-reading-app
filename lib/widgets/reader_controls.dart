import 'package:flutter/material.dart';

import '../services/reader_engine.dart';

/// Playback controls (spec §4): restart, prev/next sentence, back/forward 5s,
/// and a large play/pause. Rebuilds its play/pause icon from the engine state.
class ReaderControls extends StatelessWidget {
  final ReaderEngine engine;
  const ReaderControls({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget buildControlItem({
      required IconData icon,
      required String label,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: scheme.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Restart button with confirmation dialog
          buildControlItem(
            icon: Icons.replay_rounded,
            label: 'Restart',
            tooltip: 'Restart book',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF2C2C2C) : scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  title: Text(
                    'Restart Book',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to return to the very beginning of the book? Your current progress will be reset.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Restart',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                engine.restart();
              }
            },
          ),
          buildControlItem(
            icon: Icons.skip_previous_rounded,
            label: 'Prev Sent',
            tooltip: 'Previous sentence',
            onPressed: engine.prevSentence,
          ),
          buildControlItem(
            icon: Icons.replay_5_rounded,
            label: '-5s',
            tooltip: 'Back 5 seconds',
            onPressed: engine.back5s,
          ),
          // Large play/pause outline circle button
          ValueListenableBuilder(
            valueListenable: engine.state,
            builder: (context, state, _) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? scheme.primary.withValues(alpha: 0.15)
                      : scheme.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: IconButton(
                  iconSize: 24,
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: scheme.primary,
                  ),
                  onPressed: engine.toggle,
                ),
              );
            },
          ),
          buildControlItem(
            icon: Icons.forward_5_rounded,
            label: '+5s',
            tooltip: 'Forward 5 seconds',
            onPressed: engine.forward5s,
          ),
          buildControlItem(
            icon: Icons.skip_next_rounded,
            label: 'Next Sent',
            tooltip: 'Next sentence',
            onPressed: engine.nextSentence,
          ),
        ],
      ),
    );
  }
}
