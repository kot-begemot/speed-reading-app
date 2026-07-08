import 'package:flutter/material.dart';

import '../../widgets/trainer/exercise_card.dart';
import 'trainer_tokens.dart';

/// Static mock: the Skill Training list screen. UI only — no logic.
class SkillTrainingScreen extends StatelessWidget {
  const SkillTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      appBar: AppBar(
        backgroundColor: T.surface,
        surfaceTintColor: T.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.textPrimary),
          onPressed: () {},
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
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _FilterChip(label: 'Program'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Skills', selected: true),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Recommended'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'All'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ExerciseCard(
                    icon: Icons.grid_view,
                    accent: T.accentViolet,
                    title: 'Schulte Table',
                    purpose: 'Peripheral vision & visual search',
                    best: '5×5 · 38s',
                    last: '5×5 · 51s',
                    status: ExerciseStatus.recommended,
                  ),
                  SizedBox(height: 12),
                  ExerciseCard(
                    icon: Icons.location_on,
                    accent: T.accentTeal,
                    title: 'Number Tracking',
                    purpose: 'Attention & sequence tracking',
                    best: 'Level 4',
                    last: 'Level 3',
                    status: ExerciseStatus.available,
                  ),
                  SizedBox(height: 12),
                  ExerciseCard(
                    icon: Icons.visibility,
                    accent: T.warning,
                    title: 'Peripheral Vision',
                    purpose: 'Recognize words at the edges',
                    best: '80% · 8 pos',
                    last: '72% · 8 pos',
                    status: ExerciseStatus.available,
                  ),
                  SizedBox(height: 12),
                  ExerciseCard(
                    icon: Icons.bolt,
                    accent: T.primary,
                    title: 'Flash Recognition',
                    purpose: 'Instant word & phrase recognition',
                    best: '200ms',
                    last: '300ms',
                    status: ExerciseStatus.completed,
                  ),
                  SizedBox(height: 12),
                  ExerciseCard(
                    icon: Icons.view_column,
                    accent: T.textSecondary,
                    title: 'Chunk Reading',
                    purpose: 'Read in 2–4 word groups',
                    best: '—',
                    last: '—',
                    status: ExerciseStatus.locked,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? T.primary : T.surfaceLowest,
        borderRadius: BorderRadius.circular(20),
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
    );
  }
}
