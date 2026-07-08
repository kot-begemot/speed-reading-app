import 'package:flutter/material.dart';

import 'baseline_assessment_screen.dart';
import 'comprehension_test_screen.dart';
import 'exercise_intro_screen.dart';
import 'flash_recognition_runtime_screen.dart';
import 'number_tracking_runtime_screen.dart';
import 'peripheral_vision_runtime_screen.dart';
import 'progress_dashboard_screen.dart';
import 'rsvp_runtime_screen.dart';
import 'schulte_runtime_screen.dart';
import 'session_history_screen.dart';
import 'session_result_screen.dart';
import 'skill_training_screen.dart';
import 'trainer_home_screen.dart';
import 'trainer_tokens.dart';
import 'training_program_plan_screen.dart';

/// Index of the Trainer UI mocks. Presentation-only: each entry pushes a
/// static mock screen. No trainer logic is implemented.
class TrainerGalleryScreen extends StatelessWidget {
  const TrainerGalleryScreen({super.key});

  static const _sections = <(String, List<(String, IconData, Color)>)>[
    ('Overview', [
      ('Trainer Home', Icons.home_rounded, T.primary),
      ('Baseline Assessment', Icons.route_rounded, T.accentViolet),
      ('Skill Training', Icons.fitness_center_rounded, T.accentTeal),
      ('Training Program Plan', Icons.route_rounded, T.primary),
      ('Exercise Intro', Icons.tune_rounded, T.accentViolet),
    ]),
    ('Exercise runtimes', [
      ('Schulte Table', Icons.grid_view_rounded, T.accentViolet),
      ('RSVP Reading', Icons.menu_book_rounded, T.primary),
      ('Number Tracking', Icons.location_on_rounded, T.accentTeal),
      ('Flash Recognition', Icons.bolt_rounded, T.primary),
      ('Peripheral Vision', Icons.visibility_rounded, T.warning),
    ]),
    ('Tests & results', [
      ('Comprehension Test', Icons.quiz_rounded, T.primary),
      ('Session Result', Icons.emoji_events_rounded, T.success),
      ('Progress Dashboard', Icons.bar_chart_rounded, T.primary),
      ('Session History', Icons.history_rounded, T.textSecondary),
    ]),
  ];

  Widget _screenFor(String title) => switch (title) {
        'Trainer Home' => const TrainerHomeScreen(),
        'Baseline Assessment' => const BaselineAssessmentScreen(),
        'Skill Training' => const SkillTrainingScreen(),
        'Training Program Plan' => const TrainingProgramPlanScreen(),
        'Exercise Intro' => const ExerciseIntroScreen(),
        'Schulte Table' => const SchulteRuntimeScreen(),
        'RSVP Reading' => const RsvpRuntimeScreen(
            textTitle: 'Sample Text',
            textContent: 'This is a sample speed reading passage for testing the RSVP reader in gallery mode.',
            targetWpm: 300,
          ),
        'Number Tracking' => const NumberTrackingRuntimeScreen(),
        'Flash Recognition' => const FlashRecognitionRuntimeScreen(),
        'Peripheral Vision' => const PeripheralVisionRuntimeScreen(),
        'Comprehension Test' => const ComprehensionTestScreen(questions: []),
        'Session Result' => SessionResultScreen(
            language: 'en',
            level: 3,
            targetWpm: 300,
            rawWpm: 310,
            comprehensionRate: 80,
            consecutiveSuccessfulSessions: 2,
            sessionsRequiredForPromotion: 3,
            levelUpUnlocked: false,
            onContinue: () {},
            onRepeat: () {},
            onGoToProgress: () {},
          ),
        'Progress Dashboard' => const ProgressDashboardScreen(),
        'Session History' => const SessionHistoryScreen(lang: 'en'),
        _ => const TrainerHomeScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        title: const Text('Trainer mocks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: T.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final (section, items) in _sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(section.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: T.textSecondary)),
              ),
              Container(
                decoration: T.card(),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 1, thickness: 0.8, color: T.border),
                      ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: items[i].$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(items[i].$2, size: 20, color: items[i].$3),
                        ),
                        title: Text(items[i].$1,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600, color: T.textPrimary)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: T.textSecondary),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => _screenFor(items[i].$1)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
