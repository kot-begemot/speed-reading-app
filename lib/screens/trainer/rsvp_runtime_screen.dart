import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';
import '../../widgets/focus_word_view.dart';
import '../../theme/reader_colors.dart';

/// Fully interactive RSVP Reading runtime screen with play/pause, metronome, progress,
/// word rewinding, and completion callback.
class RsvpRuntimeScreen extends StatefulWidget {
  final String textTitle;
  final String textContent;
  final int targetWpm;
  final void Function(int rawWpm, int wordsRead)? onComplete;

  const RsvpRuntimeScreen({
    super.key,
    required this.textTitle,
    required this.textContent,
    required this.targetWpm,
    this.onComplete,
  });

  @override
  State<RsvpRuntimeScreen> createState() => _RsvpRuntimeScreenState();
}

class _RsvpRuntimeScreenState extends State<RsvpRuntimeScreen> {
  late List<String> _words;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;

  // Visual metronome state
  int _metronomeTick = 2;

  // Reader colors
  final ReaderColors _colors = const ReaderColors(
    currentWord: T.textPrimary,
    centralLetter: T.centralLetter,
    guideLine: T.guideLine,
    helperHighlight: T.primary,
    background: T.surface,
    focusBackground: T.surfaceLow,
    progressBar: T.primary,
  );

  @override
  void initState() {
    super.initState();
    // Parse text into words, filter out empty ones
    _words = widget.textContent
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (_words.isEmpty) {
      _words = ['No', 'content', 'available'];
    }

    // Auto-start RSVP
    _startPlaying();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPlaying() {
    _timer?.cancel();
    _isPlaying = true;

    final intervalMs = (60 / widget.targetWpm * 1000).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;

      setState(() {
        if (_currentIndex < _words.length - 1) {
          _currentIndex++;
          _metronomeTick = (_metronomeTick + 1) % 5;
        } else {
          _finishReading();
        }
      });
    });
  }

  void _pausePlaying() {
    setState(() {
      _isPlaying = false;
      _timer?.cancel();
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pausePlaying();
    } else {
      _startPlaying();
    }
  }

  void _rewind() {
    setState(() {
      _currentIndex = (_currentIndex - 5).clamp(0, _words.length - 1);
    });
  }

  void _finishReading() {
    _timer?.cancel();
    _isPlaying = false;

    if (widget.onComplete != null) {
      widget.onComplete!(widget.targetWpm, _words.length);
    } else {
      Navigator.pop(context);
    }
  }

  String _formatTimeLeft() {
    final wordsLeft = _words.length - _currentIndex;
    final totalSecondsLeft = (wordsLeft / widget.targetWpm * 60).round();
    final minutes = totalSecondsLeft ~/ 60;
    final seconds = totalSecondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double fraction = _currentIndex / _words.length;
    final currentWordStr = _words[_currentIndex];

    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _targetChip(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FocusWordView(
                      groupWords: [currentWordStr],
                      fontSize: 38,
                      fontFamily: null,
                      colors: _colors,
                    ),
                    const SizedBox(height: 32),
                    _metronome(),
                  ],
                ),
              ),
            ),
            _bottomBlock(fraction),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _circleIcon(
            fill: T.surfaceLow,
            icon: Icons.close_rounded,
            color: T.textSecondary,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.textTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                _formatTimeLeft(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          _circleIcon(
            fill: T.primaryBg,
            icon: Icons.graphic_eq,
            color: T.primary,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _circleIcon({
    required Color fill,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _targetChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: T.primaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.speed, size: 15, color: T.primary),
              const SizedBox(width: 5),
              Text(
                'Target ${widget.targetWpm} WPM',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metronome() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: i == _metronomeTick ? 10 : 7,
            height: i == _metronomeTick ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == _metronomeTick ? T.primary : T.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bottomBlock(double fraction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1} / ${_words.length} words',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '${widget.targetWpm} WPM',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: T.borderStrong.withValues(alpha: 0.5),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(color: T.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _rewind,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: T.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.border, width: 0.8),
                  ),
                  child: const Icon(
                    Icons.replay_5,
                    size: 24,
                    color: T.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: T.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: T.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 22,
                          color: T.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPlaying ? 'Pause' : 'Resume',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: T.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
