import 'package:flutter/material.dart';

import '../theme/reader_colors.dart';
import '../utils/time_estimator.dart';

/// Bottom-of-focus progress + times (spec §3A): time left (left), time passed
/// (right), and a draggable progress slider that seeks the book (spec §4).
class ReaderProgressBar extends StatelessWidget {
  final int currentWordIndex;
  final int totalWords;
  final int wordsPerMinute;
  final Duration elapsed;
  final ReaderColors colors;
  final ValueChanged<double> onSeek;

  const ReaderProgressBar({
    super.key,
    required this.currentWordIndex,
    required this.totalWords,
    required this.wordsPerMinute,
    required this.elapsed,
    required this.colors,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = TimeEstimator.progress(currentWordIndex, totalWords);
    final left = TimeEstimator.estimatedTimeLeft(
        currentWordIndex, totalWords, wordsPerMinute);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time left: ${_fmt(left)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.currentWord.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                'Time passed: ${_fmt(elapsed)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.currentWord.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              activeTrackColor: colors.progressBar,
              inactiveTrackColor: colors.progressBar.withValues(alpha: 0.15),
              thumbColor: colors.progressBar,
              overlayColor: colors.progressBar.withValues(alpha: 0.12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: onSeek,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final totalSeconds = d.inSeconds;
    final h = d.inHours;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}
