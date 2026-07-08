import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';

class _FlashRound {
  final String target;
  final List<String> options;

  _FlashRound({
    required this.target,
    required this.options,
  });
}

/// Fully interactive Flash Recognition drill. Shows a visual mask, flashes a phrase
/// for a brief period (e.g. 300ms), and asks the user to identify what they saw.
class FlashRecognitionRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;

  const FlashRecognitionRuntimeScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<FlashRecognitionRuntimeScreen> createState() => FlashRecognitionRuntimeScreenState();
}

class FlashRecognitionRuntimeScreenState extends State<FlashRecognitionRuntimeScreen> {
  static const int _totalRounds = 10;
  static const int _exposureMs = 300;

  static final List<List<String>> _phrasePool = [
    ['distant river', 'silent river', 'distant forest', 'silent forest'],
    ['green grass', 'green glass', 'keen grass', 'keen glass'],
    ['yellow sun', 'yellow son', 'fellow sun', 'fellow son'],
    ['smart boy', 'smart toy', 'small boy', 'small toy'],
    ['gold medal', 'gold metal', 'cold medal', 'cold metal'],
    ['blue sky', 'blue spy', 'blew sky', 'blew spy'],
    ['red apple', 'red maple', 'sad apple', 'sad maple'],
    ['fast car', 'fast cat', 'last car', 'last cat'],
    ['hot tea', 'hot sea', 'not tea', 'not sea'],
    ['deep ocean', 'deep onion', 'dear ocean', 'dear onion'],
  ];

  late List<_FlashRound> _rounds;
  int _currentRoundIndex = 0;
  int _errorCount = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _isFinished = false;

  // Flash phases: 'waiting', 'flashing', 'answering', 'feedback'
  String _flashPhase = 'waiting'; 
  int? _selectedOptionIndex;
  Timer? _phaseTimer;
  Timer? _globalTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _globalTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _phaseTimer?.cancel();
    _globalTimer?.cancel();

    _currentRoundIndex = 0;
    _errorCount = 0;
    _correctCount = 0;
    _streak = 0;
    _maxStreak = 0;
    _elapsedSeconds = 0;
    _isFinished = false;
    _selectedOptionIndex = null;
    _flashPhase = 'waiting';

    _generateRounds();
    _startGlobalTimer();
    _startRoundSequence();
  }

  void _generateRounds() {
    // Copy and shuffle phrase pool
    final pool = [..._phrasePool]..shuffle();

    _rounds = List.generate(_totalRounds, (index) {
      final item = pool[index % pool.length];
      final target = item[0];
      final options = [...item]..shuffle();

      return _FlashRound(
        target: target,
        options: options,
      );
    });
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startRoundSequence() {
    setState(() {
      _flashPhase = 'waiting';
      _selectedOptionIndex = null;
    });

    // 1. Wait 800ms on mask, then flash
    _phaseTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _flashPhase = 'flashing';
      });

      // 2. Flash phrase for 300ms, then mask again and show options
      _phaseTimer = Timer(const Duration(milliseconds: _exposureMs), () {
        if (!mounted) return;
        setState(() {
          _flashPhase = 'answering';
        });
      });
    });
  }

  void _handleOptionSelect(int index) {
    if (_flashPhase != 'answering') return;

    final round = _rounds[_currentRoundIndex];
    final isCorrect = round.options[index] == round.target;

    setState(() {
      _selectedOptionIndex = index;
      _flashPhase = 'feedback';
      if (isCorrect) {
        _correctCount++;
        _streak++;
        _maxStreak = max(_maxStreak, _streak);
        HapticFeedback.lightImpact();
      } else {
        _errorCount++;
        _streak = 0;
        HapticFeedback.vibrate();
      }
    });

    // 3. Wait 1200ms on feedback phase, then advance or complete
    _phaseTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentRoundIndex < _totalRounds - 1) {
        setState(() {
          _currentRoundIndex++;
        });
        _startRoundSequence();
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _globalTimer?.cancel();
    _phaseTimer?.cancel();
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
    if (_currentRoundIndex == 0 && _flashPhase == 'waiting') return 100;
    final totalRoundsPlayed = _correctCount + _errorCount;
    if (totalRoundsPlayed == 0) return 100;
    return (_correctCount / totalRoundsPlayed * 100).round();
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
                Expanded(child: _stageArea()),
                _bottomMetricsBlock(),
              ],
            ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Flash Recognition · 300 ms',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                _isFinished ? 'Complete' : 'Round ${_currentRoundIndex + 1} / $_totalRounds',
                style: const TextStyle(
                  fontSize: 20,
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

  Widget _stageArea() {
    final round = _rounds[_currentRoundIndex];
    final showOptions = _flashPhase == 'answering' || _flashPhase == 'feedback';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _maskCard(round),
            const SizedBox(height: 24),
            Text(
              showOptions ? 'What did you see?' : 'Prepare for flash...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: T.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Opacity(
              opacity: showOptions ? 1.0 : 0.2,
              child: AbsorbPointer(
                absorbing: !showOptions,
                child: Column(
                  children: List.generate(4, (index) {
                    final option = round.options[index];
                    final isSelected = _selectedOptionIndex == index;
                    final isCorrectOption = option == round.target;
                    final showFeedback = _flashPhase == 'feedback';

                    Color cardBg = T.surfaceLowest;
                    Color borderCol = T.border;
                    Color textCol = T.textPrimary;
                    double borderWidth = 0.8;

                    if (showFeedback) {
                      if (isCorrectOption) {
                        cardBg = T.successBg;
                        borderCol = T.success;
                        textCol = T.success;
                        borderWidth = 1.4;
                      } else if (isSelected) {
                        cardBg = T.dangerBg;
                        borderCol = T.error;
                        textCol = T.error;
                        borderWidth = 1.4;
                      }
                    } else if (isSelected) {
                      cardBg = T.primaryBg;
                      borderCol = T.primary;
                      textCol = T.primary;
                      borderWidth = 1.4;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _handleOptionSelect(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderCol, width: borderWidth),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: (isSelected || (showFeedback && isCorrectOption))
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: textCol,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _maskCard(_FlashRound round) {
    final showFlash = _flashPhase == 'flashing';

    return Container(
      width: 300,
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: T.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.border),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 70),
          child: showFlash
              ? Text(
                  round.target,
                  key: ValueKey(round.target),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: T.primary,
                  ),
                )
              : Row(
                  key: const ValueKey('mask'),
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    7,
                    (_) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0x405C5F66),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _bottomMetricsBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Metric(label: 'ACCURACY', value: '${_calculateAccuracy()}%', valueColor: T.success),
          _Metric(label: 'STREAK', value: '$_streak', valueColor: T.textPrimary),
          const _Metric(
            label: 'EXPOSURE',
            value: '300ms',
            valueColor: T.textPrimary,
          ),
        ],
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
                  'You finished Flash Recognition successfully.',
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
                      _statRow('Accuracy achieved', '$acc%'),
                      const Divider(height: 20, thickness: 0.8, color: T.border),
                      _statRow('Max streak', '$_maxStreak'),
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

class _Metric extends StatelessWidget {
  const _Metric({
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
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: T.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
