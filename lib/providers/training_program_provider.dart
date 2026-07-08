import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/trainer_profile.dart';
import '../models/training_content.dart';
import '../models/training_session.dart';
import 'books_provider.dart';
import 'baseline_provider.dart';

class TrainingProgramState {
  final String languageCode;
  final int level;
  final int targetWpm;
  final int currentStepIndex;
  final bool isSessionComplete;
  final TrainingText? selectedText;

  // Exercise Results
  final int? warmUpErrors;
  final int? warmUpDurationSecs;
  final int? recognitionAccuracy;
  final int? recognitionErrors;
  final int? readingWpm;
  final int? wordsRead;
  final int? comprehensionRate;

  // Level progression outcomes
  final bool qualified;
  final int consecutiveSuccessfulSessions;
  final int sessionsRequiredForPromotion;
  final bool levelUpUnlocked;

  TrainingProgramState({
    required this.languageCode,
    required this.level,
    required this.targetWpm,
    this.currentStepIndex = 0,
    this.isSessionComplete = false,
    this.selectedText,
    this.warmUpErrors,
    this.warmUpDurationSecs,
    this.recognitionAccuracy,
    this.recognitionErrors,
    this.readingWpm,
    this.wordsRead,
    this.comprehensionRate,
    this.qualified = false,
    this.consecutiveSuccessfulSessions = 0,
    this.sessionsRequiredForPromotion = 3,
    this.levelUpUnlocked = false,
  });

  TrainingProgramState copyWith({
    String? languageCode,
    int? level,
    int? targetWpm,
    int? currentStepIndex,
    bool? isSessionComplete,
    TrainingText? selectedText,
    int? warmUpErrors,
    int? warmUpDurationSecs,
    int? recognitionAccuracy,
    int? recognitionErrors,
    int? readingWpm,
    int? wordsRead,
    int? comprehensionRate,
    bool? qualified,
    int? consecutiveSuccessfulSessions,
    int? sessionsRequiredForPromotion,
    bool? levelUpUnlocked,
  }) {
    return TrainingProgramState(
      languageCode: languageCode ?? this.languageCode,
      level: level ?? this.level,
      targetWpm: targetWpm ?? this.targetWpm,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isSessionComplete: isSessionComplete ?? this.isSessionComplete,
      selectedText: selectedText ?? this.selectedText,
      warmUpErrors: warmUpErrors ?? this.warmUpErrors,
      warmUpDurationSecs: warmUpDurationSecs ?? this.warmUpDurationSecs,
      recognitionAccuracy: recognitionAccuracy ?? this.recognitionAccuracy,
      recognitionErrors: recognitionErrors ?? this.recognitionErrors,
      readingWpm: readingWpm ?? this.readingWpm,
      wordsRead: wordsRead ?? this.wordsRead,
      comprehensionRate: comprehensionRate ?? this.comprehensionRate,
      qualified: qualified ?? this.qualified,
      consecutiveSuccessfulSessions: consecutiveSuccessfulSessions ?? this.consecutiveSuccessfulSessions,
      sessionsRequiredForPromotion: sessionsRequiredForPromotion ?? this.sessionsRequiredForPromotion,
      levelUpUnlocked: levelUpUnlocked ?? this.levelUpUnlocked,
    );
  }
}

class TrainingProgramNotifier extends Notifier<TrainingProgramState> {
  @override
  TrainingProgramState build() {
    // Watch only the active language — it's a fast synchronous Notifier.
    // We deliberately do NOT watch trainerProfileProvider (async FutureProvider)
    // to avoid the build() being re-triggered — and resetting ephemeral step
    // state — every time the profile is invalidated after session saves.
    final activeLang = ref.watch(activeTrainerLanguageProvider);

    // Keep this provider alive so the ref stays valid during async _initFromProfile.
    ref.keepAlive();

    // Kick off async initialization in the background.
    Future.microtask(() => _initFromProfile(activeLang));

    return TrainingProgramState(
      languageCode: activeLang,
      level: 1,
      targetWpm: 200,
    );
  }

  Future<void> _initFromProfile(String activeLang) async {
    // Guard: don't try to update state if provider was invalidated.
    if (!ref.mounted) return;

    final profile = await ref.read(trainerProfileProvider.future);
    if (!ref.mounted) return;

    final storage = ref.read(storageServiceProvider);

    final langProfile = profile.languageProfiles[activeLang];
    final level = langProfile?.currentLevel ?? 1;
    final targetWpm = _targetWpmForLevel(level);

    final allTexts = storage.getTrainingTexts(activeLang);
    final allSessions = storage.getAllSessions(languageCode: activeLang);
    final readTextIds = allSessions.map((s) => s.textId).whereType<String>().toSet();

    TrainingText? selectedText;
    final unread = allTexts.where((t) => !readTextIds.contains(t.id)).toList();
    if (unread.isNotEmpty) {
      selectedText = unread.first;
    } else if (allTexts.isNotEmpty) {
      selectedText = allTexts.first;
    }

    final promotionReq = level <= 3 ? 3 : 5;
    final currentStreak = langProfile?.successfulSessionsInRow ?? 0;

    state = TrainingProgramState(
      languageCode: activeLang,
      level: level,
      targetWpm: targetWpm,
      selectedText: selectedText,
      sessionsRequiredForPromotion: promotionReq,
      consecutiveSuccessfulSessions: currentStreak,
    );
  }

  int _targetWpmForLevel(int lvl) {
    if (lvl == 1) return 200;
    if (lvl == 2) return 250;
    if (lvl == 3) return 300;
    if (lvl == 4) return 400;
    if (lvl == 5) return 500;
    return 500 + (lvl - 5) * 100;
  }

  void startSession() {
    state = state.copyWith(
      currentStepIndex: 0,
      isSessionComplete: false,
      warmUpErrors: null,
      warmUpDurationSecs: null,
      recognitionAccuracy: null,
      recognitionErrors: null,
      readingWpm: null,
      wordsRead: null,
      comprehensionRate: null,
      qualified: false,
      levelUpUnlocked: false,
    );
  }

  void advanceStep() {
    if (state.currentStepIndex < 4) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  void logWarmUp(int errors, int durationSecs) {
    state = state.copyWith(
      warmUpErrors: errors,
      warmUpDurationSecs: durationSecs,
      currentStepIndex: 1,
    );
  }

  void logRecognition(int accuracy, int errors) {
    state = state.copyWith(
      recognitionAccuracy: accuracy,
      recognitionErrors: errors,
      currentStepIndex: 2,
    );
  }

  void logReading(int rawWpm, int wordsCount) {
    state = state.copyWith(
      readingWpm: rawWpm,
      wordsRead: wordsCount,
      currentStepIndex: 3,
    );
  }

  Future<void> submitQuizAndCompleteSession(int correctCount) async {
    final storage = ref.read(storageServiceProvider);
    final activeLang = state.languageCode;
    final profile = await storage.getOrCreateTrainerProfile();
    final langProfile = profile.languageProfiles[activeLang]!;

    final totalQuestions = state.selectedText?.questions.length ?? 5;
    final compRate = ((correctCount / totalQuestions) * 100).round();

    // Check qualification criteria
    final minComprehension = state.level <= 2 ? 70 : (state.level <= 4 ? 65 : 60);
    final rawWpm = state.readingWpm ?? state.targetWpm;
    final isQualified = rawWpm >= state.targetWpm && compRate >= minComprehension;
    final effectiveWpm = (rawWpm * (compRate / 100)).round();

    int newStreak = 0;
    bool newLevelUp = false;
    int currentLevel = state.level;

    if (isQualified) {
      newStreak = state.consecutiveSuccessfulSessions + 1;
      if (newStreak >= state.sessionsRequiredForPromotion) {
        newLevelUp = true;
        currentLevel++;
        newStreak = 0;
      }
    } else {
      newStreak = 0; // Reset streak on failure
    }

    // 1. Update persisted database profile
    final updatedLangProfile = TrainerLanguageProfile(
      languageCode: activeLang,
      currentLevel: currentLevel,
      bestEffectiveWpm: effectiveWpm > langProfile.bestEffectiveWpm ? effectiveWpm : langProfile.bestEffectiveWpm,
      successfulSessionsInRow: newStreak,
      baselineCompletedAt: langProfile.baselineCompletedAt ?? DateTime.now(),
      lastSessionAt: DateTime.now(),
    );
    profile.languageProfiles[activeLang] = updatedLangProfile;
    await storage.saveTrainerProfile(profile);

    // 2. Log training session
    final sessionId = const Uuid().v4();
    final List<ExerciseResult> results = [
      ExerciseResult(
        exerciseType: 'schulte',
        difficulty: state.level,
        durationSeconds: state.warmUpDurationSecs ?? 30,
        mistakes: state.warmUpErrors ?? 0,
        completed: true,
      ),
      ExerciseResult(
        exerciseType: 'flash_recognition',
        difficulty: state.level,
        durationSeconds: 15,
        accuracyPercent: (state.recognitionAccuracy ?? 100).toDouble(),
        mistakes: state.recognitionErrors ?? 0,
        completed: true,
      ),
      ExerciseResult(
        exerciseType: 'rsvp_reading',
        languageCode: activeLang,
        textId: state.selectedText?.id,
        difficulty: state.level,
        durationSeconds: ((state.wordsRead ?? 300) / rawWpm * 60).round(),
        wpm: rawWpm,
        comprehensionPercent: compRate,
        completed: true,
        qualified: isQualified,
      ),
    ];

    final session = TrainingSession(
      id: sessionId,
      languageCode: activeLang,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      completedAt: DateTime.now(),
      level: state.level,
      textId: state.selectedText?.id,
      exerciseResults: results,
      finalWpm: rawWpm,
      comprehensionPercent: compRate,
      effectiveWpm: effectiveWpm,
      qualified: isQualified,
    );
    await storage.saveTrainingSession(session);

    // 3. Update state
    state = state.copyWith(
      level: currentLevel,
      targetWpm: _targetWpmForLevel(currentLevel),
      comprehensionRate: compRate,
      qualified: isQualified,
      consecutiveSuccessfulSessions: newStreak,
      levelUpUnlocked: newLevelUp,
      isSessionComplete: true,
      currentStepIndex: 4,
    );

    // 4. Invalidate related providers to sync UI immediately
    ref.invalidate(trainerProfileProvider);
    ref.invalidate(recentSessionsProvider(activeLang));
  }
}

final trainingProgramProvider = NotifierProvider<TrainingProgramNotifier, TrainingProgramState>(
  () => TrainingProgramNotifier(),
);
