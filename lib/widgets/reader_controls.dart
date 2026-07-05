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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Restart',
            icon: Icon(Icons.replay_rounded, color: scheme.onSurfaceVariant),
            onPressed: engine.restart,
          ),
          IconButton(
            tooltip: 'Previous sentence',
            icon: Icon(Icons.skip_previous_rounded, color: scheme.onSurfaceVariant),
            onPressed: engine.prevSentence,
          ),
          IconButton(
            tooltip: 'Back 5s',
            icon: Icon(Icons.replay_5_rounded, color: scheme.onSurfaceVariant),
            onPressed: engine.back5s,
          ),
          ValueListenableBuilder(
            valueListenable: engine.state,
            builder: (context, state, _) {
              final isDark = theme.brightness == Brightness.dark;
              return Container(
                width: 52,
                height: 52,
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
                  iconSize: 26,
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
          IconButton(
            tooltip: 'Forward 5s',
            icon: Icon(Icons.forward_5_rounded, color: scheme.onSurfaceVariant),
            onPressed: engine.forward5s,
          ),
          IconButton(
            tooltip: 'Next sentence',
            icon: Icon(Icons.skip_next_rounded, color: scheme.onSurfaceVariant),
            onPressed: engine.nextSentence,
          ),
        ],
      ),
    );
  }
}
