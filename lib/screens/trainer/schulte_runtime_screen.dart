import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';

/// Fully interactive Schulte Table runtime screen with pause/resume and completion stats.
class SchulteRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;
  final bool showIntro;

  const SchulteRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<SchulteRuntimeScreen> createState() => SchulteRuntimeScreenState();
}

class SchulteRuntimeScreenState extends State<SchulteRuntimeScreen> {
  static const int _gridSize = 5;
  static const int _maxNumber = _gridSize * _gridSize;

  late List<int> _numbers;
  int _nextNumber = 1;
  int _errorCount = 0;
  bool _isPaused = false;
  bool _isFinished = false;
  late bool _showIntro;

  // Timer fields
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Flash state for mistake cells
  int? _flashingErrorCell;

  @override
  void initState() {
    super.initState();
    _showIntro = widget.showIntro;
    if (_showIntro) {
      _numbers = List.generate(_maxNumber, (index) => index + 1)..shuffle();
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
    _nextNumber = 1;
    _errorCount = 0;
    _elapsedSeconds = 0;
    _isPaused = false;
    _isFinished = false;
    _flashingErrorCell = null;

    // Generate shuffled numbers 1 to 25
    _numbers = List.generate(_maxNumber, (index) => index + 1)..shuffle();

    _startTimer();
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

  void _handleCellTap(int number) {
    if (_isPaused || _isFinished) return;

    if (number == _nextNumber) {
      // Correct tap
      HapticFeedback.lightImpact();
      setState(() {
        _nextNumber++;
        if (_nextNumber > _maxNumber) {
          _finishGame();
        }
      });
    } else if (number > _nextNumber) {
      // Incorrect tap
      HapticFeedback.vibrate();
      setState(() {
        _errorCount++;
        _flashingErrorCell = number;
      });
      // Clear error flash after 300ms
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          if (_flashingErrorCell == number) {
            _flashingErrorCell = null;
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

  void _startFromIntro() {
    setState(() {
      _showIntro = false;
      _startNewGame();
    });
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        surfaceTintColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Exercise Intro',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
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
                  const Text(
                    'HOW TO PLAY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _instructionsCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'BENEFITS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: T.textSecondary,
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
            color: T.accentViolet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.grid_view, size: 30, color: T.accentViolet),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schulte Table',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Widen peripheral vision and speed up visual search',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: T.textSecondary,
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
        color: T.successBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
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
                  'Finish 5×5 under 40s · ≤2 errors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
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
      decoration: T.card(radius: 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InstructionRow(
            number: '1',
            text: 'Focus on the center: Keep your eyes fixed on the center of the grid.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Use peripheral vision: Find the numbers from 1 to 25 without moving your gaze away from the center.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Tap in sequence: Tap each number in ascending order as fast as possible.',
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(radius: 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Widen Visual Span: Expands your peripheral vision, allowing you to capture more words or numbers in a single glance without moving your eyes.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Speed up Visual Search: Accelerates the speed at which your brain processes visual information and recognizes patterns.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Develop Stable Attention: Strengthens focus, mental stamina, and concentration duration.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _introActions() {
    return Container(
      decoration: const BoxDecoration(
        color: T.surfaceLowest,
        border: Border(top: BorderSide(color: T.border, width: 0.8)),
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
                    side: const BorderSide(color: T.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: T.textSecondary,
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
                  child: const Text(
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
    if (_showIntro) {
      return _buildIntroScreen();
    }
    return Scaffold(
      backgroundColor: T.surfaceLow,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(),
                _targetRow(),
                Expanded(child: _gridArea()),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(
            icon: Icons.close_rounded,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Schulte Table · 5×5',
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
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

  Widget _targetRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tap in order · Next',
            style: TextStyle(fontSize: 13, color: T.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isFinished ? T.success : T.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _nextNumber > _maxNumber ? '✓' : '$_nextNumber',
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

  Widget _gridArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_gridSize, (r) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: r == _gridSize - 1 ? 0 : 8.0),
                  child: Row(
                    children: List.generate(_gridSize, (c) {
                      final index = r * _gridSize + c;
                      final val = _numbers[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: c == _gridSize - 1 ? 0 : 8.0),
                          child: GestureDetector(
                            onTap: () => _handleCellTap(val),
                            child: _cell(val),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _cell(int number) {
    final bool isDone = number < _nextNumber;
    final bool isError = _flashingErrorCell == number;

    Color fill;
    Color numberColor;
    Border? border;

    if (isError) {
      fill = T.error.withValues(alpha: 0.15);
      numberColor = T.error;
      border = Border.all(color: T.error, width: 1.6);
    } else if (isDone) {
      fill = T.surfaceLow.withValues(alpha: 0.5);
      numberColor = T.textSecondary.withValues(alpha: 0.25);
    } else {
      fill = T.surfaceLowest;
      numberColor = T.textPrimary;
      border = Border.all(color: T.border, width: 0.8);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: numberColor,
        ),
      ),
    );
  }

  Widget _bottomBlock() {
    final int progress = _nextNumber - 1;
    final double fraction = progress / _maxNumber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '$progress / $_maxNumber',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: T.borderStrong.withValues(alpha: 0.5),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(color: T.primary),
              ),
            ),
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

  // ---------------------------------------------------------------------------
  // Overlay Screens (Pause & Completion stats)
  // ---------------------------------------------------------------------------
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
                decoration: const BoxDecoration(
                  color: T.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 32,
                  color: T.primary,
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
                'Grid is hidden to maintain focus.',
                style: TextStyle(fontSize: 14, color: T.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _togglePause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: T.primary,
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
    final int accuracy = (_maxNumber / (_maxNumber + _errorCount) * 100).round();

    return Positioned.fill(
      child: Container(
        color: T.surfaceLow.withValues(alpha: 0.98),
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
                  'You successfully completed the Schulte Table.',
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
                      _statRow('Accuracy', '$accuracy%'),
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
                            // Run callback for training session logging
                            // Score is accuracy, errors is errors, duration is elapsedSeconds
                            widget.onComplete!(accuracy, _errorCount, _elapsedSeconds);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: T.primary,
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

class _InstructionRow extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: T.surfaceLow,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: T.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: T.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

