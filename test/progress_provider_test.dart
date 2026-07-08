import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:speed_reading_app/models/training_session.dart';
import 'package:speed_reading_app/providers/progress_provider.dart';
import 'package:speed_reading_app/services/storage_service.dart';
import 'package:speed_reading_app/providers/books_provider.dart';

void main() {
  late StorageService storage;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('progress_test_');
    Hive.init(tempDir.path);
    storage = await StorageService.open(docsDir: tempDir);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  TrainingSession _makeSession({
    required bool qualified,
    required int finalWpm,
    required int comprehensionPercent,
    required int effectiveWpm,
    DateTime? startedAt,
    String lang = 'en',
    int level = 1,
    List<ExerciseResult> exerciseResults = const [],
  }) {
    return TrainingSession(
      id: const Uuid().v4(),
      languageCode: lang,
      startedAt: startedAt ?? DateTime.now(),
      level: level,
      finalWpm: finalWpm,
      comprehensionPercent: comprehensionPercent,
      effectiveWpm: effectiveWpm,
      qualified: qualified,
      exerciseResults: exerciseResults,
    );
  }

  test('ProgressStats: empty sessions returns all zeros', () async {
    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final stats = ref.read(progressStatsProvider((lang: 'en', period: StatsPeriod.week)));
    expect(stats.avgWpm, 0);
    expect(stats.bestEffWpm, 0);
    expect(stats.totalSessions, 0);
    expect(stats.qualifiedSessions, 0);
    expect(stats.currentStreak, 0);
    expect(stats.bestStreak, 0);
  });

  test('ProgressStats: computes avgWpm, comprehension, streak correctly', () async {
    // Save 3 sessions: 2 qualified + 1 failed
    final now = DateTime.now();
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 200, comprehensionPercent: 80, effectiveWpm: 160,
      startedAt: now.subtract(const Duration(days: 1)),
    ));
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 240, comprehensionPercent: 90, effectiveWpm: 216,
      startedAt: now.subtract(const Duration(hours: 10)),
    ));
    await storage.saveTrainingSession(_makeSession(
      qualified: false, finalWpm: 180, comprehensionPercent: 50, effectiveWpm: 90,
      startedAt: now.subtract(const Duration(hours: 5)),
    ));

    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final stats = ref.read(progressStatsProvider((lang: 'en', period: StatsPeriod.week)));
    expect(stats.totalSessions, 3);
    expect(stats.qualifiedSessions, 2);
    expect(stats.avgWpm, ((200 + 240 + 180) / 3).round()); // 207
    expect(stats.avgComprehension, ((80 + 90 + 50) / 3).round()); // 73
    expect(stats.bestEffWpm, 216); // highest effective WPM

    // Streak: last session was failed → currentStreak = 0
    expect(stats.currentStreak, 0);
    // Best streak: 2 qualified in a row
    expect(stats.bestStreak, 2);
  });

  test('ProgressStats: currentStreak counts trailing qualified sessions', () async {
    final now = DateTime.now();
    // Older failed session
    await storage.saveTrainingSession(_makeSession(
      qualified: false, finalWpm: 150, comprehensionPercent: 40, effectiveWpm: 60,
      startedAt: now.subtract(const Duration(days: 3)),
    ));
    // Two recent qualified sessions
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 220, comprehensionPercent: 80, effectiveWpm: 176,
      startedAt: now.subtract(const Duration(days: 2)),
    ));
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 230, comprehensionPercent: 85, effectiveWpm: 195,
      startedAt: now.subtract(const Duration(days: 1)),
    ));

    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final stats = ref.read(progressStatsProvider((lang: 'en', period: StatsPeriod.week)));
    expect(stats.currentStreak, 2);
    expect(stats.bestStreak, 2);
  });

  test('ChartData: produces 7 bars for week period', () async {
    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final chart = ref.read(chartDataProvider((lang: 'en', period: StatsPeriod.week)));
    expect(chart.length, 7);
    expect(chart.last.isToday, true);
  });

  test('ChartData: produces 6 bars for month period', () async {
    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final chart = ref.read(chartDataProvider((lang: 'en', period: StatsPeriod.month)));
    expect(chart.length, 6);
  });

  test('WeakSkills: identifies lowest-scoring exercise types', () async {
    // Flash recognition: 45% accuracy (weak)
    await storage.saveTrainingSession(_makeSession(
      qualified: false, finalWpm: 0, comprehensionPercent: 0, effectiveWpm: 0,
      exerciseResults: [
        ExerciseResult(exerciseType: 'flash_recognition', durationSeconds: 15, difficulty: 1, accuracyPercent: 45, completed: true),
      ],
    ));
    // Schulte: 90% (strong)
    await storage.saveTrainingSession(_makeSession(
      qualified: false, finalWpm: 0, comprehensionPercent: 0, effectiveWpm: 0,
      exerciseResults: [
        ExerciseResult(exerciseType: 'schulte', durationSeconds: 40, difficulty: 1, accuracyPercent: 90, completed: true),
      ],
    ));

    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final skills = ref.read(weakSkillsProvider('en'));
    // Only flash_recognition is below 80 threshold
    expect(skills.length, 1);
    expect(skills.first.exerciseType, 'flash_recognition');
    expect(skills.first.score, 45.0);
  });

  test('SessionHistory: groups sessions correctly by today/yesterday/date', () async {
    final now = DateTime.now();
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 200, comprehensionPercent: 80, effectiveWpm: 160,
      startedAt: now, // today
    ));
    await storage.saveTrainingSession(_makeSession(
      qualified: true, finalWpm: 210, comprehensionPercent: 75, effectiveWpm: 158,
      startedAt: now.subtract(const Duration(days: 1)), // yesterday
    ));
    await storage.saveTrainingSession(_makeSession(
      qualified: false, finalWpm: 190, comprehensionPercent: 60, effectiveWpm: 114,
      startedAt: now.subtract(const Duration(days: 5)), // older
    ));

    final ref = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
    );
    addTearDown(ref.dispose);

    final history = ref.read(sessionHistoryProvider('en'));
    expect(history.containsKey('TODAY'), true);
    expect(history.containsKey('YESTERDAY'), true);
    expect(history['TODAY']!.length, 1);
    expect(history['YESTERDAY']!.length, 1);
    // Older session gets a date label
    final olderKeys = history.keys.where((k) => k != 'TODAY' && k != 'YESTERDAY').toList();
    expect(olderKeys.length, 1);
  });
}
