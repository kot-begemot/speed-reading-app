import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';
import '../../services/distractor_generator.dart';

class _WordMatchRound {
  final String target;
  final List<String> options;

  _WordMatchRound({required this.target, required this.options});
}

class WordMatchRuntimeScreen extends StatefulWidget {
  final void Function(int score, int errors, int durationSecs)? onComplete;
  final bool showIntro;

  const WordMatchRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<WordMatchRuntimeScreen> createState() => WordMatchRuntimeScreenState();
}

class WordMatchRuntimeScreenState extends State<WordMatchRuntimeScreen> {
  TTheme get t => T.of(context);
  static const int _totalRounds = 10;

  static final List<List<String>> _wordGroups = [
    ['beach', 'bench', 'peach', 'reach', 'teach', 'bleach', 'beast', 'batch', 'bitch', 'bacon', 'beacon', 'beech'],
    ['train', 'brain', 'drain', 'chain', 'grain', 'trail', 'trains', 'stain', 'plain', 'rainy', 'reign', 'trans'],
    ['flight', 'fight', 'light', 'night', 'right', 'sight', 'tight', 'might', 'slight', 'plight', 'fright', 'flit'],
    ['house', 'horse', 'mouse', 'whose', 'louse', 'housey', 'hours', 'hoarse', 'chase', 'phase', 'rouse', 'hose'],
    ['clock', 'flock', 'block', 'crock', 'clack', 'click', 'cloke', 'cloak', 'clasp', 'shock', 'smock', 'stock'],
    ['water', 'waiter', 'paper', 'later', 'hater', 'taper', 'wafer', 'walter', 'writer', 'winter', 'waste', 'wider'],
    ['green', 'greet', 'greed', 'grown', 'groan', 'queen', 'screen', 'greeny', 'grain', 'grunt', 'great', 'glean'],
    ['stone', 'store', 'shine', 'alone', 'clone', 'shone', 'stole', 'stoneys', 'spine', 'snout', 'stove', 'stage'],
    ['flame', 'frame', 'shame', 'blame', 'flare', 'fame', 'flake', 'flume', 'flash', 'flesh', 'flush', 'claim'],
    ['smart', 'start', 'shirt', 'smash', 'small', 'smelt', 'smile', 'smoke', 'smarted', 'spark', 'shark', 'spart'],
    ['plant', 'plane', 'paint', 'point', 'plank', 'planet', 'plants', 'pliant', 'pant', 'print', 'pointy', 'pants'],
    ['sound', 'round', 'bound', 'pound', 'hound', 'found', 'wound', 'sooth', 'sounds', 'south', 'solid', 'sonar'],
    ['shore', 'share', 'score', 'chore', 'store', 'snore', 'shone', 'shape', 'sharp', 'shirk', 'shirt', 'sheer'],
    ['sleep', 'sheep', 'steep', 'sweep', 'sleek', 'sleepy', 'slips', 'speed', 'sleet', 'weep', 'slope', 'slump'],
    ['cream', 'dream', 'scream', 'steam', 'creed', 'creak', 'crime', 'crept', 'crams', 'crown', 'crane', 'clear'],
    ['track', 'trick', 'truck', 'trace', 'tracks', 'tread', 'trade', 'tracky', 'tack', 'brick', 'tuck', 'trunk'],
    ['pride', 'price', 'prize', 'prime', 'bride', 'prude', 'probe', 'prove', 'prior', 'print', 'prism', 'prick'],
    ['watch', 'match', 'catch', 'patch', 'batch', 'witch', 'water', 'waste', 'watts', 'wrath', 'hatch', 'latch'],
    ['bread', 'break', 'broad', 'beard', 'beads', 'breed', 'brand', 'bribe', 'bleak', 'broom', 'brook', 'board'],
    ['glass', 'grass', 'gloss', 'class', 'glare', 'glands', 'glassy', 'grace', 'gross', 'shining', 'clash', 'flask'],
    ['force', 'forge', 'farce', 'focus', 'forte', 'fores', 'forced', 'horse', 'sauce', 'faced', 'fence', 'first'],
    ['smoke', 'smile', 'smell', 'smart', 'smokehouse', 'smock', 'smoky', 'smirk', 'spoke', 'stoke', 'shake', 'snake'],
    ['fruit', 'fluid', 'flute', 'front', 'fraud', 'frost', 'frown', 'fruity', 'frail', 'frame', 'flume', 'fluteplayer'],
    ['spoke', 'spine', 'space', 'spare', 'spoke-wheel', 'spike', 'spoil', 'spoon', 'spire', 'spore', 'spent', 'sport'],
    ['black', 'block', 'blank', 'blink', 'blackboard', 'slack', 'clack', 'shack', 'blacky', 'blade', 'bland', 'blend'],
    ['climb', 'claim', 'clear', 'clean', 'climber', 'clink', 'cling', 'cliff', 'cloak', 'close', 'cloth', 'clone'],
    ['stage', 'stare', 'share', 'stave', 'stagedoor', 'stale', 'state', 'stagey', 'staves', 'shave', 'store', 'stone'],
    ['place', 'plate', 'plane', 'phase', 'placement', 'plaza', 'plays', 'plaid', 'palace', 'please', 'peace', 'pace'],
    ['count', 'court', 'coast', 'craft', 'counter', 'mount', 'county', 'coins', 'cents', 'costs', 'casts', 'cleft'],
    ['proud', 'prove', 'proof', 'group', 'proudly', 'prowl', 'prude', 'prime', 'prior', 'prize', 'price', 'pound'],
  ];

  late List<_WordMatchRound> _rounds;
  int _currentRoundIndex = 0;
  int _errorCount = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  late bool _showIntro;

  int get currentRoundIndex => _currentRoundIndex;
  List<_WordMatchRound> get rounds => _rounds;
  bool get isFinished => _isFinished;
  int get errorCount => _errorCount;

  // Timer fields
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Flash incorrect selection
  String? _flashingIncorrectWord;

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
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    _currentRoundIndex = 0;
    _errorCount = 0;
    _correctCount = 0;
    _elapsedSeconds = 0;
    _isFinished = false;
    _flashingIncorrectWord = null;

    _generateRounds();
    _startTimer();
  }

  void _generateRounds() {
    _rounds = [];
    final Set<String> targets = {};
    while (targets.length < _totalRounds) {
      targets.add(DistractorGenerator.getRandomWord());
    }

    for (final target in targets) {
      final distractors = DistractorGenerator.generateLookalikes(target, 11);
      final options = [target, ...distractors]..shuffle();
      _rounds.add(_WordMatchRound(target: target, options: options));
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

  void _handleOptionTap(String word) {
    if (_isFinished) return;

    final round = _rounds[_currentRoundIndex];
    if (word == round.target) {
      HapticFeedback.lightImpact();
      setState(() {
        _correctCount++;
        _flashingIncorrectWord = null;
        if (_currentRoundIndex < _totalRounds - 1) {
          _currentRoundIndex++;
        } else {
          _finishGame();
        }
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorCount++;
        _flashingIncorrectWord = word;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          if (_flashingIncorrectWord == word) {
            _flashingIncorrectWord = null;
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
          child: const Icon(Icons.find_in_page_rounded, size: 30, color: T.warning),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual Word Match',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Rapid word shape recognition',
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
                  'Locate matching words · 10 rounds',
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
            text: 'Look at the target: Identify the word displayed in the target box at the top.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Scan the grid: Quickly scan the grid of 12 similar-looking words below.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Tap the match: Tap the exact matching word to proceed to the next round.',
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
            '• Sharpens Visual Discrimination: Speeds up the brain\'s ability to identify subtle differences between similar word configurations.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Speeds up Word Shape Recognition: Trains you to identify words as single visual shapes rather than phonetically sounding them out.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Boosts Processing Velocity: Reduces eye fixations and reading regression in real paragraphs.',
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
                Expanded(child: _playArea()),
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
                'Visual Word Match',
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

  Widget _playArea() {
    final round = _rounds[_currentRoundIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Target Word Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: T.heroGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: T.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  'FIND THIS WORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  round.target,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Options Grid
          Expanded(
            child: Column(
              children: List.generate(4, (rowIndex) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: List.generate(3, (colIndex) {
                        final index = rowIndex * 3 + colIndex;
                        if (index >= round.options.length) {
                          return const Expanded(child: SizedBox.shrink());
                        }
                        final optionWord = round.options[index];
                        final isFlashingError = _flashingIncorrectWord == optionWord;

                        Color cardBg = t.surfaceLowest;
                        Color textCol = t.textPrimary;
                        Border? border = Border.all(color: t.border, width: 0.8);

                        if (isFlashingError) {
                          cardBg = T.error.withValues(alpha: 0.15);
                          textCol = T.error;
                          border = Border.all(color: T.error, width: 1.6);
                        }

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: colIndex == 2 ? 0 : 10),
                            child: GestureDetector(
                              onTap: () => _handleOptionTap(optionWord),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: border,
                                ),
                                child: Text(
                                  optionWord,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textCol,
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildFinishedOverlay() {
    final int accuracy = (_correctCount / (_correctCount + _errorCount) * 100).round();

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
                  'You successfully completed Visual Word Match.',
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
