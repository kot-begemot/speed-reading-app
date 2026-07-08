import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/baseline_provider.dart';
import 'trainer_tokens.dart';

/// Interactive screen hosting the Baseline Assessment flow (Stage 3).
class BaselineAssessmentScreen extends ConsumerStatefulWidget {
  const BaselineAssessmentScreen({super.key});

  @override
  ConsumerState<BaselineAssessmentScreen> createState() => _BaselineAssessmentScreenState();
}

class _BaselineAssessmentScreenState extends ConsumerState<BaselineAssessmentScreen> {
  String _selectedLangCode = 'en';
  int _currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(baselineProvider(_selectedLangCode));
    final notifier = ref.read(baselineProvider(_selectedLangCode).notifier);

    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () {
            if (state.step == BaselineStep.intro) {
              Navigator.pop(context);
            } else {
              // Confirm exit if in progress
              _showExitConfirmation(context);
            }
          },
        ),
        title: Text(
          state.step == BaselineStep.intro
              ? 'Baseline Assessment'
              : state.step == BaselineStep.reading
                  ? 'Reading Phase'
                  : state.step == BaselineStep.quiz
                      ? 'Comprehension Check'
                      : 'Assessment Complete',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBodyForStep(state, notifier),
        ),
      ),
    );
  }

  Widget _buildBodyForStep(BaselineState state, BaselineNotifier notifier) {
    switch (state.step) {
      case BaselineStep.intro:
        return _buildIntroStep(state, notifier);
      case BaselineStep.reading:
        return _buildReadingStep(state, notifier);
      case BaselineStep.quiz:
        return _buildQuizStep(state, notifier);
      case BaselineStep.result:
        return _buildResultStep(state, notifier);
    }
  }

  // ---------------------------------------------------------------------------
  // 1. INTRO STEP
  // ---------------------------------------------------------------------------
  Widget _buildIntroStep(BaselineState state, BaselineNotifier notifier) {
    return Padding(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: T.heroGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.route,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Let's find your level",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: T.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A quick diagnostic is required before training. '
                    "We'll measure your reading speed and comprehension "
                    'to pick a starting level for your language.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _stepsCard(),
                  const SizedBox(height: 16),
                  _languageSelectorRow(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _startButton(notifier),
        ],
      ),
    );
  }

  Widget _stepsCard() {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _stepRow('1', 'Read a short text', '300–600 words at your own pace'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _stepRow('2', 'Answer 5 questions', 'Multiple choice on what you read'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _stepRow('3', 'Get your level', 'Start WPM, target & comprehension'),
        ],
      ),
    );
  }

  Widget _stepRow(String number, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: T.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: T.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: T.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageSelectorRow() {
    return GestureDetector(
      onTap: _showLanguagePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: T.card(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.language, size: 22, color: T.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnostic language',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLangCode == 'en' ? 'English' : 'Русский (Russian)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: T.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: T.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: T.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Choose Language',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: T.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedLangCode == 'en'
                    ? const Icon(Icons.check_circle_rounded, color: T.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedLangCode = 'en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
                title: const Text('Русский (Russian)', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedLangCode == 'ru'
                    ? const Icon(Icons.check_circle_rounded, color: T.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedLangCode = 'ru');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _startButton(BaselineNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.startAssessment(),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: T.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start assessment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. READING STEP
  // ---------------------------------------------------------------------------
  Widget _buildReadingStep(BaselineState state, BaselineNotifier notifier) {
    final text = state.text;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      key: const ValueKey('reading'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant minimal top instruction (no warning/exclamation box)
          const Text(
            'DIAGNOSTIC ASSESSMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: T.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Read at your natural, comfortable pace.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: T.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Scrollable Text view - clean typographic layout with no card background
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: T.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Topic: ${text.topic} · ${text.wordCount} words',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1, color: T.border),
                  const SizedBox(height: 18),
                  Text(
                    text.body,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.65,
                      color: T.textPrimary,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.finishReading(),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              "I'm finished reading",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. QUIZ STEP
  // ---------------------------------------------------------------------------
  Widget _buildQuizStep(BaselineState state, BaselineNotifier notifier) {
    final text = state.text;
    if (text == null) return const SizedBox.shrink();

    final questions = text.questions;
    final currentQuestion = questions[_currentQuestionIndex];
    final selectedOptionIndex = state.answers[_currentQuestionIndex];

    return Padding(
      key: const ValueKey('quiz'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: T.textPrimary,
                ),
              ),
              Text(
                '${((_currentQuestionIndex + 1) / questions.length * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              minHeight: 8,
              backgroundColor: T.border,
              valueColor: const AlwaysStoppedAnimation<Color>(T.primary),
            ),
          ),
          const SizedBox(height: 24),
          // Question card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: T.card(),
                    child: Text(
                      currentQuestion.prompt,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: T.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Options
                  ...List.generate(currentQuestion.options.length, (index) {
                    final option = currentQuestion.options[index];
                    final isSelected = selectedOptionIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => notifier.selectAnswer(_currentQuestionIndex, index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? T.primaryBg : Colors.white,
                            border: Border.all(
                              color: isSelected ? T.primary : T.border,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: T.primary.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? T.primary : T.textSecondary,
                                    width: isSelected ? 6 : 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? T.primary : T.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                        color: T.textPrimary,
                      ),
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: selectedOptionIndex == null
                      ? null
                      : () async {
                          if (_currentQuestionIndex < questions.length - 1) {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          } else {
                            // Last question: submit
                            await notifier.submitQuiz();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T.primary,
                    disabledBackgroundColor: T.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentQuestionIndex < questions.length - 1 ? 'Next' : 'Submit Answers',
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
    );
  }

  // ---------------------------------------------------------------------------
  // 4. RESULT STEP
  // ---------------------------------------------------------------------------
  Widget _buildResultStep(BaselineState state, BaselineNotifier notifier) {
    final suggestedLevel = state.suggestedLevel ?? 1;

    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Celebrate Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: T.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 44,
                        color: T.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Diagnostic Complete!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: T.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We have calculated your metrics for ${_selectedLangCode == 'en' ? 'English' : 'Russian'}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: T.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Level Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [T.primary, T.primary.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: T.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'YOUR ASSIGNED LEVEL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Level $suggestedLevel',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _levelName(suggestedLevel),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _resultStatCard(
                          'Reading Speed',
                          '${state.rawWpm}',
                          'raw WPM',
                          Icons.speed,
                          T.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _resultStatCard(
                          'Comprehension',
                          '${state.comprehensionPercent}%',
                          'accuracy',
                          Icons.quiz_rounded,
                          T.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _resultStatCard(
                    'Effective Reading Speed',
                    '${state.effectiveWpm}',
                    'WPM × comprehension',
                    Icons.bolt,
                    T.accentViolet,
                    isWide: true,
                  ),
                  const SizedBox(height: 20),
                  // Recommendation Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: T.card(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star_rounded, color: T.accentViolet, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recommendation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: T.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _levelRecommendation(suggestedLevel),
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: T.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: T.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Continue to Trainer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultStatCard(
      String title, String value, String unit, IconData icon, Color color,
      {bool isWide = false}) {
    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: T.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: T.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: T.card(),
      child: content,
    );
  }

  String _levelName(int level) {
    switch (level) {
      case 1:
        return 'Novice Reader';
      case 2:
        return 'Advanced Novice';
      case 3:
        return 'Intermediate Reader';
      case 4:
        return 'Efficient Reader';
      case 5:
        return 'Advanced Reader';
      default:
        return 'Master Reader';
    }
  }

  String _levelRecommendation(int level) {
    switch (level) {
      case 1:
        return 'Focus on expanding your peripheral span and avoiding vocalization with basic Schulte grid and Flash drills.';
      case 2:
        return 'Work on chunking words together. Use RSVP reading at 250 WPM to push your visual processing limit.';
      case 3:
        return 'Your pacing is solid! Start the Training Program to practice maintaining high comprehension at 300+ WPM.';
      case 4:
        return 'Excellent starting speed! We recommend advanced training sessions to master skimming and structural tracking.';
      default:
        return 'Outstanding speed and comprehension! Focus on peripheral retention exercises to break past 500+ WPM.';
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit Assessment?'),
          content: const Text(
              'Your progress in this diagnostic will be lost. Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: T.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // pop dialog
                Navigator.pop(context); // pop screen
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
