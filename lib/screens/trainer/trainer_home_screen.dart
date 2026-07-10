import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trainer_profile.dart';
import '../../models/training_session.dart';
import '../../providers/baseline_provider.dart';
import '../../providers/progress_provider.dart';
import 'baseline_assessment_screen.dart';
import 'trainer_tokens.dart';

// Import target screens for navigation
import 'session_history_screen.dart';
import 'skill_training_screen.dart';
import 'training_program_plan_screen.dart';
import 'schulte_runtime_screen.dart';
import 'number_tracking_runtime_screen.dart';
import 'peripheral_vision_runtime_screen.dart';
import 'flash_recognition_runtime_screen.dart';

/// Fully functional Trainer Home Screen with conditional routing gates.
class TrainerHomeScreen extends ConsumerWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(activeTrainerLanguageProvider);
    final profileAsync = ref.watch(trainerProfileProvider);

    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: Text('Loading...', style: TextStyle(color: T.textSecondary))),
          error: (err, stack) => Center(
            child: Text(
              'Error loading profile: $err',
              style: const TextStyle(color: T.error),
            ),
          ),
          data: (profile) {
            final langProfile = profile.languageProfiles[langCode];
            final hasBaseline = langProfile?.baselineCompletedAt != null;

            if (!hasBaseline) {
              return _buildBaselineRequiredView(context, ref, langCode);
            }

            return _buildDashboardView(context, ref, langCode, profile, langProfile!);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar with language selector
  // ---------------------------------------------------------------------------
  Widget _topBar(BuildContext context, WidgetRef ref, String langCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Trainer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: T.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => _showLanguagePicker(context, ref, langCode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            decoration: BoxDecoration(
              color: T.surfaceLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: T.border, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: T.textSecondary),
                const SizedBox(width: 6),
                Text(
                  langCode == 'en' ? 'English' : 'Русский',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: T.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: T.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLang) {
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
                trailing: currentLang == 'en'
                    ? const Icon(Icons.check_circle_rounded, color: T.primary)
                    : null,
                onTap: () {
                  ref.read(activeTrainerLanguageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
                title: const Text('Русский (Russian)', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: currentLang == 'ru'
                    ? const Icon(Icons.check_circle_rounded, color: T.primary)
                    : null,
                onTap: () {
                  ref.read(activeTrainerLanguageProvider.notifier).setLanguage('ru');
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

  // ---------------------------------------------------------------------------
  // Locked Baseline View
  // ---------------------------------------------------------------------------
  Widget _buildBaselineRequiredView(BuildContext context, WidgetRef ref, String langCode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _topBar(context, ref, langCode),
          const Spacer(),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: T.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: T.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Diagnostic Required',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: T.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please complete the baseline assessment for ${langCode == 'en' ? 'English' : 'Russian'} '
            'to unlock the training program and skill drills.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: T.textSecondary,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BaselineAssessmentScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: T.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start baseline assessment',
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unlocked Dashboard View
  // ---------------------------------------------------------------------------
  Widget _buildDashboardView(
    BuildContext context,
    WidgetRef ref,
    String langCode,
    TrainerProfile profile,
    TrainerLanguageProfile langProfile,
  ) {
    final recentSessionsAsync = ref.watch(recentSessionsProvider(langCode));

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _topBar(context, ref, langCode),
        const SizedBox(height: 16),
        _levelCard(langProfile),
        const SizedBox(height: 16),
        _modeRow(context),
        const SizedBox(height: 16),
        _sectionHeader('Quick drills', 'See all', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SkillTrainingScreen()),
          );
        }),
        const SizedBox(height: 12),
        _quickDrills(context, ref, langCode),
        const SizedBox(height: 16),
        _sectionHeader('Recent sessions', 'History', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SessionHistoryScreen(lang: langCode)),
          );
        }),
        const SizedBox(height: 12),
        recentSessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: T.primary)),
          error: (err, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: T.card(),
            child: Text('Error loading history: $err'),
          ),
          data: (sessions) => _buildRecentSessionsList(sessions),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Level card with active level data
  // ---------------------------------------------------------------------------
  Widget _levelCard(TrainerLanguageProfile langProfile) {
    final level = langProfile.currentLevel;
    final targetWpm = _targetWpmForLevel(level);
    final minComprehension = _minComprehensionForLevel(level);
    final requiredStreak = _requiredSessionsForLevel(level);
    final streak = langProfile.successfulSessionsInRow;
    final nextLevel = level + 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: T.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: T.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level · ${_levelName(level)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _glassTile(Icons.speed, 'Target WPM', '$targetWpm'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _glassTile(Icons.psychology, 'Min comprehension', '$minComprehension%'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sessions to Level $nextLevel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Text(
                '${streak.clamp(0, requiredStreak)} / $requiredStreak',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(requiredStreak, (index) {
              final isFilled = index < streak;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == requiredStreak - 1 ? 0 : 6.0,
                  ),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 16, color: T.gold),
              const SizedBox(width: 6),
              Text(
                'Personal best · ${langProfile.bestEffectiveWpm} effective WPM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode row (Training Program / Skill Training)
  // ---------------------------------------------------------------------------
  Widget _modeRow(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrainingProgramPlanScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: T.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: T.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.gps_fixed, size: 26, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Training Program',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Guided path that levels you up',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SkillTrainingScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: T.card(),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fitness_center, size: 26, color: T.accentTeal),
                    SizedBox(height: 12),
                    Text(
                      'Skill Training',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: T.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Free drills for single skills',
                      style: TextStyle(fontSize: 11, color: T.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: T.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: T.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quick drills grid
  // ---------------------------------------------------------------------------
  Widget _quickDrills(BuildContext context, WidgetRef ref, String langCode) {
    void Function(int, int, int) onCompleteFor(String exerciseType) {
      return (accuracy, errors, durationSecs) {
        logDrillResult(
          ref,
          languageCode: langCode,
          exerciseType: exerciseType,
          accuracy: accuracy,
          errors: errors,
          durationSeconds: durationSecs,
        );
        Navigator.pop(context);
      };
    }

    // Schulte is the only quick-drill card that surfaces a best-result
    // subtitle; it reads from the same drillStatProvider as the Skill
    // Training screen so both stay in sync regardless of where a session
    // was actually played.
    final schulteStat = ref.watch(drillStatProvider((lang: langCode, exerciseType: 'schulte')));
    final schulteBestSecs = schulteStat.best?.split(' · ').last;
    final schulteSub = schulteBestSecs != null ? '5×5 · best $schulteBestSecs' : '5×5 · not attempted yet';

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SchulteRuntimeScreen(onComplete: onCompleteFor('schulte')),
                      ),
                    );
                  },
                  child: _drillCard(Icons.grid_view, T.accentViolet, 'Schulte Table', schulteSub),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NumberTrackingRuntimeScreen(onComplete: onCompleteFor('number_tracking')),
                      ),
                    );
                  },
                  child: _drillCard(Icons.location_on, T.accentTeal, 'Number Tracking', 'Find & follow digits'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PeripheralVisionRuntimeScreen(onComplete: onCompleteFor('peripheral_vision')),
                      ),
                    );
                  },
                  child: _drillCard(Icons.visibility, T.warning, 'Peripheral Vision', 'Recognize at the edges'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FlashRecognitionRuntimeScreen(onComplete: onCompleteFor('flash_recognition')),
                      ),
                    );
                  },
                  child: _drillCard(Icons.bolt, T.primary, 'Flash Recognition', '300ms · 3-word phrases'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _drillCard(IconData icon, Color accent, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: T.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: T.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: T.textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent sessions from database box
  // ---------------------------------------------------------------------------
  Widget _buildRecentSessionsList(List<TrainingSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: T.card(),
        child: const Column(
          children: [
            Icon(Icons.history, color: T.textSecondary, size: 36),
            SizedBox(height: 10),
            Text(
              'No training sessions yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.textPrimary),
            ),
            SizedBox(height: 4),
            Text(
              'Complete program steps to see logs here.',
              style: TextStyle(fontSize: 12, color: T.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: T.border),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final isQualified = session.qualified;
          final isFailed = !isQualified && session.failReason != null;

          IconData icon;
          Color statusColor;
          Color badgeBg;
          Color badgeText;
          String badge;

          if (isFailed) {
            icon = Icons.close;
            statusColor = T.error;
            badgeBg = T.dangerBg;
            badgeText = T.error;
            badge = 'FAILED';
          } else if (isQualified) {
            icon = Icons.check;
            statusColor = T.success;
            badgeBg = T.successBg;
            badgeText = T.success;
            badge = 'QUALIFIED';
          } else {
            icon = Icons.fitness_center_rounded;
            statusColor = T.primary;
            badgeBg = T.surfaceLow;
            badgeText = T.textSecondary;
            badge = 'PRACTICE';
          }

          final hasReading = session.finalWpm > 0;
          final hasBaseline = session.exerciseResults.any((e) => e.exerciseType == 'baseline_reading');

          String displayTitle;
          String displayMeta;

          if (hasBaseline) {
            displayTitle = 'Baseline Diagnostic';
            displayMeta = '${session.finalWpm} wpm · ${session.comprehensionPercent}% comprehension';
          } else if (hasReading) {
            displayTitle = 'Training Program · Level ${session.level}';
            displayMeta = '${session.finalWpm} wpm · ${session.comprehensionPercent}% comprehension';
          } else {
            final r = session.exerciseResults.isNotEmpty ? session.exerciseResults.first : null;
            if (r != null) {
              displayTitle = _prettyExerciseName(r.exerciseType);
              final type = r.exerciseType;
              final mistakesStr = r.mistakes == 1 ? '1 mistake' : '${r.mistakes ?? 0} mistakes';
              if (type == 'schulte' || type == 'number_tracking') {
                displayMeta = 'Duration: ${r.durationSeconds}s · $mistakesStr';
              } else if (type == 'flash_recognition' || type == 'peripheral_vision') {
                final accuracyStr = r.accuracyPercent != null ? '${r.accuracyPercent!.round()}% accuracy' : '100% accuracy';
                displayMeta = '$accuracyStr · $mistakesStr';
              } else {
                displayMeta = 'Duration: ${r.durationSeconds}s';
              }
            } else {
              displayTitle = 'Practice Session';
              displayMeta = '';
            }
          }

          return _sessionRow(icon, statusColor, badgeBg, badge, badgeText, displayTitle, displayMeta);
        },
      ),
    );
  }

  Widget _sessionRow(
    IconData icon,
    Color statusColor,
    Color badgeBg,
    String badge,
    Color badgeText,
    String title,
    String meta,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
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
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: T.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Level stats configuration helpers
  // ---------------------------------------------------------------------------
  int _targetWpmForLevel(int level) {
    if (level == 1) return 200;
    if (level == 2) return 250;
    if (level == 3) return 300;
    if (level == 4) return 400;
    if (level == 5) return 500;
    return (level - 1) * 100 + 100;
  }

  int _minComprehensionForLevel(int level) {
    if (level == 1 || level == 2) return 70;
    if (level == 3 || level == 4) return 65;
    return 60;
  }

  int _requiredSessionsForLevel(int level) {
    if (level <= 3) return 3;
    return 5;
  }

  String _levelName(int level) {
    switch (level) {
      case 1:
        return 'Novice';
      case 2:
        return 'Advanced Novice';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Efficient';
      case 5:
        return 'Advanced';
      default:
        return 'Master';
    }
  }

  String _prettyExerciseName(String type) {
    switch (type) {
      case 'schulte':
        return 'Schulte Table';
      case 'number_tracking':
        return 'Number Tracking';
      case 'peripheral_vision':
        return 'Peripheral Vision';
      case 'flash_recognition':
        return 'Flash Recognition';
      case 'baseline_reading':
        return 'Baseline Diagnostic';
      default:
        return 'Reading Test';
    }
  }
}
