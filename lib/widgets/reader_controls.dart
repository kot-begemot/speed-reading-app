import 'package:flutter/material.dart';

import '../services/reader_engine.dart';

/// Playback controls (spec §4): prev/next sentence, back/forward 5s,
/// and a large play/pause centered in a size-hierarchical 5-button row.
class ReaderControls extends StatelessWidget {
  final ReaderEngine engine;
  const ReaderControls({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Far Left: Previous Sentence (small, subtle)
          IconButton(
            tooltip: 'Previous sentence',
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: engine.prevSentence,
          ),

          // Center Cluster: Back 5s, Play/Pause, Forward 5s
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Back 5 seconds',
                icon: Icon(
                  Icons.fast_rewind_rounded,
                  size: 26,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: engine.back5s,
              ),
              const SizedBox(width: 16),
              // Large play/pause solid hero circle button
              ValueListenableBuilder(
                valueListenable: engine.state,
                builder: (context, state, _) {
                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 28,
                      tooltip: state.isPlaying ? 'Pause' : 'Play',
                      icon: Icon(
                        state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: scheme.onPrimary,
                      ),
                      onPressed: engine.toggle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Forward 5 seconds',
                icon: Icon(
                  Icons.fast_forward_rounded,
                  size: 26,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: engine.forward5s,
              ),
            ],
          ),

          // Far Right: Next Sentence (small, subtle)
          IconButton(
            tooltip: 'Next sentence',
            icon: Icon(
              Icons.skip_next_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            onPressed: engine.nextSentence,
          ),
        ],
      ),
    );
  }
}
