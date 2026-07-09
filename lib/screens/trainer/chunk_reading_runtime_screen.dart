import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trainer_tokens.dart';

class _ChunkQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  const _ChunkQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class ChunkReadingRuntimeScreen extends StatefulWidget {
  final void Function(int wpm, int errors, int durationSecs)? onComplete;
  final bool showIntro;

  const ChunkReadingRuntimeScreen({
    super.key,
    this.onComplete,
    this.showIntro = true,
  });

  @override
  State<ChunkReadingRuntimeScreen> createState() => ChunkReadingRuntimeScreenState();
}

class ChunkReadingRuntimeScreenState extends State<ChunkReadingRuntimeScreen> {
  static const String _textContent =
      "Speed reading is not just about reading fast; it is about comprehension and focus. "
      "When you read chunk-by-chunk, your eyes group multiple words into a single fixation. "
      "This reduces the number of times your eyes stop on each line. "
      "It also prevents subvocalization, which is the habit of saying words silently in your head. "
      "By training with chunks, you will develop a wider span of recognition and process thoughts instantly.";

  static const List<_ChunkQuestion> _questions = [
    _ChunkQuestion(
      question: "What is speed reading NOT just about?",
      options: ["Reading fast", "Comprehension", "Focus", "Visual training"],
      correctAnswer: "Reading fast",
    ),
    _ChunkQuestion(
      question: "What habit does chunk reading help prevent?",
      options: ["Subvocalization", "Regression", "Vocalization", "Blinking"],
      correctAnswer: "Subvocalization",
    ),
    _ChunkQuestion(
      question: "What does grouping words into a single fixation reduce?",
      options: ["Eye stops", "Word count", "Comprehension", "WPM"],
      correctAnswer: "Eye stops",
    ),
  ];

  late List<String> _chunks;
  int _activeChunkIndex = -1; // -1 means waiting to start
  bool _isPlaying = false;
  int _chunkSize = 3; // number of words per chunk
  int _wpm = 300;

  // Question phase state
  bool _isQuestionPhase = false;
  int _currentQuestionIndex = 0;
  int _comprehensionScore = 0;
  int _wrongAnswers = 0;

  bool _isFinished = false;
  late bool _showIntro;

  List<String> get chunks => _chunks;
  int get activeChunkIndex => _activeChunkIndex;
  bool get isQuestionPhase => _isQuestionPhase;
  int get currentQuestionIndex => _currentQuestionIndex;
  String get currentCorrectAnswer => _questions[_currentQuestionIndex].correctAnswer;
  bool get isFinished => _isFinished;
  int get wrongAnswers => _wrongAnswers;
  int get wpm => _wpm;

  Timer? _chunkTimer;
  Timer? _globalTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _showIntro = widget.showIntro;
    _buildChunks();
    if (!_showIntro) {
      _startNewGame();
    }
  }

  @override
  void dispose() {
    _chunkTimer?.cancel();
    _globalTimer?.cancel();
    super.dispose();
  }

  void _buildChunks() {
    final words = _textContent.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final List<String> temp = [];
    for (int i = 0; i < words.length; i += _chunkSize) {
      final end = (i + _chunkSize < words.length) ? i + _chunkSize : words.length;
      temp.add(words.sublist(i, end).join(' '));
    }
    setState(() {
      _chunks = temp;
    });
  }

  void _startNewGame() {
    _chunkTimer?.cancel();
    _globalTimer?.cancel();
    _activeChunkIndex = 0;
    _isPlaying = true;
    _isQuestionPhase = false;
    _currentQuestionIndex = 0;
    _comprehensionScore = 0;
    _wrongAnswers = 0;
    _elapsedSeconds = 0;
    _isFinished = false;

    _buildChunks();
    _startGlobalTimer();
    _startChunkTimer();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _startChunkTimer() {
    _chunkTimer?.cancel();
    if (!_isPlaying) return;

    // Calculate delay based on WPM and average words in chunk
    // Delay (ms) = (60 / WPM) * 1000 * wordsInChunk
    final double wordsInChunk = _chunkSize.toDouble();
    final delayMs = ((60.0 / _wpm) * 1000.0 * wordsInChunk).round();

    _chunkTimer = Timer.periodic(Duration(milliseconds: delayMs), (timer) {
      if (!mounted) return;
      setState(() {
        if (_activeChunkIndex < _chunks.length - 1) {
          _activeChunkIndex++;
        } else {
          _isPlaying = false;
          _chunkTimer?.cancel();
          _isQuestionPhase = true;
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startChunkTimer();
      } else {
        _chunkTimer?.cancel();
      }
    });
  }

  void _handleAnswerTap(String option) {
    final question = _questions[_currentQuestionIndex];
    if (option == question.correctAnswer) {
      _comprehensionScore++;
    } else {
      _wrongAnswers++;
    }

    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _chunkTimer?.cancel();
    _globalTimer?.cancel();
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
            color: T.textSecondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.view_column, size: 30, color: T.textSecondary),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chunk Reading',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Read in 2–4 word groups',
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
                  'Read the text & score 100% on questions',
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
            text: 'Focus on chunks: Focus your gaze on the highlighted block of words.',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '2',
            text: 'Adjust your pace: Set your target reading speed (WPM) and chunk size (2-4 words).',
          ),
          SizedBox(height: 16),
          _InstructionRow(
            number: '3',
            text: 'Answer questions: Complete the short comprehension check at the end.',
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
            '• Widens Fixation Span: Grouping words teaches your eyes to capture meaning in clusters instead of letter-by-letter.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Decreases Subvocalization: Faster visual ingestion naturally quiets the internal monologue.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '• Prevents Eye Regression: Sequential pacing pushes the eye forward, stopping unnecessary re-reading habits.',
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
      backgroundColor: T.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _topBar(),
                Expanded(
                  child: _isQuestionPhase ? _questionArea() : _readerArea(),
                ),
                if (!_isQuestionPhase) _bottomControlArea(),
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
              const Text(
                'Chunk Reading',
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

  Widget _readerArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Wrap(
        spacing: 6,
        runSpacing: 10,
        children: List.generate(_chunks.length, (index) {
          final isCurrent = index == _activeChunkIndex;
          final chunk = _chunks[index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isCurrent ? T.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              chunk,
              style: TextStyle(
                fontSize: 17,
                height: 1.55,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                color: isCurrent ? T.primary : T.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _questionArea() {
    final question = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.quiz_rounded, size: 48, color: T.primary),
          const SizedBox(height: 16),
          Text(
            'Comprehension Check (${_currentQuestionIndex + 1}/${_questions.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: T.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: T.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: question.options.map((word) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _handleAnswerTap(word),
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
                  child: Text(
                    word,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chunk size selector & WPM indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Chunk Size
              Row(
                children: [
                  const Text('Chunk Size: ', style: TextStyle(fontSize: 12, color: T.textSecondary)),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: _chunkSize,
                    underline: const SizedBox(),
                    items: [2, 3, 4].map((v) {
                      return DropdownMenuItem<int>(
                        value: v,
                        child: Text('$v words', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _chunkSize = val;
                          _buildChunks();
                          _activeChunkIndex = 0;
                          _isPlaying = false;
                          _chunkTimer?.cancel();
                        });
                      }
                    },
                  ),
                ],
              ),
              // WPM Speed
              Text(
                '$_wpm WPM',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: T.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: T.primary,
              inactiveTrackColor: T.border,
              thumbColor: T.primary,
              overlayColor: T.primary.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _wpm.toDouble(),
              min: 200,
              max: 600,
              divisions: 8,
              onChanged: (val) {
                setState(() {
                  _wpm = val.round();
                  if (_isPlaying) {
                    _startChunkTimer();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Play/pause
          ElevatedButton.icon(
            onPressed: _togglePlayPause,
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
            label: Text(_isPlaying ? 'Pause' : 'Play'),
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

  Widget _buildFinishedOverlay() {
    final int comprehensionAccuracy = (_comprehensionScore / _questions.length * 100).round();

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
                  'You successfully completed Chunk Reading.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: T.textSecondary),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: T.card(radius: 16),
                  child: Column(
                    children: [
                      _statRow('Speed (WPM)', '$_wpm WPM'),
                      const Divider(height: 20, thickness: 0.8, color: T.border),
                      _statRow('Comprehension', '$comprehensionAccuracy%'),
                      const Divider(height: 20, thickness: 0.8, color: T.border),
                      _statRow('Time elapsed', _formatTime(_elapsedSeconds)),
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
                            widget.onComplete!(_wpm, _wrongAnswers, _elapsedSeconds);
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
