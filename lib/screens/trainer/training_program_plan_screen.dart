import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trainer_tokens.dart';
import '../../providers/training_program_provider.dart';
import 'schulte_runtime_screen.dart';
import 'flash_recognition_runtime_screen.dart';
import 'rsvp_runtime_screen.dart';
import 'comprehension_test_screen.dart';
import 'session_result_screen.dart';

/// Interactive Training Program plan screen that drives the step-by-step
/// workflow from Warm-up to Reading, Comprehension Quiz, and Results.
class TrainingProgramPlanScreen extends ConsumerWidget {
  const TrainingProgramPlanScreen({super.key});

  void _startNextStep(BuildContext context, WidgetRef ref, TrainingProgramState state) {
    if (state.currentStepIndex == 0) {
      // Step 1: Schulte Table Warm-up
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SchulteRuntimeScreen(
            onComplete: (accuracy, errors, durationSecs) {
              ref.read(trainingProgramProvider.notifier).logWarmUp(errors, durationSecs);
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (state.currentStepIndex == 1) {
      // Step 2: Flash Recognition Drill
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashRecognitionRuntimeScreen(
            onComplete: (accuracy, errors, durationSecs) {
              ref.read(trainingProgramProvider.notifier).logRecognition(accuracy, errors);
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (state.currentStepIndex == 2) {
      // Step 3: RSVP Text Reading
      if (state.selectedText == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unread text found for training.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RsvpRuntimeScreen(
            textTitle: state.selectedText!.title,
            textContent: state.selectedText!.body,
            targetWpm: state.targetWpm,
            onComplete: (rawWpm, wordsRead) {
              ref.read(trainingProgramProvider.notifier).logReading(rawWpm, wordsRead);
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (state.currentStepIndex == 3) {
      // Step 4: Comprehension Test Quiz
      if (state.selectedText == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprehensionTestScreen(
            questions: state.selectedText!.questions,
            onComplete: (correctCount) async {
              final oldState = ref.read(trainingProgramProvider);
              await ref.read(trainingProgramProvider.notifier).submitQuizAndCompleteSession(correctCount);
              final newState = ref.read(trainingProgramProvider);
              
              if (!context.mounted) return;
              Navigator.pop(context); // Pop comprehension test

              // Push the final results screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionResultScreen(
                    language: newState.languageCode,
                    level: oldState.level,
                    targetWpm: oldState.targetWpm,
                    rawWpm: newState.readingWpm ?? oldState.targetWpm,
                    comprehensionRate: newState.comprehensionRate ?? 0,
                    consecutiveSuccessfulSessions: newState.consecutiveSuccessfulSessions,
                    sessionsRequiredForPromotion: newState.sessionsRequiredForPromotion,
                    levelUpUnlocked: newState.levelUpUnlocked,
                    onContinue: () {
                      ref.read(trainingProgramProvider.notifier).startSession();
                      Navigator.pop(context); // pop result
                      Navigator.pop(context); // pop plan screen (return to Trainer Home)
                    },
                    onRepeat: () {
                      Navigator.pop(context); // pop result
                      ref.read(trainingProgramProvider.notifier).startSession();
                    },
                    onGoToProgress: () {
                      ref.read(trainingProgramProvider.notifier).startSession();
                      Navigator.pop(context); // pop result
                      Navigator.pop(context); // pop plan screen
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingProgramProvider);

    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        surfaceTintColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Training Program',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _goalCard(state),
            const SizedBox(height: 20),
            const Text(
              'This session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: T.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _Step(
                  state: _getStepState(0, state),
                  icon: Icons.grid_view_rounded,
                  kicker: 'SKILL WARM-UP',
                  title: 'Schulte Table · 5×5',
                ),
                const SizedBox(height: 10),
                _Step(
                  state: _getStepState(1, state),
                  icon: Icons.bolt_rounded,
                  kicker: 'RECOGNITION DRILL',
                  title: 'Flash Recognition · 300ms',
                ),
                const SizedBox(height: 10),
                _Step(
                  state: _getStepState(2, state),
                  icon: Icons.menu_book_rounded,
                  kicker: 'TEXT EXERCISE',
                  title: 'RSVP Reading · ${state.targetWpm} WPM',
                ),
                const SizedBox(height: 10),
                _Step(
                  state: _getStepState(3, state),
                  icon: Icons.quiz_rounded,
                  kicker: 'COMPREHENSION TEST',
                  title: '${state.selectedText?.questions.length ?? 5} questions',
                ),
                const SizedBox(height: 10),
                _Step(
                  state: _getStepState(4, state),
                  icon: Icons.flag_rounded,
                  kicker: 'LEVEL CHECKPOINT',
                  title: 'Qualify to advance',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!state.isSessionComplete) ...[
              _primaryCta(context, ref, state),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  _StepState _getStepState(int index, TrainingProgramState state) {
    if (state.isSessionComplete) return _StepState.done;
    if (state.currentStepIndex > index) return _StepState.done;
    if (state.currentStepIndex == index) return _StepState.current;
    return _StepState.locked;
  }

  Widget _goalCard(TrainingProgramState state) {
    final progress = state.consecutiveSuccessfulSessions;
    final total = state.sessionsRequiredForPromotion;
    final minComprehension = state.level <= 2 ? 70 : (state.level <= 4 ? 65 : 60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.languageCode.toUpperCase()} · LEVEL ${state.level}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: T.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${state.targetWpm} WPM · ≥$minComprehension%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: T.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$progress / $total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: T.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(total, (index) {
              final isFilled = index < progress;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == total - 1 ? 0.0 : 6.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isFilled ? T.success : T.borderStrong.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '${total - progress} more qualified session${(total - progress) > 1 ? 's' : ''} to reach Level ${state.level + 1}',
            style: const TextStyle(fontSize: 12, color: T.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta(BuildContext context, WidgetRef ref, TrainingProgramState state) {
    final isQuiz = state.currentStepIndex == 3;

    return ElevatedButton(
      onPressed: () => _startNextStep(context, ref, state),
      style: ElevatedButton.styleFrom(
        backgroundColor: T.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isQuiz ? 'Start Comprehension Test' : 'Start next step',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.play_arrow_rounded, size: 20),
        ],
      ),
    );
  }
}

enum _StepState { done, current, locked }

class _Step extends StatelessWidget {
  final _StepState state;
  final IconData icon;
  final String kicker;
  final String title;

  const _Step({
    required this.state,
    required this.icon,
    required this.kicker,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor = switch (state) {
      _StepState.done => T.success,
      _StepState.current => T.primary,
      _StepState.locked => T.surfaceLow,
    };
    final Color iconColor =
        state == _StepState.locked ? T.textSecondary : Colors.white;
    final Color kickerColor = switch (state) {
      _StepState.current => T.primary,
      _StepState.locked => T.textSecondary,
      _StepState.done => T.textSecondary,
    };

    final BoxDecoration decoration = state == _StepState.current
        ? BoxDecoration(
            color: T.primaryBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.primary, width: 1.2),
          )
        : T.card(radius: 14);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: kickerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (state == _StepState.done) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle_rounded, size: 20, color: T.success),
          ] else if (state == _StepState.current) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: T.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (state == _StepState.locked) {
      return Opacity(opacity: 0.6, child: card);
    }
    return card;
  }
}
