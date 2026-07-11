import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';
import '../../services/distractor_generator.dart';

class _PeripheralRound {
  final String target;
  final List<String> options;
  final int angleIndex; // 0 to 7 representing angle: index * pi / 4

  _PeripheralRound({
    required this.target,
    required this.options,
    required this.angleIndex,
  });
}

/// Fully interactive Peripheral Vision drill. Shows a central focal point and flashes
/// stimuli at the periphery, requiring the user to recognize the word.
class PeripheralVisionRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;
  final bool showIntro;

  const PeripheralVisionRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<PeripheralVisionRuntimeScreen> createState() => PeripheralVisionRuntimeScreenState();
}

class PeripheralVisionRuntimeScreenState extends State<PeripheralVisionRuntimeScreen> {
  TTheme get t => T.of(context);
  static const int _totalRounds = 10;
  static const double _peripheralRadiusFactor = 0.35; // R = min(w,h) * factor

  // Pool of target word options
  static final List<List<String>> _wordPool = [
    ['cloud', 'clock', 'crowd', 'could'],
    ['house', 'horse', 'mouse', 'whose'],
    ['train', 'brain', 'drain', 'chain'],
    ['light', 'night', 'right', 'fight'],
    ['water', 'waiter', 'paper', 'later'],
    ['green', 'greet', 'greed', 'grown'],
    ['stone', 'store', 'shine', 'alone'],
    ['flame', 'frame', 'shame', 'blame'],
    ['beach', 'bench', 'reach', 'peach'],
    ['smart', 'start', 'shirt', 'smash'],
    ['plant', 'plane', 'paint', 'point'],
    ['sound', 'round', 'bound', 'pound'],
    ['shore', 'share', 'score', 'chore'],
    ['sleep', 'sheep', 'steep', 'sweep'],
    ['cream', 'dream', 'scream', 'steam'],
    ['track', 'trick', 'truck', 'trace'],
    ['pride', 'price', 'prize', 'prime'],
    ['watch', 'match', 'catch', 'patch'],
    ['bread', 'break', 'broad', 'beard'],
    ['glass', 'grass', 'gloss', 'class'],
    ['force', 'forge', 'farce', 'focus'],
    ['smoke', 'smile', 'smell', 'smart'],
    ['fruit', 'fluid', 'flute', 'front'],
    ['spoke', 'spine', 'space', 'spare'],
    ['black', 'block', 'blank', 'blink'],
    ['climb', 'claim', 'clear', 'clean'],
    ['stage', 'stare', 'share', 'stave'],
    ['place', 'plate', 'plane', 'phase'],
    ['count', 'court', 'coast', 'craft'],
    ['proud', 'prove', 'proof', 'group'],
  ];

  late List<_PeripheralRound> _rounds;
  int _currentRoundIndex = 0;
  int _errorCount = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  late bool _showIntro;

  // Flash phases: 'waiting', 'flashing', 'answering', 'feedback'
  String _flashPhase = 'waiting'; 
  int? _selectedOptionIndex;
  Timer? _phaseTimer;
  Timer? _globalTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _showIntro = widget.showIntro;
    if (_showIntro) {
      _rounds = [];
    } else {
      _startNewGame();
    }
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
    _elapsedSeconds = 0;
    _isFinished = false;
    _selectedOptionIndex = null;
    _flashPhase = 'waiting';

    _generateRounds();
    _startGlobalTimer();
    _startRoundSequence();
  }

  void _generateRounds() {
    final rand = Random();
    final Set<String> targets = {};
    while (targets.length < _totalRounds) {
      targets.add(DistractorGenerator.getRandomWord());
    }

    _rounds = targets.map((target) {
      final distractors = DistractorGenerator.generateLookalikes(target, 3);
      final options = [target, ...distractors]..shuffle();
      final angleIdx = rand.nextInt(8);
      return _PeripheralRound(
        target: target,
        options: options,
        angleIndex: angleIdx,
      );
    }).toList();
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

    // 1. Wait 800ms with center dot only, then flash
    _phaseTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _flashPhase = 'flashing';
      });

      // 2. Flash word for 600ms, then hide and show answers
      _phaseTimer = Timer(const Duration(milliseconds: 600), () {
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
        HapticFeedback.lightImpact();
      } else {
        _errorCount++;
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
            color: T.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.visibility, size: 30, color: T.warning),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peripheral Vision',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Recognize words at the edges',
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
                  'Identify flashed words · 10 rounds',
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
            text: 'Focus on the center: Keep your eyes fixed on the center crosshair (+) at all times.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Flashing stimuli: A word will flash briefly at the edge of your screen.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Identify the word: Select the correct word from the options at the bottom.',
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
            '• Expand Peripheral Span: Increases your ability to perceive and read words outside your direct line of sight.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Minimize Eye Movements: Redirection of eye movement reduces fatigue and increases reading speed.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Boost Recognition Speed: Speeds up word recognition and cognitive translation.',
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
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Keep your eyes on the center dot',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: _field()),
                _bottomAnswerArea(),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Peripheral Vision · 8 positions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              Text(
                _isFinished ? 'Complete' : 'Round ${_currentRoundIndex + 1} / $_totalRounds',
                style: TextStyle(
                  fontSize: 20,
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

  Widget _field() {
    final round = _rounds[_currentRoundIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final centerX = w / 2;
        final centerY = h / 2;
        final radius = min(w, h) * _peripheralRadiusFactor;

        // Calculate active peripheral positions for faint dots
        final List<Point<double>> dotPositions = [];
        for (int i = 0; i < 8; i++) {
          final double angle = i * pi / 4;
          final double x = centerX + radius * cos(angle);
          final double y = centerY + radius * sin(angle);
          dotPositions.add(Point(x, y));
        }

        // Active stimulus coordinate
        final activePos = dotPositions[round.angleIndex];

        return Stack(
          key: const Key('peripheral_field_stack'),
          clipBehavior: Clip.hardEdge,
          children: [
            // Center crosshair (+)
            Positioned(
              left: centerX - 13,
              top: centerY - 22,
              child: const Text(
                '+',
                style: TextStyle(
                  fontSize: 26,
                  color: Color(0x304C6EF5),
                ),
              ),
            ),
            // Center focal dot
            Positioned(
              left: centerX - 8,
              top: centerY - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: T.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Faint peripheral helper dots
            for (int i = 0; i < dotPositions.length; i++)
              Positioned(
                left: dotPositions[i].x - 4,
                top: dotPositions[i].y - 4,
                child: const _FaintDot(),
              ),
            // Active Flash Stimulus
            if (_flashPhase == 'flashing')
              Positioned(
                left: activePos.x - 45, // approximate center offset
                top: activePos.y - 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: t.surfaceLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: T.warning, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: T.warning.withValues(alpha: 0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Text(
                    round.target,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _bottomAnswerArea() {
    final round = _rounds[_currentRoundIndex];
    final showOptions = _flashPhase == 'answering' || _flashPhase == 'feedback';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showOptions ? 'Which word appeared?' : 'Focus on the center...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: showOptions ? 1.0 : 0.2,
            child: AbsorbPointer(
              absorbing: !showOptions,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final option = round.options[index];
                  final isSelected = _selectedOptionIndex == index;
                  final isCorrectOption = option == round.target;
                  final showFeedback = _flashPhase == 'feedback';

                  Color cardBg = t.surfaceLowest;
                  Color borderCol = t.border;
                  Color textCol = t.textPrimary;
                  double borderWidth = 0.8;

                  if (showFeedback) {
                    if (isCorrectOption) {
                      cardBg = t.successBg;
                      borderCol = T.success;
                      textCol = T.success;
                      borderWidth = 1.4;
                    } else if (isSelected) {
                      cardBg = t.dangerBg;
                      borderCol = T.error;
                      textCol = T.error;
                      borderWidth = 1.4;
                    }
                  } else if (isSelected) {
                    cardBg = t.primaryBg;
                    borderCol = T.primary;
                    textCol = T.primary;
                    borderWidth = 1.4;
                  }

                  return GestureDetector(
                    onTap: () => _handleOptionSelect(index),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol, width: borderWidth),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isSelected || (showFeedback && isCorrectOption))
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: textCol,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
                  'You finished Peripheral Vision successfully.',
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
                          backgroundColor: T.primary,
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

class _FaintDot extends StatelessWidget {
  const _FaintDot();

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: t.textSecondary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
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

