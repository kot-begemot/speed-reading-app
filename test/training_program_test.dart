import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speed_reading_app/providers/baseline_provider.dart';
import 'package:speed_reading_app/providers/books_provider.dart';
import 'package:speed_reading_app/providers/training_program_provider.dart';
import 'package:speed_reading_app/services/storage_service.dart';
import 'package:speed_reading_app/services/seed_service.dart';
import 'package:speed_reading_app/models/trainer_profile.dart';

void main() {
  late Directory tmp;
  late StorageService storage;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('programtest');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
    await SeedService.ensureSeeded(storage);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('Training Program Workflow Integration Test', () async {
    // 1. Setup profile where English baseline is already completed
    final profile = await storage.getOrCreateTrainerProfile();
    profile.languageProfiles['en'] = TrainerLanguageProfile(
      languageCode: 'en',
      currentLevel: 1,
      bestEffectiveWpm: 150,
      successfulSessionsInRow: 0,
      baselineCompletedAt: DateTime.now(),
    );
    await storage.saveTrainerProfile(profile);

    final ref = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(ref.dispose);

    // Read the provider first to trigger build() and schedule the microtask init.
    ref.read(trainingProgramProvider);

    // Now await the profile future so _initFromProfile can complete.
    await ref.read(trainerProfileProvider.future);
    // Pump one extra microtask cycle for the state update to land.
    await Future.delayed(Duration.zero);

    // Initial state should now be fully loaded from DB.
    var state = ref.read(trainingProgramProvider);
    expect(state.level, 1);
    expect(state.targetWpm, 200);
    expect(state.currentStepIndex, 0);
    expect(state.isSessionComplete, false);
    expect(state.selectedText, isNotNull);
    expect(state.selectedText!.languageCode, 'en');

    final notifier = ref.read(trainingProgramProvider.notifier);

    // ==========================================
    // RUN SESSION 1 (Qualified: Speed 220, Comp 80%)
    // ==========================================
    notifier.logWarmUp(0, 35);
    state = ref.read(trainingProgramProvider);
    expect(state.currentStepIndex, 1);
    expect(state.warmUpErrors, 0);
    expect(state.warmUpDurationSecs, 35);

    notifier.logRecognition(90, 1);
    state = ref.read(trainingProgramProvider);
    expect(state.currentStepIndex, 2);
    expect(state.recognitionAccuracy, 90);
    expect(state.recognitionErrors, 1);

    notifier.logReading(220, 300);
    state = ref.read(trainingProgramProvider);
    expect(state.currentStepIndex, 3);
    expect(state.readingWpm, 220);
    expect(state.wordsRead, 300);

    // Answer 4 out of 5 correct (80% comprehension, Level 1 min is 70%)
    await notifier.submitQuizAndCompleteSession(4);
    state = ref.read(trainingProgramProvider);
    expect(state.currentStepIndex, 4);
    expect(state.isSessionComplete, true);
    expect(state.qualified, true);
    expect(state.consecutiveSuccessfulSessions, 1);
    expect(state.levelUpUnlocked, false);

    // Verify session log was written to local DB
    var sessions = storage.getAllSessions(languageCode: 'en');
    expect(sessions.length, 1);
    expect(sessions.first.qualified, true);
    expect(sessions.first.finalWpm, 220);
    expect(sessions.first.comprehensionPercent, 80);

    // Verify profile streak matches
    var currentProfile = await storage.getOrCreateTrainerProfile();
    expect(currentProfile.languageProfiles['en']!.successfulSessionsInRow, 1);
    expect(currentProfile.languageProfiles['en']!.currentLevel, 1);

    // ==========================================
    // RUN SESSION 2 (Qualified: Speed 230, Comp 100%)
    // ==========================================
    notifier.startSession();
    state = ref.read(trainingProgramProvider);
    expect(state.currentStepIndex, 0);
    expect(state.isSessionComplete, false);

    notifier.logWarmUp(1, 40);
    notifier.logRecognition(100, 0);
    notifier.logReading(230, 300);
    await notifier.submitQuizAndCompleteSession(5); // 100% comprehension

    state = ref.read(trainingProgramProvider);
    expect(state.qualified, true);
    expect(state.consecutiveSuccessfulSessions, 2);
    expect(state.levelUpUnlocked, false);

    // ==========================================
    // RUN SESSION 3 (Qualified: Speed 240, Comp 80% -> Promotes to Level 2!)
    // ==========================================
    notifier.startSession();
    notifier.logWarmUp(0, 30);
    notifier.logRecognition(90, 1);
    notifier.logReading(240, 300);
    await notifier.submitQuizAndCompleteSession(4); // 80% comprehension

    state = ref.read(trainingProgramProvider);
    expect(state.qualified, true);
    expect(state.consecutiveSuccessfulSessions, 0); // resets on level up
    expect(state.levelUpUnlocked, true);
    expect(state.level, 2); // should be level 2 now!

    // Verify DB profile updated to level 2
    currentProfile = await storage.getOrCreateTrainerProfile();
    expect(currentProfile.languageProfiles['en']!.currentLevel, 2);
    expect(currentProfile.languageProfiles['en']!.successfulSessionsInRow, 0);

    // ==========================================
    // RUN SESSION 4 (Failure: Speed 210, Comp 60% -> reset streak)
    // ==========================================
    // Reset only the step-tracking state for a new session; level stays at 2 from the previous result.
    notifier.startSession();
    state = ref.read(trainingProgramProvider);
    expect(state.level, 2);
    expect(state.targetWpm, 250); // Level 2 target is 250

    notifier.logWarmUp(0, 25);
    notifier.logRecognition(80, 2);
    notifier.logReading(210, 300);
    // Level 2 min comprehension is 70%. Answer 3/5 correct (60% comprehension).
    await notifier.submitQuizAndCompleteSession(3);

    state = ref.read(trainingProgramProvider);
    expect(state.qualified, false);
    expect(state.consecutiveSuccessfulSessions, 0);
    expect(state.levelUpUnlocked, false);

    // Verify DB profile reset streak
    currentProfile = await storage.getOrCreateTrainerProfile();
    expect(currentProfile.languageProfiles['en']!.successfulSessionsInRow, 0);
    expect(currentProfile.languageProfiles['en']!.currentLevel, 2); // did not lose level
  });
}
