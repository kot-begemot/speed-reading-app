import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

/// Static UI mock for the RSVP reading runtime screen.
class RsvpRuntimeScreen extends StatelessWidget {
  const RsvpRuntimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _targetChip(),
            Expanded(child: _focus()),
            _bottomBlock(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _circleIcon(
            fill: T.surfaceLow,
            icon: Icons.close_rounded,
            color: T.textSecondary,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'RSVP Reading · Level 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '00:38',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          _circleIcon(
            fill: T.primaryBg,
            icon: Icons.graphic_eq,
            color: T.primary,
          ),
        ],
      ),
    );
  }

  Widget _circleIcon({
    required Color fill,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _targetChip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: T.primaryBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.speed, size: 15, color: T.primary),
              SizedBox(width: 5),
              Text(
                'Target 300 WPM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 240, height: 2, color: T.guideLine),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'jour',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: T.textPrimary,
                ),
              ),
              Text(
                'n',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: T.centralLetter,
                ),
              ),
              Text(
                'ey',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: T.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(width: 240, height: 2, color: T.guideLine),
          const SizedBox(height: 32),
          _metronome(),
        ],
      ),
    );
  }

  Widget _metronome() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: i == 2 ? 10 : 7,
            height: i == 2 ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 2 ? T.primary : T.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bottomBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '142 / 320 words',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: T.textSecondary,
                ),
              ),
              Text(
                '305 WPM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: T.borderStrong,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.48,
                child: Container(color: T.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: T.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.replay_5,
                    size: 24,
                    color: T.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
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
                        Icon(
                          Icons.pause_rounded,
                          size: 22,
                          color: T.onPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pause',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: T.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
