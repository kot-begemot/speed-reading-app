import 'package:flutter/material.dart';

import 'trainer_tokens.dart';

enum _Status { qualified, failed, practice }

class _Session {
  final IconData icon;
  final Color accent;
  final String title;
  final String meta;
  final String time;
  final _Status status;
  const _Session(this.icon, this.accent, this.title, this.meta, this.time, this.status);
}

/// Static UI mock: session history screen.
class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  static const _today = <_Session>[
    _Session(Icons.menu_book, T.primary, 'RSVP Reading', '310 wpm · 80% · eff 248 · 2m', '09:41', _Status.qualified),
    _Session(Icons.grid_view, T.accentViolet, 'Schulte 5×5', '41s · 1 error · 1m', '09:38', _Status.practice),
    _Session(Icons.bolt, T.primary, 'Flash Recognition', '83% · 300ms · 2m', '09:35', _Status.practice),
  ];

  static const _yesterday = <_Session>[
    _Session(Icons.view_column, T.accentTeal, 'Chunk Reading', '265 wpm · 60% · eff 159 · 3m', '20:12', _Status.failed),
    _Session(Icons.menu_book, T.primary, 'RSVP Reading', '300 wpm · 80% · eff 240 · 2m', '20:05', _Status.qualified),
    _Session(Icons.location_on, T.accentTeal, 'Number Tracking', 'Level 3 · 100% · 2m', '19:58', _Status.practice),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _appBar(),
            _chips(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _groupLabel('TODAY'),
                    const SizedBox(height: 8),
                    _sessionCard(_today),
                    const SizedBox(height: 8),
                    _groupLabel('YESTERDAY'),
                    const SizedBox(height: 8),
                    _sessionCard(_yesterday),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: T.textPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: T.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.filter_list_rounded, size: 22, color: T.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          _Chip(label: 'All', selected: true),
          SizedBox(width: 8),
          _Chip(label: 'Qualified', selected: false),
          SizedBox(width: 8),
          _Chip(label: 'Skills', selected: false),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: T.textSecondary,
      ),
    );
  }

  Widget _sessionCard(List<_Session> sessions) {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: T.border),
            _SessionRow(session: sessions[i]),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? T.primary : T.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: T.border, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? T.onPrimary : T.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final _Session session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: session.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(session.icon, size: 20, color: session.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.textPrimary),
                    ),
                    _StatusBadge(status: session.status),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.meta,
                        style: const TextStyle(fontSize: 12, color: T.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      session.time,
                      style: TextStyle(fontSize: 11, color: T.textSecondary.withValues(alpha: 0.6)),
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

class _StatusBadge extends StatelessWidget {
  final _Status status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color fill;
    late final Color text;
    late final String label;
    switch (status) {
      case _Status.qualified:
        fill = T.successBg;
        text = T.success;
        label = 'QUALIFIED';
        break;
      case _Status.failed:
        fill = T.dangerBg;
        text = T.error;
        label = 'FAILED';
        break;
      case _Status.practice:
        fill = T.surfaceLow;
        text = T.textSecondary;
        label = 'PRACTICE';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
