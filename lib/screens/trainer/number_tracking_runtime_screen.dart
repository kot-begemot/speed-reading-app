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
  final bool showIntro;

  const NumberTrackingRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<NumberTrackingRuntimeScreen> createState() => NumberTrackingRuntimeScreenState();
}

class NumberTrackingRuntimeScreenState extends State<NumberTrackingRuntimeScreen> {
  TTheme get t => T.of(context);
  static const int _gridCols = 4;
  static const int _gridRows = 5;
  static const int _maxTarget = 9;

  late List<_Token> _tokens;
  int _nextTarget = 1;
  int _errorCount = 0;
  int _correctTaps = 0;
  bool _isPaused = false;
  bool _isFinished = false;
  late bool _showIntro;

  // Timer fields
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Track error visual flash
  int? _flashingErrorLabel;

  @override
  void initState() {
    super.initState();
    _showIntro = widget.showIntro;
    if (_showIntro) {
      _tokens = [];
    } else {
      _startNewGame();
    }
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

  void _startFromIntro() {
    setState(() {
      _showIntro = false;
      _startNewGame();
    });
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: t.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Exercise Intro',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _introHead(),
                  const SizedBox(height: 24),
                  _introGoalCard(),
                  const SizedBox(height: 24),
                  Text(
                    'HOW TO PLAY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _instructionsCard(),
                  const SizedBox(height: 24),
                  Text(
                    'BENEFITS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _benefitsCard(),
                ],
              ),
            ),
          ),
          _introActions(),
        ],
      ),
    );
  }

  Widget _introHead() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: T.accentTeal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.location_on, size: 30, color: T.accentTeal),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number Tracking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Attention & sequence tracking',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _introGoalCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.successBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.center_focus_strong, size: 22, color: T.success),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUCCESS GOAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: T.success,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Find 1 to 9 under 25s · ≤1 error',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InstructionRow(
            number: '1',
            text: 'Focus on the grid: Find target numbers from 1 to 9 distributed on the screen.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Ignore distractors: Avoid tapping numbers between 10 and 40.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Tap in sequence: Tap target numbers in ascending order as fast as possible.',
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Enhance Focus and Selectivity: Trains the brain to filter out irrelevant information (distractors) and focus on key items.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Improve Scanning Speed: Enhances visual scanning rates and processing efficiency across the visual field.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Develop Sequence Tracking: Increases the speed of sequencing elements under cognitive load.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _introActions() {
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceLowest,
        border: Border(top: BorderSide(color: t.border, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: t.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startFromIntro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    if (_showIntro) {
      return _buildIntroScreen();
    }
    return Scaffold(
      backgroundColor: t.surface,
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
                color: t.surfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: t.border, width: 0.8),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: t.textSecondary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Number Tracking · Find next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              Text(
                _formatTime(_elapsedSeconds),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
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
          color: t.surfaceLowest,
          shape: BoxShape.circle,
          border: Border.all(color: t.border, width: 0.8),
        ),
        child: Icon(icon, size: 20, color: t.textSecondary),
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
          Text(
            'Tap 1→9 in order · Next',
            style: TextStyle(fontSize: 13, color: t.textSecondary),
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
              style: TextStyle(
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

  Widget _tokenWidget(_Token token) {
    final isError = _flashingErrorLabel == token.label;

    Color fill;
    Color numberColor;
    Border? border;

    if (isError) {
      fill = T.error.withValues(alpha: 0.15);
      numberColor = T.error;
      border = Border.all(color: T.error, width: 1.6);
    } else {
      switch (token.state) {
        case _TokenState.done:
          fill = t.surfaceLow.withValues(alpha: 0.4);
          numberColor = t.textSecondary.withValues(alpha: 0.25);
          break;
        case _TokenState.distractor:
          fill = t.surfaceLowest;
          numberColor = t.textPrimary;
          border = Border.all(color: t.border, width: 0.8);
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
        '${token.label}',
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
                valueColor: t.textPrimary,
              ),
              _MiniMetric(
                label: 'ACCURACY',
                value: '${_calculateAccuracy()}%',
                valueColor: _calculateAccuracy() >= 80 ? T.success : T.error,
              ),
              _MiniMetric(
                label: 'ERRORS',
                value: '$_errorCount',
                valueColor: _errorCount == 0 ? t.textPrimary : T.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _togglePause,
            icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20),
            label: Text(_isPaused ? 'Resume' : 'Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.surfaceLowest,
              foregroundColor: t.textPrimary,
              elevation: 0,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: t.border),
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
        color: t.surfaceLow.withValues(alpha: 0.96),
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
              Text(
                'Training Paused',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Numbers are hidden to maintain focus.',
                style: TextStyle(fontSize: 14, color: t.textSecondary),
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
                child: Text(
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
        color: t.surface.withValues(alpha: 0.98),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: t.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 36,
                    color: T.success,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Exercise Complete!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You finished Number Tracking successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
                const SizedBox(height: 24),
                // Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: t.card(radius: 16),
                  child: Column(
                    children: [
                      _statRow('Time elapsed', _formatTime(_elapsedSeconds)),
                      Divider(height: 20, thickness: 0.8, color: t.border),
                      _statRow('Accuracy', '$acc%'),
                      Divider(height: 20, thickness: 0.8, color: t.border),
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
                            side: BorderSide(color: t.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
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
                          style: TextStyle(
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
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
    final t = T.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: t.textSecondary,
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

class _InstructionRow extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surfaceLow,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: t.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

