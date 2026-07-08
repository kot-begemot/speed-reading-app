import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:speed_reading_app/models/trainer_profile.dart';
import 'package:speed_reading_app/models/training_content.dart';
import 'package:speed_reading_app/models/training_session.dart';
import 'package:speed_reading_app/services/storage_service.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('trainer_test');
    Hive.init(p.join(tmp.path, 'hive'));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('TrainerProfile getOrCreate, update, and persist round-trip', () async {
    final storage = await StorageService.open(docsDir: tmp);

    // Initial load creates default profile
    TrainerProfile profile = await storage.getOrCreateTrainerProfile();
    expect(profile.id, 'global_profile');
    expect(profile.defaultLanguageCode, 'en');
    expect(profile.languageProfiles.containsKey('en'), isTrue);
    expect(profile.languageProfiles['en']!.currentLevel, 1);

    // Modify profile
    profile.defaultLanguageCode = 'ru';
    profile.languageProfiles['en']!.currentLevel = 3;
    profile.languageProfiles['en']!.bestEffectiveWpm = 250;
    await storage.saveTrainerProfile(profile);

    // Close and reopen box (simulates app restart)
    await Hive.close();
    final storage2 = await StorageService.open(docsDir: tmp);

    TrainerProfile reloaded = await storage2.getOrCreateTrainerProfile();
    expect(reloaded.defaultLanguageCode, 'ru');
    expect(reloaded.languageProfiles['en']!.currentLevel, 3);
    expect(reloaded.languageProfiles['en']!.bestEffectiveWpm, 250);
  });

  test('TrainingSession save, list, and sort order', () async {
    final storage = await StorageService.open(docsDir: tmp);

    final session1 = TrainingSession(
      id: 'session_1',
      languageCode: 'en',
      startedAt: DateTime(2026, 1, 1, 10, 0),
      completedAt: DateTime(2026, 1, 1, 10, 10),
      level: 1,
      exerciseResults: [
        ExerciseResult(
          exerciseType: 'schulte',
          durationSeconds: 45,
          difficulty: 5,
          completed: true,
          qualified: true,
        ),
      ],
      finalWpm: 210,
      comprehensionPercent: 80,
      effectiveWpm: 168,
      qualified: true,
    );

    final session2 = TrainingSession(
      id: 'session_2',
      languageCode: 'en',
      startedAt: DateTime(2026, 1, 1, 12, 0),
      completedAt: DateTime(2026, 1, 1, 12, 10),
      level: 1,
      exerciseResults: [],
      finalWpm: 250,
      comprehensionPercent: 40,
      effectiveWpm: 100,
      qualified: false,
      failReason: 'Comprehension too low',
    );

    final session3 = TrainingSession(
      id: 'session_3',
      languageCode: 'ru',
      startedAt: DateTime(2026, 1, 2, 9, 0),
      level: 2,
      exerciseResults: [],
      qualified: false,
    );

    await storage.saveTrainingSession(session1);
    await storage.saveTrainingSession(session2);
    await storage.saveTrainingSession(session3);

    // Reload and check sessions
    final enSessions = storage.getAllSessions(languageCode: 'en');
    expect(enSessions.length, 2);
    // Sort should be date descending, so session2 is first (started at 12:00 vs 10:00)
    expect(enSessions[0].id, 'session_2');
    expect(enSessions[1].id, 'session_1');
    expect(enSessions[0].qualified, isFalse);
    expect(enSessions[1].qualified, isTrue);

    final ruSessions = storage.getAllSessions(languageCode: 'ru');
    expect(ruSessions.length, 1);
    expect(ruSessions[0].id, 'session_3');

    final recent = storage.getRecentSessions(1, languageCode: 'en');
    expect(recent.length, 1);
    expect(recent[0].id, 'session_2');

    // Test clear trainer progress
    await storage.resetTrainerProgress();
    expect(storage.getAllSessions().length, 0);
  });

  test('TrainingText save and load by level', () async {
    final storage = await StorageService.open(docsDir: tmp);

    final text1 = TrainingText(
      id: 'text_1',
      title: 'Topic 1',
      level: 1,
      languageCode: 'en',
      wordCount: 150,
      topic: 'General',
      body: 'This is a level 1 text.',
      questions: [
        ComprehensionQuestion(
          id: 'q1',
          prompt: 'Is this level 1?',
          options: ['Yes', 'No', 'Maybe', 'IDK'],
          correctOptionIndex: 0,
        ),
      ],
    );

    final text2 = TrainingText(
      id: 'text_2',
      title: 'Topic 2',
      level: 2,
      languageCode: 'en',
      wordCount: 250,
      topic: 'Science',
      body: 'This is a level 2 text.',
      questions: [],
    );

    await storage.saveTrainingText(text1);
    await storage.saveTrainingText(text2);

    final level1Texts = storage.getTextsForLevel('en', 1);
    expect(level1Texts.length, 1);
    expect(level1Texts[0].id, 'text_1');
    expect(level1Texts[0].questions.length, 1);
    expect(level1Texts[0].questions[0].prompt, 'Is this level 1?');

    final level2Texts = storage.getTextsForLevel('en', 2);
    expect(level2Texts.length, 1);
    expect(level2Texts[0].id, 'text_2');

    await storage.clearAllTrainingTexts();
    expect(storage.getTrainingTexts('en').length, 0);
  });
}
