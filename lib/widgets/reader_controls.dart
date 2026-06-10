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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Restart',
              icon: const Icon(Icons.replay),
              onPressed: engine.restart,
            ),
            IconButton(
              tooltip: 'Previous sentence',
              icon: const Icon(Icons.skip_previous),
              onPressed: engine.prevSentence,
            ),
            IconButton(
              tooltip: 'Back 5s',
              icon: const Icon(Icons.replay_5),
              onPressed: engine.back5s,
            ),
            ValueListenableBuilder(
              valueListenable: engine.state,
              builder: (context, state, _) {
                return IconButton.filled(
                  iconSize: 36,
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: engine.toggle,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Forward 5s',
              icon: const Icon(Icons.forward_5),
              onPressed: engine.forward5s,
            ),
            IconButton(
              tooltip: 'Next sentence',
              icon: const Icon(Icons.skip_next),
              onPressed: engine.nextSentence,
            ),
          ],
        ),
      ),
    );
  }
}
