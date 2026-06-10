/// Progress and time math (spec §8). WPM always means *actual words per
/// minute*, even when `wordsPerEntry > 1`, so estimates use the word count
/// directly, not entries.
class TimeEstimator {
  const TimeEstimator._();

  static double progress(int currentWordIndex, int totalWords) =>
      totalWords <= 0 ? 0 : (currentWordIndex / totalWords).clamp(0.0, 1.0);

  static Duration estimatedTimeLeft(
      int currentWordIndex, int totalWords, int wordsPerMinute) {
    if (wordsPerMinute <= 0 || totalWords <= 0) return Duration.zero;
    final remaining = (totalWords - currentWordIndex).clamp(0, totalWords);
    final seconds = remaining / wordsPerMinute * 60.0;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Display interval per entry (spec §5A): `60000 / wpm * wordsPerEntry` ms.
  static int millisecondsPerEntry(int wordsPerMinute, int wordsPerEntry) =>
      wordsPerMinute <= 0
          ? 0
          : (60000 / wordsPerMinute * wordsPerEntry).round();
}
