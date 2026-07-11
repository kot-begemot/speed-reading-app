import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static mock: the Exercise Intro / skill drill setup screen. UI only.
class ExerciseIntroScreen extends StatelessWidget {
  const ExerciseIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        backgroundColor: t.surface,
        surfaceTintColor: t.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.textPrimary),
          onPressed: () {},
        ),
        title: Text(
          'Skill drill',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _head(t),
            const SizedBox(height: 16),
            _goalCard(t),
            const SizedBox(height: 16),
            Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _settingsCard(t),
            const SizedBox(height: 16),
            _cta(),
            const SizedBox(height: 16),
            _practiceButton(t),
          ],
        ),
      ),
    );
  }

  Widget _head(TTheme t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: T.accentViolet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.grid_view, size: 30, color: T.accentViolet),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schulte Table',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Widen peripheral vision and speed up visual search',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalCard(TTheme t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.successBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.center_focus_strong, size: 22, color: T.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUCCESS GOAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: T.success,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Finish 5×5 under 40s · ≤2 errors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(TTheme t) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: t.card(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grid size',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _segmentedControl(t),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: t.border),
          const _ToggleRow(label: 'Countdown before start', on: true),
          Divider(height: 1, thickness: 1, color: t.border),
          const _ToggleRow(label: 'Sound', on: false),
          Divider(height: 1, thickness: 1, color: t.border),
          const _ToggleRow(label: 'Haptics', on: true),
        ],
      ),
    );
  }

  Widget _segmentedControl(TTheme t) {
    const labels = ['3×3', '4×4', '5×5', '6×6'];
    const selectedIndex = 2;
    return Container(
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border, width: 0.8),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Container(width: 0.8, height: 38, color: t.border),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: i == selectedIndex
                    ? T.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: i == selectedIndex
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: i == selectedIndex ? T.primary : t.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cta() {
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
                  Icon(Icons.play_arrow_rounded, size: 20, color: T.onPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: T.onPrimary,
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

  Widget _practiceButton(TTheme t) {
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Center(
            child: Text(
              'Practice without saving',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool on;

  const _ToggleRow({required this.label, required this.on});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          _PillSwitch(on: on),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  final bool on;

  const _PillSwitch({required this.on});

  @override
  Widget build(BuildContext context) {
    final t = T.of(context);
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? T.primary : t.borderStrong,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
