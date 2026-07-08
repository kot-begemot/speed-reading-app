import 'package:flutter/material.dart';

import '../../widgets/trainer/metric_tile.dart';
import 'trainer_tokens.dart';

/// Interactive Session Result / Qualification summary screen.
class SessionResultScreen extends StatelessWidget {
  final String language;
  final int level;
  final int targetWpm;
  final int rawWpm;
  final int comprehensionRate;
  final int consecutiveSuccessfulSessions;
  final int sessionsRequiredForPromotion;
  final bool levelUpUnlocked;
  final VoidCallback onContinue;
  final VoidCallback onRepeat;
  final VoidCallback onGoToProgress;

  const SessionResultScreen({
    super.key,
    required this.language,
    required this.level,
    required this.targetWpm,
    required this.rawWpm,
    required this.comprehensionRate,
    required this.consecutiveSuccessfulSessions,
    required this.sessionsRequiredForPromotion,
    required this.levelUpUnlocked,
    required this.onContinue,
    required this.onRepeat,
    required this.onGoToProgress,
  });

  @override
  Widget build(BuildContext context) {
    // Session is qualified if speed >= targetWpm and comprehension >= minComprehension of level
    // Level min comprehension is: Level 1-2: 70%, Level 3-4: 65%, Level 5+: 60%
    final int minComprehension = level <= 2 ? 70 : (level <= 4 ? 65 : 60);
    final bool isQualified = rawWpm >= targetWpm && comprehensionRate >= minComprehension;
    final int effectiveWpm = (rawWpm * (comprehensionRate / 100)).round();

    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: T.surfaceLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 24, color: T.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    _banner(isQualified),
                    const SizedBox(height: 24),
                    _heroMetric(effectiveWpm),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: 'READING WPM',
                            value: '$rawWpm',
                            unit: 'wpm',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'COMPREHENSION',
                            value: '$comprehensionRate',
                            unit: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _criteriaCard(isQualified, minComprehension),
                    const SizedBox(height: 24),
                    _streakCard(isQualified),
                    const SizedBox(height: 32),
                    _cta(),
                    const SizedBox(height: 16),
                    _secondaryRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(bool isQualified) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isQualified ? T.successBg : T.dangerBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isQualified ? Icons.check_rounded : Icons.close_rounded,
            size: 40,
            color: isQualified ? T.success : T.error,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isQualified ? 'Qualified!' : 'Not Qualified',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isQualified ? T.success : T.error,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Text Exercise · ${language.toUpperCase()} · Level $level',
          style: const TextStyle(fontSize: 14, color: T.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _heroMetric(int effectiveWpm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'EFFECTIVE WPM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: T.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$effectiveWpm',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              color: T.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _criteriaCard(bool isQualified, int minComprehension) {
    return Container(
      decoration: T.card(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _criteriaRow(
            'Speed target ≥ $targetWpm WPM',
            '$rawWpm WPM',
            rawWpm >= targetWpm,
          ),
          const Divider(height: 1, thickness: 0.8, color: T.border),
          _criteriaRow(
            'Comprehension target ≥ $minComprehension%',
            '$comprehensionRate%',
            comprehensionRate >= minComprehension,
          ),
          const Divider(height: 1, thickness: 0.8, color: T.border),
          _criteriaRow(
            'Text completion 100%',
            'Completed',
            true,
          ),
        ],
      ),
    );
  }

  Widget _criteriaRow(String label, String value, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: passed ? T.success : T.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.textPrimary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: passed ? T.success : T.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(bool isQualified) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consecutive successful sessions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: T.textPrimary),
              ),
              Text(
                '$consecutiveSuccessfulSessions / $sessionsRequiredForPromotion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isQualified ? T.success : T.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(sessionsRequiredForPromotion, (index) {
              final isFilled = index < consecutiveSuccessfulSessions;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == sessionsRequiredForPromotion - 1 ? 0.0 : 6.0,
                  ),
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
          if (levelUpUnlocked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 18, color: T.primary),
                const SizedBox(width: 8),
                Text(
                  'Level ${level + 1} unlocked · target ${targetWpm + (level <= 2 ? 50 : 100)} WPM!',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: T.primary),
                ),
              ],
            ),
          ] else if (!isQualified) ...[
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: T.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Qualified streak was reset. Try again with comfortable focus.',
                    style: TextStyle(fontSize: 12, color: T.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cta() {
    return ElevatedButton(
      onPressed: onContinue,
      style: ElevatedButton.styleFrom(
        backgroundColor: T.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Continue to Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }

  Widget _secondaryRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRepeat,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: T.textSecondary),
            label: const Text(
              'Repeat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: T.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onGoToProgress,
            icon: const Icon(Icons.bar_chart_rounded, size: 18, color: T.textSecondary),
            label: const Text(
              'Progress',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: T.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
