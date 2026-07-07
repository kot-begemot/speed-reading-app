import 'package:flutter/material.dart';

import '../../widgets/trainer/metric_tile.dart';
import 'trainer_tokens.dart';

/// Static UI mock: session result / qualification summary screen.
class SessionResultScreen extends StatelessWidget {
  const SessionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onTap: () {},
                    child: const Icon(Icons.close_rounded, size: 24, color: T.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _banner(),
                    const SizedBox(height: 20),
                    _heroMetric(),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(
                          child: MetricTile(
                            label: 'READING WPM',
                            value: '310',
                            unit: 'wpm',
                            delta: '+10',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'COMPREHENSION',
                            value: '80',
                            unit: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _criteriaCard(),
                    const SizedBox(height: 20),
                    _streakCard(),
                    const SizedBox(height: 20),
                    _cta(),
                    const SizedBox(height: 20),
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

  Widget _banner() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: T.successBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded, size: 40, color: T.success),
        ),
        const SizedBox(height: 10),
        const Text(
          'Qualified!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: T.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'RSVP Reading · English · Level 3',
          style: TextStyle(fontSize: 14, color: T.textSecondary),
        ),
      ],
    );
  }

  Widget _heroMetric() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.primaryBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'EFFECTIVE WPM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: T.primary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '248',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: T.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(Icons.arrow_upward_rounded, size: 16, color: T.success),
                    SizedBox(width: 1),
                    Text(
                      '22',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: T.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criteriaCard() {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _criteriaRow('Speed ≥ 300 WPM', '310 WPM'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _criteriaRow('Comprehension ≥ 65%', '80%'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _criteriaRow('Text completed', '100%'),
        ],
      ),
    );
  }

  Widget _criteriaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: T.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: T.textPrimary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.success),
          ),
        ],
      ),
    );
  }

  Widget _streakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Successful sessions in a row',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: T.textPrimary),
              ),
              Text(
                '3 / 3',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: T.success),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _StreakSeg()),
              SizedBox(width: 6),
              Expanded(child: _StreakSeg()),
              SizedBox(width: 6),
              Expanded(child: _StreakSeg()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.trending_up, size: 16, color: T.primary),
              SizedBox(width: 6),
              Text(
                'Level 4 unlocked · target 400 WPM',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: T.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Continue training',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: T.onPrimary),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: T.onPrimary),
          ],
        ),
      ),
    );
  }

  Widget _secondaryRow() {
    return Row(
      children: const [
        Expanded(child: _OutlinedBtn(icon: Icons.refresh_rounded, label: 'Repeat')),
        SizedBox(width: 12),
        Expanded(child: _OutlinedBtn(icon: Icons.bar_chart_rounded, label: 'Progress')),
      ],
    );
  }
}

class _StreakSeg extends StatelessWidget {
  const _StreakSeg();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: T.success,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _OutlinedBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OutlinedBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.borderStrong, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: T.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
