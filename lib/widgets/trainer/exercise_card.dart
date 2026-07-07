import 'package:flutter/material.dart';

import '../../screens/trainer/trainer_tokens.dart';

/// Status shown on the top-right chip of an [ExerciseCard].
enum ExerciseStatus { recommended, available, completed, locked }

/// Static exercise card mock: icon, title, purpose, best/last results,
/// a status chip and a Start action. UI only.
class ExerciseCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String purpose;
  final String best;
  final String last;
  final ExerciseStatus status;

  const ExerciseCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.purpose,
    this.best = '—',
    this.last = '—',
    this.status = ExerciseStatus.available,
  });

  (String, Color, Color) get _chip => switch (status) {
        ExerciseStatus.recommended => ('RECOMMENDED', T.success, T.successBg),
        ExerciseStatus.completed => ('COMPLETED', T.primary, T.primaryBg),
        ExerciseStatus.locked => ('LOCKED', T.textSecondary, T.surfaceLow),
        ExerciseStatus.available => ('AVAILABLE', T.textSecondary, T.surfaceLow),
      };

  @override
  Widget build(BuildContext context) {
    final (chipText, chipColor, chipBg) = _chip;
    return Opacity(
      opacity: status == ExerciseStatus.locked ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: T.card(),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700, color: T.textPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(chipText,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: chipColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(purpose,
                          style: const TextStyle(fontSize: 12, height: 1.3, color: T.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('BEST', best),
                const SizedBox(width: 14),
                _stat('LAST', last),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: T.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Start',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.onPrimary)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: T.onPrimary),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: T.textSecondary.withValues(alpha: 0.6))),
          const SizedBox(height: 1),
          Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.textPrimary)),
        ],
      );
}
