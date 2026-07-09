import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/baseline_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/trainer/metric_tile.dart';
import 'session_history_screen.dart';
import 'skill_training_screen.dart';
import 'trainer_tokens.dart';

class ProgressDashboardScreen extends ConsumerStatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  ConsumerState<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends ConsumerState<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _chartAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chartAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    final lang = ref.watch(activeTrainerLanguageProvider);
    final period = ref.watch(activePeriodProvider);
    final statsKey = (lang: lang, period: period);
    final stats = ref.watch(progressStatsProvider(statsKey));
    final chartData = ref.watch(chartDataProvider(statsKey));
    final weakSkills = ref.watch(weakSkillsProvider(lang));

    // Re-animate chart when period changes
    ref.listen(activePeriodProvider, (_, __) {
      _animController.forward(from: 0);
    });

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(lang: lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _PeriodSelector(period: period),
                    const SizedBox(height: 16),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 16),
                    _StreakCard(stats: stats),
                    const SizedBox(height: 16),
                    _ChartCard(chartData: chartData, chartAnim: _chartAnim, period: period),
                    const SizedBox(height: 16),
                    if (weakSkills.isNotEmpty) ...[
                      _WeakSkillsCard(weakSkills: weakSkills),
                      const SizedBox(height: 16),
                    ],
                    _HistoryButton(lang: lang),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String lang;
  const _Header({required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = T.of(context);
    final langLabel = lang == 'en' ? 'English' : lang == 'ru' ? 'Russian' : lang.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Progress',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: t.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () {
              // Toggle language
              final next = lang == 'en' ? 'ru' : 'en';
              ref.read(activeTrainerLanguageProvider.notifier).setLanguage(next);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: t.surfaceLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.border, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16, color: t.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    langLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Period selector
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  final StatsPeriod period;
  const _PeriodSelector({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = T.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (int i = 0; i < StatsPeriod.values.length; i++) ...[
            if (i > 0)
              Container(width: 0.8, height: 38, color: t.border),
            Expanded(
              child: GestureDetector(
                onTap: () => ref.read(activePeriodProvider.notifier).select(StatsPeriod.values[i]),
                child: _Segment(
                  label: StatsPeriod.values[i].label,
                  selected: period == StatsPeriod.values[i],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  const _Segment({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 38,
      alignment: Alignment.center,
      color: selected ? T.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? T.primary : t.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final ProgressStats stats;
  const _StatsGrid({required this.stats});

  String _fmtDelta(int? delta) {
    if (delta == null) return '';
    if (delta > 0) return '+$delta';
    return '$delta';
  }

  IconData _deltaIcon(int? delta) {
    if (delta == null || delta == 0) return Icons.remove;
    return delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    final secondaryColor = t.textSecondary;

    Color deltaColorWithSecondary(int? delta) {
      if (delta == null || delta == 0) return secondaryColor;
      return delta > 0 ? T.success : T.error;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'AVG WPM',
                value: stats.avgWpm > 0 ? '${stats.avgWpm}' : '—',
                unit: stats.avgWpm > 0 ? 'wpm' : '',
                delta: stats.wpmDelta != null && stats.wpmDelta != 0
                    ? _fmtDelta(stats.wpmDelta)
                    : null,
                deltaColor: deltaColorWithSecondary(stats.wpmDelta),
                deltaIcon: _deltaIcon(stats.wpmDelta),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'BEST EFF. WPM',
                value: stats.bestEffWpm > 0 ? '${stats.bestEffWpm}' : '—',
                unit: stats.bestEffWpm > 0 ? 'wpm' : '',
                delta: stats.bestEffWpm > 0 ? 'Personal best' : null,
                deltaColor: T.gold,
                deltaIcon: Icons.emoji_events_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'AVG COMPREHENSION',
                value: stats.avgComprehension > 0 ? '${stats.avgComprehension}' : '—',
                unit: stats.avgComprehension > 0 ? '%' : '',
                delta: stats.comprDelta != null && stats.comprDelta != 0
                    ? _fmtDelta(stats.comprDelta)
                    : null,
                deltaColor: deltaColorWithSecondary(stats.comprDelta),
                deltaIcon: _deltaIcon(stats.comprDelta),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'SESSIONS',
                value: '${stats.totalSessions}',
                unit: 'done',
                delta: stats.qualifiedSessions > 0 ? '${stats.qualifiedSessions} qualified' : null,
                deltaColor: T.success,
                deltaIcon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak card
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final ProgressStats stats;
  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.card(),
      child: Row(
        children: [
          // Current streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STREAK',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: t.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stats.currentStreak}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: t.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'in a row',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: t.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 48, color: t.border),
          const SizedBox(width: 16),
          // Best streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST STREAK',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: t.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 28, color: T.gold),
                    const SizedBox(width: 6),
                    Text(
                      '${stats.bestStreak}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: T.gold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart card
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<ChartPoint> chartData;
  final Animation<double> chartAnim;
  final StatsPeriod period;
  const _ChartCard({required this.chartData, required this.chartAnim, required this.period});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    final hasData = chartData.any((p) => p.hasData);
    final maxWpm = chartData.isEmpty ? 1.0 : chartData.map((p) => p.effWpm).reduce(math.max).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Effective WPM',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t.textPrimary),
              ),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: T.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    period == StatsPeriod.week ? 'per day' : period == StatsPeriod.month ? 'per 5 days' : 'per month',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No data yet for this period',
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: chartAnim,
                builder: (_, __) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < chartData.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _ChartBar(
                          point: chartData[i],
                          maxWpm: maxWpm,
                          progress: chartAnim.value,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final ChartPoint point;
  final double maxWpm;
  final double progress;
  const _ChartBar({required this.point, required this.maxWpm, required this.progress});

  static const double _valueLabelHeight = 15;
  static const double _bottomLabelHeight = 15;
  static const double _spacing = 6;

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    final heightFraction = point.hasData ? (point.effWpm / maxWpm).clamp(0.04, 1.0) : 0.03;
    final isToday = point.isToday;

    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = _bottomLabelHeight + _spacing + (point.hasData ? _valueLabelHeight : 0);
        final maxBarHeight = (constraints.maxHeight - reserved).clamp(0.0, double.infinity);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (point.hasData)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${point.effWpm.round()}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isToday ? T.primary : t.textSecondary,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              height: maxBarHeight * heightFraction * progress,
              decoration: BoxDecoration(
                gradient: point.hasData
                    ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isToday
                            ? [T.primary, T.accentViolet]
                            : [T.primary.withValues(alpha: 0.7), T.accentViolet.withValues(alpha: 0.7)],
                      )
                    : null,
                color: point.hasData ? null : t.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: _spacing),
            Text(
              point.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                color: isToday ? T.primary : t.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weak skills card
// ─────────────────────────────────────────────────────────────────────────────

class _WeakSkillsCard extends StatelessWidget {
  final List<WeakSkill> weakSkills;
  const _WeakSkillsCard({required this.weakSkills});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: T.warning),
              const SizedBox(width: 8),
              Text(
                'Areas to improve',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < weakSkills.length; i++) ...[
            if (i > 0) ...[
              Divider(height: 20, thickness: 0.8, color: t.border),
            ],
            _WeakSkillRow(skill: weakSkills[i]),
          ],
        ],
      ),
    );
  }
}

class _WeakSkillRow extends StatelessWidget {
  final WeakSkill skill;
  const _WeakSkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Row(
      children: [
        // Score ring indicator
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: skill.score / 100,
                  strokeWidth: 4,
                  backgroundColor: t.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    skill.score < 50 ? T.error : T.warning,
                  ),
                ),
              ),
              Text(
                '${skill.score.round()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.displayName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                skill.detail,
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SkillTrainingScreen(exerciseType: skill.exerciseType),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
            decoration: BoxDecoration(
              color: t.primaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Train',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View History button
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryButton extends StatelessWidget {
  final String lang;
  const _HistoryButton({required this.lang});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SessionHistoryScreen(lang: lang)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: t.surfaceLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border, width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 18, color: T.primary),
            SizedBox(width: 8),
            Text(
              'View full session history',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.primary),
            ),
          ],
        ),
      ),
    );
  }
}
