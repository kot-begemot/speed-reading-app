import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_reading_app/models/tokenized_text.dart';
import 'package:speed_reading_app/services/reader_engine.dart';

TokenizedText synthetic(
  int n, {
  List<int>? sentenceStarts,
  List<int>? paragraphStarts,
}) {
  return TokenizedText(
    words: List.generate(n, (i) => 'w$i'),
    sentenceStarts: sentenceStarts ?? const [0],
    paragraphStarts: paragraphStarts ?? const [0],
    paragraphs: [ParagraphSpan(0, n)],
  );
}

ReaderEngine engine(
  FakeAsync async,
  TokenizedText text, {
  int wpm = 300,
  int wordsPerEntry = 1,
}) {
  return ReaderEngine(
    bookId: 'b',
    text: text,
    wordsPerMinute: wpm,
    wordsPerEntry: wordsPerEntry,
    nowMs: () => async.elapsed.inMilliseconds,
  );
}

void main() {
  test('advances one word per 200ms at 300 WPM', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(100));
      e.play();
      async.elapse(const Duration(seconds: 1));
      expect(e.currentWordIndex, 5);
      e.dispose();
    });
  });

  test('no cumulative drift over 10 minutes at 600 WPM', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(10000), wpm: 600);
      e.play();
      async.elapse(const Duration(minutes: 10)); // 100ms each → exactly 6000
      expect(e.currentWordIndex, 6000);
      e.dispose();
    });
  });

  test('changing WPM mid-run takes effect on the next cadence', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(1000));
      e.play();
      async.elapse(const Duration(seconds: 1)); // 5 words @300
      expect(e.currentWordIndex, 5);
      e.updateSettings(wordsPerMinute: 600); // 100ms each now
      async.elapse(const Duration(seconds: 1)); // +10 words
      expect(e.currentWordIndex, 15);
      e.dispose();
    });
  });

  test('pause halts advancement', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(100));
      e.play();
      async.elapse(const Duration(seconds: 1));
      e.pause();
      async.elapse(const Duration(seconds: 5));
      expect(e.currentWordIndex, 5);
      expect(e.isPlaying, false);
      e.dispose();
    });
  });

  test('stops and pauses at the end of the book', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(10));
      e.play();
      async.elapse(const Duration(seconds: 5));
      expect(e.isPlaying, false);
      expect(e.currentWordIndex, 9); // last group start (k=1)
      e.dispose();
    });
  });

  test('back/forward 5s moves by WPM and snaps to the group boundary', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(100), wpm: 300, wordsPerEntry: 3);
      // 5s @300 WPM = 25 words; from 0, forward → 25 snapped to 24.
      e.forward5s();
      expect(e.currentWordIndex, 24);
      // back 25 from 24 = -1 → clamped/snapped to 0.
      e.back5s();
      expect(e.currentWordIndex, 0);
      e.dispose();
    });
  });

  test('sentence jumps move between sentence starts', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(20, sentenceStarts: const [0, 5, 12]));
      e.nextSentence();
      expect(e.currentWordIndex, 5);
      e.nextSentence();
      expect(e.currentWordIndex, 12);
      e.nextSentence(); // none beyond → stays
      expect(e.currentWordIndex, 12);
      e.prevSentence();
      expect(e.currentWordIndex, 5);
      e.dispose();
    });
  });

  test('seek and jump snap to a group boundary', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(100), wordsPerEntry: 4);
      e.seekToFraction(0.5); // word 50 → snapped to 48
      expect(e.currentWordIndex, 48);
      e.jumpToWord(7); // → snapped to 4
      expect(e.currentWordIndex, 4);
      e.dispose();
    });
  });

  test('tracks elapsed playing time', () {
    fakeAsync((async) {
      final e = engine(async, synthetic(100));
      e.play();
      async.elapse(const Duration(seconds: 1));
      expect(e.currentState.elapsedTime, const Duration(seconds: 1));
      expect(e.currentState.estimatedTimeLeft,
          TimeEstimatorReference.left(5, 100, 300));
      e.dispose();
    });
  });
}

/// Tiny local reference so the elapsed-time test asserts the same formula the
/// engine uses, without re-importing the util namespace verbosely.
class TimeEstimatorReference {
  static Duration left(int idx, int total, int wpm) =>
      Duration(milliseconds: ((total - idx) / wpm * 60 * 1000).round());
}
