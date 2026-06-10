import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/reader_state.dart';
import '../models/tokenized_text.dart';
import '../utils/time_estimator.dart';

/// The speed-reading playback engine (spec §3, §4, §8). Pure logic — no UI.
///
/// Words are partitioned into fixed groups of `wordsPerEntry` starting at 0;
/// [currentWordIndex] is always the (group-aligned) start of the active group,
/// so the helper highlight never straddles a group.
///
/// Ticking is **drift-free**: each tick schedules a one-shot timer against an
/// ideal schedule anchored at play time, so error never accumulates (matters at
/// high WPM where the interval is ~100 ms). Time is read through [_now], which
/// defaults to a monotonic [Stopwatch] but can be injected (tests pass a
/// `fake_async`-driven clock).
class ReaderEngine {
  ReaderEngine({
    required this.bookId,
    required TokenizedText text,
    required int wordsPerMinute,
    required int wordsPerEntry,
    int initialWordIndex = 0,
    int Function()? nowMs,
  })  : _text = text,
        _wpm = wordsPerMinute,
        _wordsPerEntry = wordsPerEntry < 1 ? 1 : wordsPerEntry,
        _clock = nowMs {
    _stopwatch.start();
    _currentWordIndex = _snap(initialWordIndex);
    _state = ValueNotifier<ReaderState>(_build());
  }

  final String bookId;
  final TokenizedText _text;
  final int Function()? _clock;
  final Stopwatch _stopwatch = Stopwatch();

  int _wpm;
  int _wordsPerEntry;
  late int _currentWordIndex;
  bool _isPlaying = false;
  Timer? _timer;

  // Ideal-schedule anchor (drift-free ticking).
  int _anchorMs = 0;
  int _entriesPlayed = 0;

  // Accumulated playing time, for "time passed".
  int _accumulatedMs = 0;
  int _playStartMs = 0;

  late final ValueNotifier<ReaderState> _state;

  // --- public surface ---

  ValueListenable<ReaderState> get state => _state;
  ReaderState get currentState => _state.value;

  int get total => _text.words.length;
  int get currentWordIndex => _currentWordIndex;
  bool get isPlaying => _isPlaying;
  int get wordsPerMinute => _wpm;
  int get wordsPerEntry => _wordsPerEntry;

  /// `[start, end)` word indices of the active group (end exclusive, clamped).
  (int, int) get currentGroupRange =>
      (_currentWordIndex, (_currentWordIndex + _wordsPerEntry).clamp(0, total));

  List<String> get currentGroupWords {
    if (total == 0) return const [];
    final (s, e) = currentGroupRange;
    return _text.words.sublist(s, e);
  }

  // --- playback ---

  void play() {
    if (_isPlaying || total == 0) return;
    if (_atOrPastEnd()) _currentWordIndex = 0; // replay from start
    _isPlaying = true;
    _playStartMs = _now();
    _anchorSchedule();
    _emit();
  }

  void pause() {
    if (!_isPlaying) return;
    _accumulatedMs += _now() - _playStartMs;
    _isPlaying = false;
    _cancelTimer();
    _emit();
  }

  void toggle() => _isPlaying ? pause() : play();

  void restart() {
    _currentWordIndex = 0;
    _restartScheduleIfPlaying();
    _emit();
  }

  // --- navigation (all targets snapped to a group boundary) ---

  void jumpToWord(int wordIndex) {
    _currentWordIndex = _snap(wordIndex);
    _restartScheduleIfPlaying();
    _emit();
  }

  void seekToFraction(double fraction) {
    if (total == 0) return;
    jumpToWord((fraction.clamp(0.0, 1.0) * total).round());
  }

  void stepForward() => jumpToWord(_currentWordIndex + _wordsPerEntry);
  void stepBackward() => jumpToWord(_currentWordIndex - _wordsPerEntry);

  /// Move by `seconds × WPM/60` words (spec §4 back/forward 5s). Negative
  /// seconds move backward.
  void skipSeconds(int seconds) {
    final words = (seconds * _wpm / 60).round();
    jumpToWord(_currentWordIndex + words);
  }

  void back5s() => skipSeconds(-5);
  void forward5s() => skipSeconds(5);

  void nextSentence() => _jumpToBoundary(_text.sentenceStarts, forward: true);
  void prevSentence() => _jumpToBoundary(_text.sentenceStarts, forward: false);
  void nextParagraph() => _jumpToBoundary(_text.paragraphStarts, forward: true);
  void prevParagraph() => _jumpToBoundary(_text.paragraphStarts, forward: false);

  /// Applies live setting changes. Re-aligns the position when `wordsPerEntry`
  /// changes and re-anchors the schedule so cadence updates on the next tick.
  void updateSettings({int? wordsPerMinute, int? wordsPerEntry}) {
    var changed = false;
    if (wordsPerMinute != null && wordsPerMinute > 0 && wordsPerMinute != _wpm) {
      _wpm = wordsPerMinute;
      changed = true;
    }
    if (wordsPerEntry != null &&
        wordsPerEntry >= 1 &&
        wordsPerEntry != _wordsPerEntry) {
      _wordsPerEntry = wordsPerEntry;
      _currentWordIndex = _snap(_currentWordIndex);
      changed = true;
    }
    if (changed) {
      _restartScheduleIfPlaying();
      _emit();
    }
  }

  void dispose() {
    _cancelTimer();
    _stopwatch.stop();
    _state.dispose();
  }

  // --- internals ---

  int _now() => _clock?.call() ?? _stopwatch.elapsedMilliseconds;

  bool _atOrPastEnd() => _currentWordIndex + _wordsPerEntry >= total;

  int get _lastGroupStart =>
      total == 0 ? 0 : ((total - 1) ~/ _wordsPerEntry) * _wordsPerEntry;

  int _snap(int wordIndex) {
    if (total == 0) return 0;
    final clamped = wordIndex.clamp(0, total - 1);
    return (clamped ~/ _wordsPerEntry) * _wordsPerEntry;
  }

  void _jumpToBoundary(List<int> starts, {required bool forward}) {
    if (starts.isEmpty) return;
    final cur = _currentWordIndex;
    int? target;
    if (forward) {
      for (final s in starts) {
        if (s > cur) {
          target = s;
          break;
        }
      }
    } else {
      for (final s in starts) {
        if (s < cur) {
          target = s;
        } else {
          break;
        }
      }
    }
    jumpToWord(target ?? (forward ? cur : 0));
  }

  void _anchorSchedule() {
    _cancelTimer();
    _anchorMs = _now();
    _entriesPlayed = 0;
    _scheduleNext();
  }

  void _restartScheduleIfPlaying() {
    if (_isPlaying) _anchorSchedule();
  }

  void _scheduleNext() {
    final interval = TimeEstimator.millisecondsPerEntry(_wpm, _wordsPerEntry);
    final ideal = _anchorMs + (_entriesPlayed + 1) * interval;
    final delay = ideal - _now();
    _timer = Timer(Duration(milliseconds: delay < 0 ? 0 : delay), _onTick);
  }

  void _onTick() {
    _entriesPlayed++;
    final next = _currentWordIndex + _wordsPerEntry;
    if (next >= total) {
      _currentWordIndex = _lastGroupStart;
      pause(); // emits final state
      return;
    }
    _currentWordIndex = next;
    _emit();
    _scheduleNext();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Duration _elapsed() {
    final extra = _isPlaying ? (_now() - _playStartMs) : 0;
    return Duration(milliseconds: _accumulatedMs + extra);
  }

  ReaderState _build() => ReaderState(
        bookId: bookId,
        currentWordIndex: _currentWordIndex,
        isPlaying: _isPlaying,
        wordsPerMinute: _wpm,
        wordsPerEntry: _wordsPerEntry,
        elapsedTime: _elapsed(),
        estimatedTimeLeft:
            TimeEstimator.estimatedTimeLeft(_currentWordIndex, total, _wpm),
      );

  void _emit() => _state.value = _build();
}
