import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';

enum _TokenState { distractor, done }

class _Token {
  final int cellIndex;
  final int label;
  _TokenState state;

  _Token({
    required this.cellIndex,
    required this.label,
    required this.state,
  });
}

/// Fully interactive Number Tracking drill. Randomly distributes targets (1-9)
/// and distractors across a responsive cell grid to prevent overlaps.
class NumberTrackingRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;

  const NumberTrackingRuntimeScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<NumberTrackingRuntimeScreen> createState() => NumberTrackingRuntimeScreenState();
}

class NumberTrackingRuntimeScreenState extends State<NumberTrackingRuntimeScreen> {
  static const int _gridCols = 4;
  static const int _gridRows = 5;
  static const int _maxTarget = 9;

  late List<_Token> _tokens;
  int _nextTarget = 1;
  int _errorCount = 0;
  int _correctTaps = 0;
  bool _isPaused = false;
  bool _isFinished = false;

  // Timer fields
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Track error visual flash
  int? _flashingErrorLabel;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    _nextTarget = 1;
    _errorCount = 0;
    _correctTaps = 0;
    _elapsedSeconds = 0;
    _isPaused = false;
    _isFinished = false;
    _flashingErrorLabel = null;

    _generateTokens();
    _startTimer();
  }

  void _generateTokens() {
    final totalCells = _gridCols * _gridRows; // 20 cells
    final List<int> cellIndices = List.generate(totalCells, (i) => i)..shuffle();

    _tokens = [];
    final rand = Random();

    // 1. Generate target tokens 1 to 9
    for (int i = 1; i <= _maxTarget; i++) {
      final cellIdx = cellIndices[i - 1];
      _tokens.add(_Token(
        cellIndex: cellIdx,
        label: i,
        state: _TokenState.distractor,
      ));
    }

    // 2. Fill remaining cells with distractor numbers (10 to 40)
    for (int i = _maxTarget; i < totalCells; i++) {
      final cellIdx = cellIndices[i];
      final label = 10 + rand.nextInt(31); // 10 to 40
      _tokens.add(_Token(
        cellIndex: cellIdx,
        label: label,
        state: _TokenState.distractor,
      ));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _togglePause() {
    if (_isFinished) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
      } else {
        _startTimer();
      }
    });
  }

  void _handleTokenTap(_Token token) {
    if (_isPaused || _isFinished) return;

    if (token.label == _nextTarget) {
      // Correct tap!
      HapticFeedback.lightImpact();
      setState(() {
        _correctTaps++;
        token.state = _TokenState.done;
        _nextTarget++;

        if (_nextTarget > _maxTarget) {
          _finishGame();
        }
      });
    } else {
      // Incorrect tap
      HapticFeedback.vibrate();
      setState(() {
        _errorCount++;
        _flashingErrorLabel = token.label;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          if (_flashingErrorLabel == token.label) {
            _flashingErrorLabel = null;
          }
        });
      });
    }
  }

  void _finishGame() {
    _timer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _calculateAccuracy() {
    final totalTaps = _correctTaps + _errorCount;
    if (totalTaps == 0) return 100;
    return (_correctTaps / totalTaps * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(),
                _subRow(),
                Expanded(child: _field()),
                _bottomBlock(),
              ],
            ),
            if (_isPaused) _buildPausedOverlay(),
            if (_isFinished) _buildFinishedOverlay(),
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
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: T.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: T.border, width: 0.8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: T.textSecondary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Number Tracking · Find next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          _circleButton(
            icon: Icons.refresh_rounded,
            onTap: _startNewGame,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: T.surfaceLowest,
          shape: BoxShape.circle,
          border: Border.all(color: T.border, width: 0.8),
        ),
        child: Icon(icon, size: 20, color: T.textSecondary),
      ),
    );
  }

  Widget _subRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tap 1→9 in order · Next',
            style: TextStyle(fontSize: 13, color: T.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: T.accentTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _nextTarget > _maxTarget ? '✓' : '$_nextTarget',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final cellWidth = w / _gridCols;
          final cellHeight = h / _gridRows;
          const double tokenDiameter = 48;

          return Stack(
            key: const Key('play_field_stack'),
            children: _tokens.map((t) {
              final col = t.cellIndex % _gridCols;
              final row = t.cellIndex ~/ _gridCols;

              // Center token inside its grid cell
              final left = col * cellWidth + (cellWidth - tokenDiameter) / 2;
              final top = row * cellHeight + (cellHeight - tokenDiameter) / 2;

              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () => _handleTokenTap(t),
                  child: _tokenWidget(t),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _tokenWidget(_Token t) {
    final isError = _flashingErrorLabel == t.label;

    Color fill;
    Color numberColor;
    Border? border;

    if (isError) {
      fill = T.error.withValues(alpha: 0.15);
      numberColor = T.error;
      border = Border.all(color: T.error, width: 1.6);
    } else {
      switch (t.state) {
        case _TokenState.done:
          fill = T.surfaceLow.withValues(alpha: 0.4);
          numberColor = T.textSecondary.withValues(alpha: 0.25);
          break;
        case _TokenState.distractor:
          fill = T.surfaceLowest;
          numberColor = T.textPrimary;
          border = Border.all(color: T.border, width: 0.8);
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Text(
        '${t.label}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: numberColor,
        ),
      ),
    );
  }

  Widget _bottomBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniMetric(
                label: 'FOUND',
                value: '${_nextTarget - 1} / $_maxTarget',
                valueColor: T.textPrimary,
              ),
              _MiniMetric(
                label: 'ACCURACY',
                value: '${_calculateAccuracy()}%',
                valueColor: _calculateAccuracy() >= 80 ? T.success : T.error,
              ),
              _MiniMetric(
                label: 'ERRORS',
                value: '$_errorCount',
                valueColor: _errorCount == 0 ? T.textPrimary : T.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _togglePause,
            icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
            label: Text(_isPaused ? 'Resume' : 'Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.surfaceLowest,
              foregroundColor: T.textPrimary,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: T.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Positioned.fill(
      child: Container(
        color: T.surfaceLow.withValues(alpha: 0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: T.accentTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 32,
                  color: T.accentTeal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Training Paused',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Numbers are hidden to maintain focus.',
                style: TextStyle(fontSize: 14, color: T.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _togglePause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: T.accentTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Resume Training',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay() {
    final acc = _calculateAccuracy();

    return Positioned.fill(
      child: Container(
        color: T.surface.withValues(alpha: 0.98),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: T.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 36,
                    color: T.success,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Exercise Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: T.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You finished Number Tracking successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: T.textSecondary),
                ),
                const SizedBox(height: 24),
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: T.card(radius: 16),
                  child: Column(
                    children: [
                      _statRow('Time elapsed', _formatTime(_elapsedSeconds)),
                      const Divider(height: 20, thickness: 0.8, color: T.border),
                      _statRow('Accuracy', '$acc%'),
                      const Divider(height: 20, thickness: 0.8, color: T.border),
                      _statRow('Errors committed', '$_errorCount'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (widget.onComplete == null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _startNewGame,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: T.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: T.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.onComplete != null) {
                            widget.onComplete!(acc, _errorCount, _elapsedSeconds);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: T.accentTeal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.onComplete != null ? 'Continue' : 'Exit to Trainer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: T.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: T.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: T.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
