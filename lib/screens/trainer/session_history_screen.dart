import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/training_session.dart';
import '../../providers/progress_provider.dart';
import 'trainer_tokens.dart';

enum _Filter { all, qualified, failed, drills }

class SessionHistoryScreen extends ConsumerStatefulWidget {
  final String lang;
  const SessionHistoryScreen({super.key, required this.lang});

  @override
  ConsumerState<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  _Filter _filter = _Filter.all;

  bool _matchesFilter(TrainingSession session) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.qualified:
        return session.qualified;
      case _Filter.failed:
        return !session.qualified && session.finalWpm > 0; // reading sessions that failed
      case _Filter.drills:
        // Drill sessions have no finalWpm reading (only exercise results without RSVP)
        return session.exerciseResults.any((e) =>
            e.exerciseType == 'schulte' ||
            e.exerciseType == 'flash_recognition' ||
            e.exerciseType == 'number_tracking' ||
            e.exerciseType == 'peripheral_vision');
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(sessionHistoryProvider(widget.lang));

    // Apply filter across all groups
    final filtered = <String, List<TrainingSession>>{};
    for (final entry in grouped.entries) {
      final sessions = entry.value.where(_matchesFilter).toList();
      if (sessions.isNotEmpty) filtered[entry.key] = sessions;
    }

    final isEmpty = filtered.isEmpty;

    return Scaffold(
      backgroundColor: T.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AppBar(),
            _FilterChips(
              current: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: isEmpty
                  ? _EmptyState(filter: _filter)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final key = filtered.keys.elementAt(index);
                        final sessions = filtered[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _GroupLabel(label: key),
                            const SizedBox(height: 8),
                            _SessionGroup(sessions: sessions),
                            const SizedBox(height: 4),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: T.textPrimary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Session History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: T.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _Filter current;
  final void Function(_Filter) onSelect;
  const _FilterChips({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Filter.all: 'All',
      _Filter.qualified: 'Qualified',
      _Filter.failed: 'Failed',
      _Filter.drills: 'Drills',
    };
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: _Filter.values.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                decoration: BoxDecoration(
                  color: selected ? T.primary : T.surfaceLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: selected ? null : Border.all(color: T.border, width: 0.8),
                ),
                child: Text(
                  labels[f]!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? T.onPrimary : T.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group label + session card group
// ─────────────────────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: T.textSecondary,
      ),
    );
  }
}

class _SessionGroup extends StatelessWidget {
  final List<TrainingSession> sessions;
  const _SessionGroup({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: T.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: T.border),
            _SessionRow(session: sessions[i]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session row
// ─────────────────────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final TrainingSession session;
  const _SessionRow({required this.session});

  (IconData, Color) get _iconAndColor {
    final hasReading = session.finalWpm > 0;
    final hasBaseline = session.exerciseResults.any((e) => e.exerciseType == 'baseline_reading');
    if (hasBaseline) return (Icons.assessment_rounded, T.accentTeal);
    if (hasReading) return (Icons.menu_book_rounded, T.primary);
    final drillType = session.exerciseResults.isNotEmpty ? session.exerciseResults.first.exerciseType : '';
    switch (drillType) {
      case 'schulte':
        return (Icons.grid_view_rounded, T.accentViolet);
      case 'flash_recognition':
        return (Icons.bolt_rounded, T.primary);
      case 'number_tracking':
        return (Icons.location_on_rounded, T.accentTeal);
      case 'peripheral_vision':
        return (Icons.visibility_rounded, T.accentViolet);
      default:
        return (Icons.fitness_center_rounded, T.textSecondary);
    }
  }

  String get _title {
    final hasReading = session.finalWpm > 0;
    final hasBaseline = session.exerciseResults.any((e) => e.exerciseType == 'baseline_reading');
    if (hasBaseline) return 'Baseline Assessment';
    if (hasReading) return 'Training Session';
    final drillType = session.exerciseResults.isNotEmpty ? session.exerciseResults.first.exerciseType : '';
    switch (drillType) {
      case 'schulte':
        return 'Schulte Table';
      case 'flash_recognition':
        return 'Flash Recognition';
      case 'number_tracking':
        return 'Number Tracking';
      case 'peripheral_vision':
        return 'Peripheral Vision';
      default:
        return 'Practice Session';
    }
  }

  String get _meta {
    if (session.finalWpm > 0) {
      return '${session.finalWpm} wpm · ${session.comprehensionPercent}% · eff ${session.effectiveWpm} · Lv${session.level}';
    }
    final results = session.exerciseResults;
    if (results.isEmpty) return 'No data';
    final r = results.first;
    if (r.accuracyPercent != null) {
      return '${r.durationSeconds}s · ${r.accuracyPercent!.round()}% accuracy';
    }
    return '${r.durationSeconds}s · Lv${r.difficulty}';
  }

  String get _time {
    final t = session.startedAt;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: T.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(qualified: session.qualified, hasReading: session.finalWpm > 0),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _meta,
                        style: const TextStyle(fontSize: 12, color: T.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _time,
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
  final bool qualified;
  final bool hasReading;
  const _StatusBadge({required this.qualified, required this.hasReading});

  @override
  Widget build(BuildContext context) {
    if (!hasReading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
        decoration: BoxDecoration(color: T.surfaceLow, borderRadius: BorderRadius.circular(6)),
        child: const Text('DRILL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: T.textSecondary)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
      decoration: BoxDecoration(
        color: qualified ? T.successBg : T.dangerBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        qualified ? 'QUALIFIED' : 'FAILED',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: qualified ? T.success : T.error,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = filter == _Filter.all
        ? 'No sessions yet.\nComplete a training session to see history.'
        : 'No ${filter.name} sessions found\nfor this filter.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter == _Filter.all ? Icons.history_rounded : Icons.filter_list_off_rounded,
              size: 56,
              color: T.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: T.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
