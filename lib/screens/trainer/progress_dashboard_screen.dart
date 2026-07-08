import 'package:flutter/material.dart';

import '../../widgets/trainer/metric_tile.dart';
import '../../widgets/trainer/trainer_bottom_nav.dart';
import 'trainer_tokens.dart';

/// Static UI mock: progress dashboard screen.
class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  static const _bars = <(double, String)>[
    (110, 'M'),
    (135, 'T'),
    (95, 'W'),
    (150, 'T'),
    (130, 'F'),
    (175, 'S'),
    (160, 'S'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      bottomNavigationBar: const TrainerBottomNav(selectedIndex: 2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: T.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                    decoration: BoxDecoration(
                      color: T.surfaceLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: T.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.language, size: 16, color: T.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'English',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: T.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _segmentedControl(),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: MetricTile(
                            label: 'AVG WPM',
                            value: '288',
                            unit: 'wpm',
                            delta: '+18',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'BEST EFF. WPM',
                            value: '312',
                            unit: 'wpm',
                            delta: 'PB',
                            deltaColor: T.gold,
                            deltaIcon: Icons.emoji_events_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: MetricTile(
                            label: 'AVG COMPREHENSION',
                            value: '76',
                            unit: '%',
                            delta: '+4',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'SESSIONS',
                            value: '14',
                            unit: 'done',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _chartCard(),
                    const SizedBox(height: 16),
                    _weakSkillsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: T.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: const [
          Expanded(child: _Segment(label: '7 days', selected: true)),
          _SegDivider(),
          Expanded(child: _Segment(label: '30 days', selected: false)),
          _SegDivider(),
          Expanded(child: _Segment(label: 'All time', selected: false)),
        ],
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Effective WPM',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: T.textPrimary),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: T.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'per day',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: T.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _ChartBar(value: _bars[i].$1, label: _bars[i].$2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weakSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weak skills',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: T.textPrimary),
          ),
          const SizedBox(height: 12),
          _weakRow('Visual search', 'Schulte avg 48s'),
          const SizedBox(height: 12),
          _weakRow('Peripheral span', '72% at 8 pos'),
        ],
      ),
    );
  }

  Widget _weakRow(String name, String sub) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: T.warning, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: T.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 12, color: T.textSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: T.primaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Train',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: T.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  const _Segment({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      color: selected ? T.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? T.primary : T.textSecondary,
        ),
      ),
    );
  }
}

class _SegDivider extends StatelessWidget {
  const _SegDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 0.8, height: 38, color: T.border);
  }
}

class _ChartBar extends StatelessWidget {
  final double value;
  final String label;
  const _ChartBar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          height: 120 * value / 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [T.primary, T.accentViolet],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: T.textSecondary),
        ),
      ],
    );
  }
}
