/// Runtime snapshot of an active reading session (spec §7).
///
/// Not persisted as a unit — on exit only the durable bits (`currentWordIndex`,
/// progress, time, last-opened) are written back to [BookMeta]. The reader
/// engine (Stage 4) emits immutable instances of this on every tick.
class ReaderState {
  final String bookId;
  final int currentWordIndex;
  final bool isPlaying;
  final int wordsPerMinute;
  final int wordsPerEntry;
  final Duration elapsedTime;
  final Duration estimatedTimeLeft;

  const ReaderState({
    required this.bookId,
    required this.currentWordIndex,
    required this.isPlaying,
    required this.wordsPerMinute,
    required this.wordsPerEntry,
    required this.elapsedTime,
    required this.estimatedTimeLeft,
  });

  ReaderState copyWith({
    int? currentWordIndex,
    bool? isPlaying,
    int? wordsPerMinute,
    int? wordsPerEntry,
    Duration? elapsedTime,
    Duration? estimatedTimeLeft,
  }) {
    return ReaderState(
      bookId: bookId,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      wordsPerEntry: wordsPerEntry ?? this.wordsPerEntry,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      estimatedTimeLeft: estimatedTimeLeft ?? this.estimatedTimeLeft,
    );
  }
}
