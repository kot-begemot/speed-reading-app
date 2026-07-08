import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speed_reading_app/providers/baseline_provider.dart';
import 'package:speed_reading_app/providers/books_provider.dart';
import 'package:speed_reading_app/services/storage_service.dart';
import 'package:speed_reading_app/services/seed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tmp;
  late StorageService storage;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('baselinetest');
    Hive.init(p.join(tmp.path, 'hive'));
    storage = await StorageService.open(docsDir: tmp);
    await SeedService.ensureSeeded(storage);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('Baseline Assessment Flow State Machine Integration Test', () async {
    final ref = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(ref.dispose);

    // 1. Initial Intro Step
    var state = ref.read(baselineProvider('en'));
    expect(state.step, BaselineStep.intro);
    expect(state.languageCode, 'en');
    expect(state.text, isNull);

    // 2. Start Assessment -> moves to reading
    final notifier = ref.read(baselineProvider('en').notifier);
    notifier.startAssessment();
    
    state = ref.read(baselineProvider('en'));
    expect(state.step, BaselineStep.reading);
    expect(state.text, isNotNull);
    expect(state.text!.languageCode, 'en');
    expect(state.readingStartedAt, isNotNull);

    // Mock reading duration: let's pretend 40 seconds passed.
    // To test the exact math, we will override the readingStartedAt to 30 seconds ago.
    final startTime = DateTime.now().subtract(const Duration(seconds: 30));
    // Set internal state directly by using notifier's state setter or recreating it.
    // But wait! In our notifier:
    // seconds is: duration.inSeconds
    // WPM is: (text.wordCount / seconds) * 60
    // If text has 304 words, and we read in 30 seconds, raw WPM should be: (304 / 30) * 60 = 608 WPM.
    
    // Let's call finishReading after overriding the state.
    // In Riverpod 3 Notifier: we can set the notifier state directly!
    final sleepText = storage.getTrainingTexts('en').firstWhere((t) => t.id == 'diag-en-sleep');
    ref.read(baselineProvider('en').notifier).state = state.copyWith(
      readingStartedAt: startTime,
      text: sleepText,
    );

    notifier.finishReading();

    state = ref.read(baselineProvider('en'));
    expect(state.step, BaselineStep.quiz);
    // (304 / 30) * 60 = 608 WPM
    expect(state.rawWpm, 608);

    // 3. Quiz Step - Select Answers
    // The text has 5 questions. Let's answer 4 out of 5 correctly (80% comprehension).
    // Correct answers in diag-en-sleep:
    // q1: index 2
    // q2: index 0
    // q3: index 1
    // q4: index 3
    // q5: index 1
    notifier.selectAnswer(0, 2); // Correct
    notifier.selectAnswer(1, 0); // Correct
    notifier.selectAnswer(2, 1); // Correct
    notifier.selectAnswer(3, 3); // Correct
    notifier.selectAnswer(4, 0); // Incorrect (correct is 1)

    state = ref.read(baselineProvider('en'));
    expect(state.answers.length, 5);
    expect(state.answers[0], 2);

    // 4. Submit Quiz -> Result Step
    await notifier.submitQuiz();

    state = ref.read(baselineProvider('en'));
    expect(state.step, BaselineStep.result);
    expect(state.comprehensionPercent, 80);
    // effective WPM = 608 * 0.8 = 486
    expect(state.effectiveWpm, 486);
    // effective WPM 486 is between 400 and 500 -> suggested Level 5
    expect(state.suggestedLevel, 5);

    // 5. Verify database profile & history updates
    final profile = await storage.getOrCreateTrainerProfile();
    expect(profile.defaultLanguageCode, 'en');
    expect(profile.languageProfiles['en']!.currentLevel, 5);
    expect(profile.languageProfiles['en']!.bestEffectiveWpm, 486);
    expect(profile.languageProfiles['en']!.baselineCompletedAt, isNotNull);

    final sessions = storage.getAllSessions(languageCode: 'en');
    expect(sessions.length, 1);
    expect(sessions[0].finalWpm, 608);
    expect(sessions[0].comprehensionPercent, 80);
    expect(sessions[0].effectiveWpm, 486);
    expect(sessions[0].qualified, isTrue);
  });
}
