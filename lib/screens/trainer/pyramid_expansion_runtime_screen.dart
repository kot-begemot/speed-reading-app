import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';

class _PyramidLine {
  final String left;
  final String right;

  const _PyramidLine(this.left, this.right);
}

class _PyramidRound {
  final List<_PyramidLine> lines;
  final String targetWord;
  final List<String> verificationOptions;

  const _PyramidRound({
    required this.lines,
    required this.targetWord,
    required this.verificationOptions,
  });
}

class PyramidExpansionRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;
  final bool showIntro;

  const PyramidExpansionRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<PyramidExpansionRuntimeScreen> createState() => PyramidExpansionRuntimeScreenState();
}

class PyramidExpansionRuntimeScreenState extends State<PyramidExpansionRuntimeScreen> {
  TTheme get t => T.of(context);
  static const int _totalRounds = 5;

  static const List<_PyramidRound> _staticRounds = [
    _PyramidRound(
      lines: [
        _PyramidLine('sky', 'blue'),
        _PyramidLine('deep', 'ocean'),
        _PyramidLine('green', 'fields'),
        _PyramidLine('silver', 'lining'),
        _PyramidLine('mountain', 'peaks'),
      ],
      targetWord: 'mountain',
      verificationOptions: ['mountain', 'river', 'forest', 'valley'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('hot', 'sun'),
        _PyramidLine('warm', 'beach'),
        _PyramidLine('yellow', 'sand'),
        _PyramidLine('gentle', 'breeze'),
        _PyramidLine('ocean', 'currents'),
      ],
      targetWord: 'currents',
      verificationOptions: ['currents', 'waves', 'sharks', 'shells'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('cold', 'snow'),
        _PyramidLine('white', 'frost'),
        _PyramidLine('frozen', 'lakes'),
        _PyramidLine('chilly', 'wind'),
        _PyramidLine('winter', 'morning'),
      ],
      targetWord: 'frozen',
      verificationOptions: ['frozen', 'melted', 'slushy', 'boiled'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('fast', 'cars'),
        _PyramidLine('quick', 'pace'),
        _PyramidLine('racing', 'track'),
        _PyramidLine('speedy', 'driving'),
        _PyramidLine('rapid', 'movement'),
      ],
      targetWord: 'speedy',
      verificationOptions: ['speedy', 'slowly', 'heavy', 'steady'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('wise', 'owl'),
        _PyramidLine('smart', 'bird'),
        _PyramidLine('clever', 'fox'),
        _PyramidLine('crafty', 'hunter'),
        _PyramidLine('silent', 'predator'),
      ],
      targetWord: 'predator',
      verificationOptions: ['predator', 'prey', 'keeper', 'forest'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('kind', 'soul'),
        _PyramidLine('happy', 'smile'),
        _PyramidLine('loving', 'family'),
        _PyramidLine('caring', 'friends'),
        _PyramidLine('peaceful', 'relation'),
      ],
      targetWord: 'loving',
      verificationOptions: ['loving', 'hostile', 'lonely', 'angry'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('tall', 'tree'),
        _PyramidLine('thick', 'trunk'),
        _PyramidLine('golden', 'leaves'),
        _PyramidLine('autumn', 'weather'),
        _PyramidLine('blowing', 'branches'),
      ],
      targetWord: 'autumn',
      verificationOptions: ['autumn', 'spring', 'summer', 'winter'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('dark', 'cave'),
        _PyramidLine('black', 'rocks'),
        _PyramidLine('secret', 'pathway'),
        _PyramidLine('hidden', 'treasures'),
        _PyramidLine('glowing', 'diamonds'),
      ],
      targetWord: 'treasures',
      verificationOptions: ['treasures', 'rubbish', 'pebbles', 'shadows'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('soft', 'wool'),
        _PyramidLine('fluffy', 'pillow'),
        _PyramidLine('cozy', 'blankets'),
        _PyramidLine('warm', 'fireplace'),
        _PyramidLine('winter', 'comforts'),
      ],
      targetWord: 'fireplace',
      verificationOptions: ['fireplace', 'snowball', 'icicle', 'frostbite'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('loud', 'bell'),
        _PyramidLine('noisy', 'street'),
        _PyramidLine('crowded', 'markets'),
        _PyramidLine('traffic', 'congestion'),
        _PyramidLine('endless', 'commotion'),
      ],
      targetWord: 'congestion',
      verificationOptions: ['congestion', 'clearance', 'emptiness', 'freedom'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('rare', 'gem'),
        _PyramidLine('shiny', 'pearl'),
        _PyramidLine('costly', 'jewelry'),
        _PyramidLine('antique', 'collection'),
        _PyramidLine('valuable', 'possession'),
      ],
      targetWord: 'possession',
      verificationOptions: ['possession', 'donation', 'loss', 'theft'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('high', 'peak'),
        _PyramidLine('steep', 'climb'),
        _PyramidLine('rocky', 'terrain'),
        _PyramidLine('snowy', 'glacier'),
        _PyramidLine('windy', 'summit'),
      ],
      targetWord: 'glacier',
      verificationOptions: ['glacier', 'desert', 'forest', 'swamp'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('blue', 'lake'),
        _PyramidLine('clear', 'water'),
        _PyramidLine('swimming', 'fishes'),
        _PyramidLine('floating', 'lilies'),
        _PyramidLine('relaxing', 'vacation'),
      ],
      targetWord: 'swimming',
      verificationOptions: ['swimming', 'sinking', 'flying', 'climbing'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('hard', 'work'),
        _PyramidLine('heavy', 'loads'),
        _PyramidLine('strong', 'efforts'),
        _PyramidLine('endless', 'patience'),
        _PyramidLine('deserved', 'success'),
      ],
      targetWord: 'patience',
      verificationOptions: ['patience', 'laziness', 'anger', 'haste'],
    ),
    _PyramidRound(
      lines: [
        _PyramidLine('old', 'town'),
        _PyramidLine('stone', 'walls'),
        _PyramidLine('ancient', 'castles'),
        _PyramidLine('historic', 'monuments'),
        _PyramidLine('beautiful', 'cathedrals'),
      ],
      targetWord: 'monuments',
      verificationOptions: ['monuments', 'skyscrapers', 'factories', 'highways'],
    ),
  ];

  late List<_PyramidRound> _rounds;
  int _currentRoundIndex = 0;
  int _currentLineIndex = 0; // -1 means waiting to start, 5 means verification phase
  int _errorCount = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  bool _isVerificationPhase = false;
  late bool _showIntro;

  int get currentRoundIndex => _currentRoundIndex;
  List<_PyramidRound> get rounds => _rounds;
  bool get isVerificationPhase => _isVerificationPhase;
  bool get isFinished => _isFinished;
  int get errorCount => _errorCount;

  // Pace speed (milliseconds per line)
  int _lineDurationMs = 800;

  // Timers
  Timer? _globalTimer;
  Timer? _lineTimer;
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
    _globalTimer?.cancel();
    _lineTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _globalTimer?.cancel();
    _lineTimer?.cancel();
    _currentRoundIndex = 0;
    _currentLineIndex = 0;
    _errorCount = 0;
    _correctCount = 0;
    _elapsedSeconds = 0;
    _isFinished = false;
    _isVerificationPhase = false;

    // Shuffle the rounds
    _rounds = [..._staticRounds]..shuffle();

    _startTimer();
    _startLinePacing();
  }

  void _startTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startLinePacing() {
    _lineTimer?.cancel();
    _currentLineIndex = 0;
    _isVerificationPhase = false;

    _lineTimer = Timer.periodic(Duration(milliseconds: _lineDurationMs), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentLineIndex < 4) {
          _currentLineIndex++;
        } else {
          _lineTimer?.cancel();
          _isVerificationPhase = true;
        }
      });
    });
  }

  void _handleVerificationTap(String word) {
    final round = _rounds[_currentRoundIndex];
    final bool isCorrect = word == round.targetWord;

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _correctCount++;
    } else {
      HapticFeedback.vibrate();
      _errorCount++;
    }

    setState(() {
      if (_currentRoundIndex < _totalRounds - 1) {
        _currentRoundIndex++;
        _startLinePacing();
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _globalTimer?.cancel();
    _lineTimer?.cancel();
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
          child: const Icon(Icons.text_fields_rounded, size: 30, color: T.accentTeal),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pyramid Expansion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Vertical focus & visual expansion',
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
                  'Identify the outer words · 5 rounds',
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
            text: 'Focus on the center: Keep your eyes fixed on the central vertical guide line.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Follow the highlight: Let the scanning cursor guide your pacing down the pyramid.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Verify retention: At the end of the round, identify which word was in the pyramid.',
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
            '• Stretches Horizontal Vision: Trains your brain to process word meanings further out in the margins.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Minimizes Eye Movements: Eliminates left-to-right eye scanning patterns, which reduces eye strain and speeds up reading.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Builds Spatial Awareness: Enhances rapid structural text scanning and word-chunk processing.',
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
                _progressIndicator(),
                Expanded(
                  child: _isVerificationPhase ? _verificationArea() : _pyramidArea(),
                ),
                _bottomControlArea(),
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
              Text(
                'Pyramid Expansion',
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
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

  Widget _progressIndicator() {
    final double fraction = _currentRoundIndex / _totalRounds;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Round ${_currentRoundIndex + 1} / $_totalRounds',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              Text(
                'Errors: $_errorCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 4,
              color: t.border.withValues(alpha: 0.5),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(color: T.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _pyramidArea() {
    final round = _rounds[_currentRoundIndex];
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical guide line
          Container(
            width: 1.5,
            color: T.accentTeal.withValues(alpha: 0.25),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(round.lines.length, (index) {
              final line = round.lines[index];
              final isCurrent = index == _currentLineIndex;

              // Horizontal spacing increases as we go down the pyramid
              final double spacing = 40.0 + (index * 32.0);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                decoration: BoxDecoration(
                  color: isCurrent ? T.accentTeal.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        line.left,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrent ? t.textPrimary : t.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing / 2),
                    // Central Focus Dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? T.accentTeal : t.textSecondary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: Text(
                        line.right,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                          color: isCurrent ? t.textPrimary : t.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _verificationArea() {
    final round = _rounds[_currentRoundIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline_rounded, size: 48, color: T.accentTeal),
          const SizedBox(height: 16),
          Text(
            'Verification Check',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the word that appeared in the pyramid you just saw:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
          const SizedBox(height: 32),
          Column(
            children: round.verificationOptions.map((word) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _handleVerificationTap(word),
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
                  child: Text(
                    word,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bottomControlArea() {
    if (_isVerificationPhase) {
      return const SizedBox(height: 10);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pacing Speed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              Text(
                '${_lineDurationMs}ms / line',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: T.accentTeal,
              inactiveTrackColor: t.border,
              thumbColor: T.accentTeal,
              overlayColor: T.accentTeal.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _lineDurationMs.toDouble(),
              min: 400,
              max: 1600,
              divisions: 6,
              onChanged: (val) {
                setState(() {
                  _lineDurationMs = val.round();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedOverlay() {
    final int accuracy = (_correctCount / _totalRounds * 100).round();

    return Positioned.fill(
      child: Container(
        color: t.surfaceLow.withValues(alpha: 0.98),
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
                  'You successfully completed Pyramid Expansion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: t.card(radius: 16),
                  child: Column(
                    children: [
                      _statRow('Time elapsed', _formatTime(_elapsedSeconds)),
                      Divider(height: 20, thickness: 0.8, color: t.border),
                      _statRow('Accuracy', '$accuracy%'),
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
