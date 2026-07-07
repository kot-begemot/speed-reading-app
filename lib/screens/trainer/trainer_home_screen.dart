import 'package:flutter/material.dart';

import '../../widgets/trainer/trainer_bottom_nav.dart';
import 'trainer_tokens.dart';

/// Static UI mock: Trainer home screen.
class TrainerHomeScreen extends StatelessWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      bottomNavigationBar: const TrainerBottomNav(selectedIndex: 1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _topBar(),
            const SizedBox(height: 16),
            _levelCard(),
            const SizedBox(height: 16),
            _modeRow(),
            const SizedBox(height: 16),
            _sectionHeader('Quick drills', 'See all'),
            const SizedBox(height: 12),
            _quickDrills(),
            const SizedBox(height: 16),
            _sectionHeader('Recent sessions', 'History'),
            const SizedBox(height: 12),
            _recentSessions(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------
  Widget _topBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Trainer',
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 16, color: T.textSecondary),
              SizedBox(width: 6),
              Text(
                'English',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: T.textPrimary,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down, size: 18, color: T.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Level card
  // ---------------------------------------------------------------------------
  Widget _levelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: T.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Level 3 · Intermediate',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _glassTile(Icons.speed, 'Target WPM', '300'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _glassTile(
                    Icons.psychology, 'Min comprehension', '65%'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sessions to Level 4',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '2 / 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _segment(Colors.white),
              const SizedBox(width: 6),
              _segment(Colors.white),
              const SizedBox(width: 6),
              _segment(Colors.white.withValues(alpha: 0.24)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 16, color: T.gold),
              const SizedBox(width: 6),
              Text(
                'Personal best · 312 effective WPM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(Color color) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _glassTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode row
  // ---------------------------------------------------------------------------
  Widget _modeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gps_fixed, size: 26, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Training Program',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Guided path that levels you up',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: T.card(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fitness_center, size: 26, color: T.accentTeal),
                SizedBox(height: 12),
                Text(
                  'Skill Training',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: T.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Free drills for single skills',
                  style: TextStyle(fontSize: 12, color: T.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section header
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: T.textPrimary,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: T.primary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Quick drills grid
  // ---------------------------------------------------------------------------
  Widget _quickDrills() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _drillCard(Icons.grid_view, T.accentViolet,
                  'Schulte Table', '5×5 · best 38s'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _drillCard(Icons.location_on, T.accentTeal,
                  'Number Tracking', 'Find & follow digits'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _drillCard(Icons.visibility, T.warning,
                  'Peripheral Vision', 'Recognize at the edges'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _drillCard(Icons.bolt, T.primary, 'Flash Recognition',
                  '300ms · 3-word phrases'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _drillCard(IconData icon, Color accent, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: T.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: T.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: T.textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recent sessions
  // ---------------------------------------------------------------------------
  Widget _recentSessions() {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sessionRow(Icons.check, T.success, T.successBg, 'QUALIFIED',
              T.success, 'RSVP Reading', '310 wpm · 80%'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _sessionRow(Icons.close, T.error, T.dangerBg, 'FAILED', T.error,
              'Chunk Reading', '265 wpm · 60%'),
          const Divider(height: 1, thickness: 1, color: T.border),
          _sessionRow(Icons.grid_view, T.primary, T.surfaceLow, 'PRACTICE',
              T.textSecondary, 'Schulte 5×5', '41s · 1 error'),
        ],
      ),
    );
  }

  Widget _sessionRow(
    IconData icon,
    Color statusColor,
    Color badgeBg,
    String badge,
    Color badgeText,
    String title,
    String meta,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: T.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
