import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static mock: the Training Program plan screen. UI only — no logic.
class TrainingProgramPlanScreen extends StatelessWidget {
  const TrainingProgramPlanScreen({super.key});

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
          'Training Program',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: T.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _goalCard(),
            const SizedBox(height: 16),
            const Text(
              'This session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: T.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: const [
                _Step(
                  state: _StepState.done,
                  icon: Icons.check,
                  kicker: 'SKILL WARM-UP',
                  title: 'Schulte Table · 5×5',
                ),
                SizedBox(height: 10),
                _Step(
                  state: _StepState.done,
                  icon: Icons.check,
                  kicker: 'RECOGNITION DRILL',
                  title: 'Flash Recognition · 300ms',
                ),
                SizedBox(height: 10),
                _Step(
                  state: _StepState.current,
                  icon: Icons.menu_book,
                  kicker: 'TEXT EXERCISE',
                  title: 'RSVP Reading · 300 WPM',
                ),
                SizedBox(height: 10),
                _Step(
                  state: _StepState.locked,
                  icon: Icons.quiz,
                  kicker: 'COMPREHENSION TEST',
                  title: '5 questions',
                ),
                SizedBox(height: 10),
                _Step(
                  state: _StepState.locked,
                  icon: Icons.flag,
                  kicker: 'LEVEL CHECKPOINT',
                  title: 'Qualify to advance',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _primaryCta(),
            const SizedBox(height: 16),
            _secondaryButton(),
          ],
        ),
      ),
    );
  }

  Widget _goalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: T.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENGLISH · LEVEL 3',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: T.primary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Goal: 300 WPM · ≥65%',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: T.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '2 / 3',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: T.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _barSeg(T.success),
              const SizedBox(width: 6),
              _barSeg(T.success),
              const SizedBox(width: 6),
              _barSeg(T.borderStrong),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1 more qualified session to reach Level 4',
            style: TextStyle(fontSize: 12, color: T.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _barSeg(Color color) => Expanded(
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _primaryCta() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: T.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start next step',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: T.onPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.play_arrow_rounded, size: 20, color: T.onPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton() {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: T.borderStrong, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 18, color: T.primary),
                  SizedBox(width: 8),
                  Text(
                    'Practice weak skill',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: T.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepState { done, current, locked }

class _Step extends StatelessWidget {
  final _StepState state;
  final IconData icon;
  final String kicker;
  final String title;

  const _Step({
    required this.state,
    required this.icon,
    required this.kicker,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor = switch (state) {
      _StepState.done => T.success,
      _StepState.current => T.primary,
      _StepState.locked => T.surfaceLow,
    };
    final Color iconColor =
        state == _StepState.locked ? T.textSecondary : T.onPrimary;
    final Color kickerColor = switch (state) {
      _StepState.current => T.primary,
      _StepState.locked => T.textSecondary,
      _StepState.done => T.textSecondary,
    };

    final BoxDecoration decoration = state == _StepState.current
        ? BoxDecoration(
            color: T.primaryBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.primary, width: 1.2),
          )
        : T.card(radius: 14);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: kickerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (state == _StepState.done) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle, size: 20, color: T.success),
          ] else if (state == _StepState.current) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: T.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: T.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (state == _StepState.locked) {
      return Opacity(opacity: 0.6, child: card);
    }
    return card;
  }
}
