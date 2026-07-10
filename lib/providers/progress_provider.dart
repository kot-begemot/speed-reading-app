import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/training_session.dart';
import 'baseline_provider.dart';
import 'books_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Period enum
// ─────────────────────────────────────────────────────────────────────────────

enum StatsPeriod { week, month, allTime }

extension StatsPeriodX on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.week:
        return '7 days';
      case StatsPeriod.month:
        return '30 days';
      case StatsPeriod.allTime:
        return 'All time';
    }
  }

  DateTime? get cutoff {
    final now = DateTime.now();
    switch (this) {
      case StatsPeriod.week:
        return now.subtract(const Duration(days: 7));
      case StatsPeriod.month:
        return now.subtract(const Duration(days: 30));
      case StatsPeriod.allTime:
        return null;
    }
  }

  DateTime? get previousCutoff {
    final now = DateTime.now();
    switch (this) {
      case StatsPeriod.week:
        return now.subtract(const Duration(days: 14));
      case StatsPeriod.month:
        return now.subtract(const Duration(days: 60));
      case StatsPeriod.allTime:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class ProgressStats {
  final int avgWpm;
  final int bestEffWpm;
  final int avgComprehension;
  final int totalSessions;
  final int qualifiedSessions;
  final int currentStreak;
  final int bestStreak;
  final int? wpmDelta;
  final int? comprDelta;

  const ProgressStats({
    required this.avgWpm,
    required this.bestEffWpm,
    required this.avgComprehension,
    required this.totalSessions,
    required this.qualifiedSessions,
    required this.currentStreak,
    required this.bestStreak,
    this.wpmDelta,
    this.comprDelta,
  });

  static const empty = ProgressStats(
    avgWpm: 0,
    bestEffWpm: 0,
    avgComprehension: 0,
    totalSessions: 0,
    qualifiedSessions: 0,
    currentStreak: 0,
    bestStreak: 0,
  );

  ProgressStats copyWith({
    int? avgWpm,
    int? bestEffWpm,
    int? avgComprehension,
    int? totalSessions,
    int? qualifiedSessions,
    int? currentStreak,
    int? bestStreak,
    int? wpmDelta,
    int? comprDelta,
  }) {
    return ProgressStats(
      avgWpm: avgWpm ?? this.avgWpm,
      bestEffWpm: bestEffWpm ?? this.bestEffWpm,
      avgComprehension: avgComprehension ?? this.avgComprehension,
      totalSessions: totalSessions ?? this.totalSessions,
      qualifiedSessions: qualifiedSessions ?? this.qualifiedSessions,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      wpmDelta: wpmDelta ?? this.wpmDelta,
      comprDelta: comprDelta ?? this.comprDelta,
    );
  }
}

class ChartPoint {
  final String label;
  final double effWpm;
  final bool isToday;
  final bool hasData;

  const ChartPoint({
    required this.label,
    required this.effWpm,
    this.isToday = false,
    this.hasData = false,
  });
}

class WeakSkill {
  final String exerciseType;
  final String displayName;
  final String detail;
  final double score;

  const WeakSkill({
    required this.exerciseType,
    required this.displayName,
    required this.detail,
    required this.score,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Computation helpers
// ─────────────────────────────────────────────────────────────────────────────

List<TrainingSession> _filterSessions(
  List<TrainingSession> all,
  DateTime? from,
  DateTime? to,
) {
  return all.where((s) {
    if (from != null && s.startedAt.isBefore(from)) return false;
    if (to != null && s.startedAt.isAfter(to)) return false;
    return true;
  }).toList();
}

ProgressStats _computeStats(
  List<TrainingSession> current,
  List<TrainingSession> previous,
  TrainingSession? bestEverSession,
) {
  if (current.isEmpty) {
    return ProgressStats.empty.copyWith(
      bestEffWpm: bestEverSession?.effectiveWpm ?? 0,
    );
  }

  final reading = current.where((s) => s.finalWpm > 0).toList();

  final avgWpm = reading.isEmpty
      ? 0
      : (reading.map((s) => s.finalWpm).reduce((a, b) => a + b) / reading.length).round();

  final avgCompr = reading.isEmpty
      ? 0
      : (reading.map((s) => s.comprehensionPercent).reduce((a, b) => a + b) / reading.length).round();

  final bestEff = current
      .map((s) => s.effectiveWpm)
      .fold(bestEverSession?.effectiveWpm ?? 0, (prev, e) => e > prev ? e : prev);

  final qualified = current.where((s) => s.qualified).length;

  final sorted = List<TrainingSession>.from(current)
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  int maxStreak = 0;
  int streak = 0;
  for (final s in sorted) {
    if (s.qualified) {
      streak++;
      if (streak > maxStreak) maxStreak = streak;
    } else {
      streak = 0;
    }
  }

  int curStreak = 0;
  for (final s in sorted.reversed) {
    if (s.qualified) {
      curStreak++;
    } else {
      break;
    }
  }

  int? wpmDelta;
  int? comprDelta;
  if (previous.isNotEmpty) {
    final prevReading = previous.where((s) => s.finalWpm > 0).toList();
    if (prevReading.isNotEmpty) {
      final prevAvgWpm =
          (prevReading.map((s) => s.finalWpm).reduce((a, b) => a + b) / prevReading.length).round();
      final prevAvgCompr = (prevReading.map((s) => s.comprehensionPercent).reduce((a, b) => a + b) /
              prevReading.length)
          .round();
      wpmDelta = avgWpm - prevAvgWpm;
      comprDelta = avgCompr - prevAvgCompr;
    }
  }

  return ProgressStats(
    avgWpm: avgWpm,
    bestEffWpm: bestEff,
    avgComprehension: avgCompr,
    totalSessions: current.length,
    qualifiedSessions: qualified,
    currentStreak: curStreak,
    bestStreak: maxStreak,
    wpmDelta: wpmDelta,
    comprDelta: comprDelta,
  );
}

List<ChartPoint> _computeChart(List<TrainingSession> sessions, StatsPeriod period) {
  final now = DateTime.now();

  if (period == StatsPeriod.week) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final points = <ChartPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final daySessions = sessions
          .where((s) => s.startedAt.isAfter(dayStart) && s.startedAt.isBefore(dayEnd) && s.effectiveWpm > 0)
          .toList();
      final avgEff = daySessions.isEmpty
          ? 0.0
          : daySessions.map((s) => s.effectiveWpm).reduce((a, b) => a + b) / daySessions.length;
      points.add(ChartPoint(
        label: dayLabels[day.weekday - 1],
        effWpm: avgEff,
        isToday: i == 0,
        hasData: daySessions.isNotEmpty,
      ));
    }
    return points;
  } else if (period == StatsPeriod.month) {
    final points = <ChartPoint>[];
    for (int bucket = 5; bucket >= 0; bucket--) {
      final bucketEnd = now.subtract(Duration(days: bucket * 5));
      final bucketStart = bucketEnd.subtract(const Duration(days: 5));
      final bucketSessions = sessions
          .where((s) => s.startedAt.isAfter(bucketStart) && s.startedAt.isBefore(bucketEnd) && s.effectiveWpm > 0)
          .toList();
      final avgEff = bucketSessions.isEmpty
          ? 0.0
          : bucketSessions.map((s) => s.effectiveWpm).reduce((a, b) => a + b) / bucketSessions.length;
      points.add(ChartPoint(
        label: '${bucketStart.day}/${bucketStart.month}',
        effWpm: avgEff,
        isToday: bucket == 0,
        hasData: bucketSessions.isNotEmpty,
      ));
    }
    return points;
  } else {
    if (sessions.isEmpty) return [];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final grouped = <String, List<TrainingSession>>{};
    for (final s in sessions) {
      if (s.effectiveWpm <= 0) continue;
      final key = '${s.startedAt.year}-${s.startedAt.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    final keep = sortedKeys.length > 12 ? sortedKeys.sublist(sortedKeys.length - 12) : sortedKeys;
    return keep.map((key) {
      final parts = key.split('-');
      final month = int.parse(parts[1]);
      final s = grouped[key]!;
      final avgEff = s.map((x) => x.effectiveWpm).reduce((a, b) => a + b) / s.length;
      final isCurrentMonth = now.year.toString() == parts[0] && now.month == month;
      return ChartPoint(
        label: months[month],
        effWpm: avgEff,
        isToday: isCurrentMonth,
        hasData: true,
      );
    }).toList();
  }
}

List<WeakSkill> _computeWeakSkills(List<TrainingSession> sessions) {
  final exerciseScores = <String, List<double>>{};
  for (final session in sessions) {
    for (final result in session.exerciseResults) {
      if (!result.completed) continue;
      double? score;
      if (result.accuracyPercent != null) {
        score = result.accuracyPercent!;
      } else if (result.comprehensionPercent != null) {
        score = result.comprehensionPercent!.toDouble();
      }
      if (score != null) {
        exerciseScores.putIfAbsent(result.exerciseType, () => []).add(score);
      }
    }
  }

  final skills = <WeakSkill>[];
  for (final entry in exerciseScores.entries) {
    if (entry.value.isEmpty) continue;
    final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
    skills.add(WeakSkill(
      exerciseType: entry.key,
      displayName: _exerciseDisplayName(entry.key),
      detail: _exerciseWeakDetail(entry.key, avg, entry.value.length),
      score: avg,
    ));
  }

  skills.sort((a, b) => a.score.compareTo(b.score));
  return skills.where((s) => s.score < 80).take(3).toList();
}

String _exerciseDisplayName(String type) {
  switch (type) {
    case 'schulte':
      return 'Visual Search';
    case 'flash_recognition':
      return 'Flash Recognition';
    case 'number_tracking':
      return 'Number Tracking';
    case 'peripheral_vision':
      return 'Peripheral Vision';
    case 'rsvp_reading':
      return 'RSVP Reading';
    case 'baseline_reading':
      return 'Baseline Reading';
    default:
      return type;
  }
}

String _exerciseWeakDetail(String type, double avg, int count) {
  final avgStr = avg.round().toString();
  switch (type) {
    case 'schulte':
      return 'Avg accuracy $avgStr% · $count drills';
    case 'flash_recognition':
      return 'Avg accuracy $avgStr% · needs improvement';
    case 'number_tracking':
      return 'Avg $avgStr% over $count sessions';
    case 'peripheral_vision':
      return 'Avg recognition $avgStr% at wide positions';
    case 'rsvp_reading':
      return 'Avg comprehension $avgStr%';
    default:
      return 'Avg score $avgStr%';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-drill best/last stats (used by the Skill Training list)
// ─────────────────────────────────────────────────────────────────────────────

class DrillStat {
  final String? best;
  final String? last;
  final bool hasData;

  const DrillStat({this.best, this.last, this.hasData = false});

  static const empty = DrillStat();
}

String _formatDrillResult(String exerciseType, ExerciseResult r) {
  switch (exerciseType) {
    case 'schulte':
      return '5×5 · ${r.durationSeconds}s';
    case 'schulte_gorbov':
      return '7×7 · ${r.durationSeconds}s';
    case 'number_tracking':
      return '${r.accuracyPercent?.round() ?? 0}% · ${r.durationSeconds}s';
    case 'peripheral_vision':
      return '${r.accuracyPercent?.round() ?? 0}% · 8 pos';
    case 'flash_recognition':
      return '${r.accuracyPercent?.round() ?? 0}% · ${r.mistakes ?? 0} err';
    case 'chunk_reading':
      return '${r.accuracyPercent?.round() ?? 0} WPM';
    case 'pyramid_expansion':
      return '${r.accuracyPercent?.round() ?? 0}% · ${r.durationSeconds}s';
    case 'word_match':
      return '${r.accuracyPercent?.round() ?? 0}% · ${r.durationSeconds}s';
    default:
      return '${r.accuracyPercent?.round() ?? 0}%';
  }
}

DrillStat _computeDrillStat(List<TrainingSession> sessions, String exerciseType) {
  final entries = <(DateTime, ExerciseResult)>[];
  for (final s in sessions) {
    for (final r in s.exerciseResults) {
      if (r.exerciseType == exerciseType && r.completed) {
        entries.add((s.startedAt, r));
      }
    }
  }
  if (entries.isEmpty) return DrillStat.empty;

  entries.sort((a, b) => b.$1.compareTo(a.$1));
  final last = entries.first.$2;

  final best = (exerciseType == 'schulte' || exerciseType == 'schulte_gorbov')
      ? entries.map((e) => e.$2).reduce((a, b) => a.durationSeconds <= b.durationSeconds ? a : b)
      : entries.map((e) => e.$2).reduce(
          (a, b) => (a.accuracyPercent ?? 0) >= (b.accuracyPercent ?? 0) ? a : b);

  return DrillStat(
    best: _formatDrillResult(exerciseType, best),
    last: _formatDrillResult(exerciseType, last),
    hasData: true,
  );
}

typedef DrillStatKey = ({String lang, String exerciseType});

final drillStatProvider = Provider.family<DrillStat, DrillStatKey>((ref, key) {
  final sessions = ref.watch(allSessionsForLangProvider(key.lang));
  return _computeDrillStat(sessions, key.exerciseType);
});

/// Persists the result of a standalone skill drill (Schulte, Number Tracking,
/// Peripheral Vision, Flash Recognition) as a [TrainingSession], regardless of
/// which screen launched the drill — this is the single write path so every
/// screen reading [drillStatProvider] / [weakSkillsProvider] sees the same data.
Future<void> logDrillResult(
  WidgetRef ref, {
  required String languageCode,
  required String exerciseType,
  required int accuracy,
  required int errors,
  required int durationSeconds,
}) async {
  final storage = ref.read(storageServiceProvider);
  final profile = await ref.read(trainerProfileProvider.future);
  final level = profile.languageProfiles[languageCode]?.currentLevel ?? 1;
  final session = TrainingSession(
    id: const Uuid().v4(),
    languageCode: languageCode,
    startedAt: DateTime.now().subtract(Duration(seconds: durationSeconds)),
    completedAt: DateTime.now(),
    level: level,
    exerciseResults: [
      ExerciseResult(
        exerciseType: exerciseType,
        durationSeconds: durationSeconds,
        difficulty: level,
        accuracyPercent: accuracy.toDouble(),
        mistakes: errors,
        completed: true,
      ),
    ],
  );
  await storage.saveTrainingSession(session);
  ref.invalidate(allSessionsForLangProvider(languageCode));
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

typedef ProgressKey = ({String lang, StatsPeriod period});

final allSessionsForLangProvider = Provider.family<List<TrainingSession>, String>((ref, lang) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAllSessions(languageCode: lang);
});

final progressStatsProvider = Provider.family<ProgressStats, ProgressKey>((ref, key) {
  final allSessions = ref.watch(allSessionsForLangProvider(key.lang));
  final cutoff = key.period.cutoff;
  final prevCutoff = key.period.previousCutoff;
  final now = DateTime.now();
  final current = cutoff == null ? allSessions : _filterSessions(allSessions, cutoff, now);
  final previous = (prevCutoff != null && cutoff != null)
      ? _filterSessions(allSessions, prevCutoff, cutoff)
      : <TrainingSession>[];
  final bestEverSession = allSessions.isEmpty
      ? null
      : allSessions.reduce((a, b) => a.effectiveWpm >= b.effectiveWpm ? a : b);
  return _computeStats(current, previous, bestEverSession);
});

final chartDataProvider = Provider.family<List<ChartPoint>, ProgressKey>((ref, key) {
  final allSessions = ref.watch(allSessionsForLangProvider(key.lang));
  final cutoff = key.period.cutoff;
  final now = DateTime.now();
  final sessions = cutoff == null ? allSessions : _filterSessions(allSessions, cutoff, now);
  return _computeChart(sessions, key.period);
});

final weakSkillsProvider = Provider.family<List<WeakSkill>, String>((ref, lang) {
  final allSessions = ref.watch(allSessionsForLangProvider(lang));
  return _computeWeakSkills(allSessions.take(30).toList());
});

final sessionHistoryProvider = Provider.family<Map<String, List<TrainingSession>>, String>((ref, lang) {
  final allSessions = ref.watch(allSessionsForLangProvider(lang));
  final grouped = <String, List<TrainingSession>>{};
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  const monthAbbrev = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  for (final session in allSessions) {
    final sessionDay = DateTime(session.startedAt.year, session.startedAt.month, session.startedAt.day);
    final String label;
    if (sessionDay == today) {
      label = 'TODAY';
    } else if (sessionDay == yesterday) {
      label = 'YESTERDAY';
    } else {
      final year = sessionDay.year != now.year ? ' ${sessionDay.year}' : '';
      label = '${monthAbbrev[sessionDay.month]} ${sessionDay.day}$year';
    }
    grouped.putIfAbsent(label, () => []).add(session);
  }
  return grouped;
});

class ActivePeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.week;
  void select(StatsPeriod period) => state = period;
}

final activePeriodProvider = NotifierProvider<ActivePeriodNotifier, StatsPeriod>(
  () => ActivePeriodNotifier(),
);
