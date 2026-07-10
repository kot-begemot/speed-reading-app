import 'package:flutter/material.dart';

import '../../screens/trainer/trainer_tokens.dart';

/// Status shown on the top-right chip of an [ExerciseCard].
enum ExerciseStatus { recommended, available, completed, locked }

/// Exercise card: icon, title, purpose, best/last results, a status chip
/// and a Start action that invokes [onStart] when tapped.
class ExerciseCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String purpose;
  final String best;
  final String last;
  final ExerciseStatus status;
  final VoidCallback? onStart;
  final bool highlighted;
  final int? unlockLevel;

  const ExerciseCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.purpose,
    this.best = '—',
    this.last = '—',
    this.status = ExerciseStatus.available,
    this.onStart,
    this.highlighted = false,
    this.unlockLevel,
  });

  (String, Color, Color) _chip(TTheme t) {
    switch (status) {
      case ExerciseStatus.recommended:
        return ('RECOMMENDED', T.success, t.successBg);
      case ExerciseStatus.completed:
        return ('COMPLETED', T.primary, t.primaryBg);
      case ExerciseStatus.locked:
        final text = unlockLevel != null ? 'LVL $unlockLevel REQUIRED' : 'LOCKED';
        return (text, t.textSecondary, t.surfaceLow);
      case ExerciseStatus.available:
        return ('AVAILABLE', t.textSecondary, t.surfaceLow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    final (chipText, chipColor, chipBg) = _chip(t);
    return Opacity(
      opacity: status == ExerciseStatus.locked ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onStart,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: highlighted
                ? t.card().copyWith(border: Border.all(color: accent, width: 1.6))
                : t.card(),
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
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: t.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration:
                                    BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(8)),
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
                              style: TextStyle(fontSize: 12, height: 1.3, color: t.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat('BEST', best, t),
                    const SizedBox(width: 14),
                    _stat('LAST', last, t),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: status == ExerciseStatus.locked ? t.surfaceLow : T.primary,
                        borderRadius: BorderRadius.circular(20),
                        border: status == ExerciseStatus.locked
                            ? Border.all(color: t.border, width: 0.8)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status == ExerciseStatus.locked ? 'Locked' : 'Start',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: status == ExerciseStatus.locked ? t.textSecondary : T.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            status == ExerciseStatus.locked
                                ? Icons.lock_outline_rounded
                                : Icons.arrow_forward_rounded,
                            size: 16,
                            color: status == ExerciseStatus.locked ? t.textSecondary : T.onPrimary,
                          ),
                        ],
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

  Widget _stat(String k, String v, TTheme t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: t.textSecondary.withValues(alpha: 0.6))),
          const SizedBox(height: 1),
          Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary)),
        ],
      );
}
