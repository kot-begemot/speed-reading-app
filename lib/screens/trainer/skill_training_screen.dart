import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/baseline_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/trainer/exercise_card.dart';
import 'flash_recognition_runtime_screen.dart';
import 'number_tracking_runtime_screen.dart';
import 'peripheral_vision_runtime_screen.dart';
import 'schulte_runtime_screen.dart';
import 'chunk_reading_runtime_screen.dart';
import 'schulte_gorbov_runtime_screen.dart';
import 'pyramid_expansion_runtime_screen.dart';
import 'word_match_runtime_screen.dart';
import 'trainer_tokens.dart';
import 'training_program_plan_screen.dart';

enum _Tab { skills, recommended, all }

class _DrillDef {
  final String type;
  final IconData icon;
  final Color accent;
  final String title;
  final String purpose;
  final bool hasRuntime;
  final int unlockLevel;

  const _DrillDef({
    required this.type,
    required this.icon,
    required this.accent,
    required this.title,
    required this.purpose,
    this.hasRuntime = true,
    required this.unlockLevel,
  });
}

const _drills = <_DrillDef>[
  _DrillDef(
    type: 'schulte',
    icon: Icons.grid_view,
    accent: T.accentViolet,
    title: 'Schulte Table',
    purpose: 'Peripheral vision & visual search',
    unlockLevel: 1,
  ),
  _DrillDef(
    type: 'schulte_gorbov',
    icon: Icons.grid_on,
    accent: T.accentViolet,
    title: 'Schulte-Gorbov Table',
    purpose: 'Alternating red & black search',
    unlockLevel: 3,
  ),
  _DrillDef(
    type: 'number_tracking',
    icon: Icons.location_on,
    accent: T.accentTeal,
    title: 'Number Tracking',
    purpose: 'Attention & sequence tracking',
    unlockLevel: 2,
  ),
  _DrillDef(
    type: 'peripheral_vision',
    icon: Icons.visibility,
    accent: T.warning,
    title: 'Peripheral Vision',
    purpose: 'Recognize words at the edges',
    unlockLevel: 3,
  ),
  _DrillDef(
    type: 'flash_recognition',
    icon: Icons.bolt,
    accent: T.primary,
    title: 'Flash Recognition',
    purpose: 'Instant word & phrase recognition',
    unlockLevel: 4,
  ),
  _DrillDef(
    type: 'chunk_reading',
    icon: Icons.view_column,
    accent: T.textSecondary,
    title: 'Chunk Reading',
    purpose: 'Read in 2–4 word groups',
    unlockLevel: 4,
  ),
  _DrillDef(
    type: 'pyramid_expansion',
    icon: Icons.text_fields_rounded,
    accent: T.accentTeal,
    title: 'Pyramid Expansion',
    purpose: 'Vertical focus & visual expansion',
    unlockLevel: 2,
  ),
  _DrillDef(
    type: 'word_match',
    icon: Icons.find_in_page_rounded,
    accent: T.warning,
    title: 'Visual Word Match',
    purpose: 'Rapid word shape recognition',
    unlockLevel: 1,
  ),
];

/// Skill Training list screen — navigates to individual drill screens and
/// filters by Skills / Recommended / All, using real session history for
/// best/last stats and recommendations.
class SkillTrainingScreen extends ConsumerStatefulWidget {
  /// Optional: if provided, the screen will highlight/scroll to this exercise type.
  final String? exerciseType;
  const SkillTrainingScreen({super.key, this.exerciseType});

  @override
  ConsumerState<SkillTrainingScreen> createState() => _SkillTrainingScreenState();
}

class _SkillTrainingScreenState extends ConsumerState<SkillTrainingScreen> {
  _Tab _tab = _Tab.skills;
  final Map<String, GlobalKey> _keys = {for (final d in _drills) d.type: GlobalKey()};

  @override
  void initState() {
    super.initState();
    final target = widget.exerciseType;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
        }
      });
    }
  }

  void _start(String lang, _DrillDef drill) {
    if (!drill.hasRuntime) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${drill.title} is coming soon.')),
      );
      return;
    }

    void onComplete(int accuracy, int errors, int durationSecs) {
      logDrillResult(
        ref,
        languageCode: lang,
        exerciseType: drill.type,
        accuracy: accuracy,
        errors: errors,
        durationSeconds: durationSecs,
      );
      Navigator.pop(context);
    }

    final Widget screen = switch (drill.type) {
      'schulte' => SchulteRuntimeScreen(onComplete: onComplete),
      'schulte_gorbov' => SchulteGorbovRuntimeScreen(onComplete: onComplete),
      'number_tracking' => NumberTrackingRuntimeScreen(onComplete: onComplete),
      'peripheral_vision' => PeripheralVisionRuntimeScreen(onComplete: onComplete),
      'flash_recognition' => FlashRecognitionRuntimeScreen(onComplete: onComplete),
      'chunk_reading' => ChunkReadingRuntimeScreen(onComplete: onComplete),
      'pyramid_expansion' => PyramidExpansionRuntimeScreen(onComplete: onComplete),
      'word_match' => WordMatchRuntimeScreen(onComplete: onComplete),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showLockedDialog(BuildContext context, _DrillDef drill) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: T.surface,
          surfaceTintColor: T.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: drill.accent, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Skill Locked',
                style: TextStyle(fontWeight: FontWeight.w800, color: T.textPrimary),
              ),
            ],
          ),
          content: Text(
            'To practice "${drill.title}", you need to reach Level ${drill.unlockLevel} in the Training Program.\n\nYour current level is based on your daily training progression.',
            style: const TextStyle(fontSize: 14, color: T.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w700, color: T.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingProgramPlanScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: T.primary,
                foregroundColor: T.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Go to Program',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(activeTrainerLanguageProvider);
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(trainerProfileProvider);
    final currentLevel = profileAsync.maybeWhen(
      data: (p) => p.languageProfiles[lang]?.currentLevel ?? 1,
      orElse: () => 1,
    );

    final weakSkills = ref.watch(weakSkillsProvider(lang));
    final weakTypes = weakSkills.map((s) => s.exerciseType).toSet();

    final stats = {
      for (final d in _drills)
        d.type: ref.watch(drillStatProvider((lang: lang, exerciseType: d.type))),
    };
    final anyDataYet = stats.values.any((s) => s.hasData);
    final recommendedTypes = weakTypes.isNotEmpty
        ? weakTypes.where((t) => _drills.any((d) => d.type == t && d.hasRuntime)).toSet()
        : (anyDataYet ? <String>{} : {'schulte'});

    final visible = _drills.where((d) {
      switch (_tab) {
        case _Tab.skills:
          return d.hasRuntime;
        case _Tab.all:
          return true;
        case _Tab.recommended:
          return d.hasRuntime && recommendedTypes.contains(d.type);
      }
    }).toList();

    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        surfaceTintColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Skill Training',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _FilterChip(
                    label: 'Program',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrainingProgramPlanScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Skills',
                    selected: _tab == _Tab.skills,
                    onTap: () => setState(() => _tab = _Tab.skills),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Recommended',
                    selected: _tab == _Tab.recommended,
                    onTap: () => setState(() => _tab = _Tab.recommended),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'All',
                    selected: _tab == _Tab.all,
                    onTap: () => setState(() => _tab = _Tab.all),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const _EmptyRecommended()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final d = visible[index];
                        final stat = stats[d.type] ?? DrillStat.empty;
                        final isLevelLocked = !settings.unlockAllSkills && currentLevel < d.unlockLevel;
                        final status = !d.hasRuntime || isLevelLocked
                            ? ExerciseStatus.locked
                            : recommendedTypes.contains(d.type)
                                ? ExerciseStatus.recommended
                                : stat.hasData
                                    ? ExerciseStatus.completed
                                    : ExerciseStatus.available;
                        return KeyedSubtree(
                          key: _keys[d.type],
                          child: ExerciseCard(
                            icon: d.icon,
                            accent: d.accent,
                            title: d.title,
                            purpose: d.purpose,
                            best: stat.best ?? '—',
                            last: stat.last ?? '—',
                            status: status,
                            highlighted: widget.exerciseType == d.type,
                            unlockLevel: d.unlockLevel,
                            onStart: () {
                              if (!d.hasRuntime) {
                                _start(lang, d);
                              } else if (isLevelLocked) {
                                _showLockedDialog(context, d);
                              } else {
                                _start(lang, d);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecommended extends StatelessWidget {
  const _EmptyRecommended();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No recommendations right now — nice work! Check back after your next session.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: T.textSecondary, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? T.primary : T.surfaceLowest,
              borderRadius: BorderRadius.circular(18),
              border: selected ? null : Border.all(color: T.border, width: 0.8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? T.onPrimary : T.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
