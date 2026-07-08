import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/trainer_profile.dart';
import '../models/training_content.dart';
import '../models/training_session.dart';
import '../services/storage_service.dart';
import 'books_provider.dart';

enum BaselineStep {
  intro,
  reading,
  quiz,
  result,
}

class BaselineState {
  final String languageCode;
  final BaselineStep step;
  final TrainingText? text;
  final DateTime? readingStartedAt;
  final Duration? readingDuration;
  final Map<int, int> answers; // question index -> selected option index
  final int? rawWpm;
  final int? comprehensionPercent;
  final int? effectiveWpm;
  final int? suggestedLevel;

  BaselineState({
    required this.languageCode,
    this.step = BaselineStep.intro,
    this.text,
    this.readingStartedAt,
    this.readingDuration,
    this.answers = const {},
    this.rawWpm,
    this.comprehensionPercent,
    this.effectiveWpm,
    this.suggestedLevel,
  });

  BaselineState copyWith({
    String? languageCode,
    BaselineStep? step,
    TrainingText? text,
    DateTime? readingStartedAt,
    Duration? readingDuration,
    Map<int, int>? answers,
    int? rawWpm,
    int? comprehensionPercent,
    int? effectiveWpm,
    int? suggestedLevel,
  }) {
    return BaselineState(
      languageCode: languageCode ?? this.languageCode,
      step: step ?? this.step,
      text: text ?? this.text,
      readingStartedAt: readingStartedAt ?? this.readingStartedAt,
      readingDuration: readingDuration ?? this.readingDuration,
      answers: answers ?? this.answers,
      rawWpm: rawWpm ?? this.rawWpm,
      comprehensionPercent: comprehensionPercent ?? this.comprehensionPercent,
      effectiveWpm: effectiveWpm ?? this.effectiveWpm,
      suggestedLevel: suggestedLevel ?? this.suggestedLevel,
    );
  }
}

class BaselineNotifier extends Notifier<BaselineState> {
  final String languageCode;
  BaselineNotifier(this.languageCode);

  @override
  BaselineState build() {
    return BaselineState(languageCode: languageCode);
  }

  /// Selects a diagnostic text randomly from the DB for the current language.
  void startAssessment() {
    final StorageService storage = ref.read(storageServiceProvider);
    final texts = storage.getTrainingTexts(languageCode);
    
    if (texts.isEmpty) {
      throw StateError('No diagnostic texts seeded for language: $languageCode');
    }

    // Select randomly
    final text = texts[Random().nextInt(texts.length)];

    state = state.copyWith(
      step: BaselineStep.reading,
      text: text,
      readingStartedAt: DateTime.now(),
    );
  }

  /// Stops reading phase and transitions to quiz.
  void finishReading() {
    final start = state.readingStartedAt;
    final text = state.text;
    if (start == null || text == null) return;

    final duration = DateTime.now().difference(start);
    // Protect against instant tapping by forcing a minimum of 1 second
    final seconds = duration.inSeconds.clamp(1, 999999);
    final rawWpm = ((text.wordCount / seconds) * 60).round();

    state = state.copyWith(
      step: BaselineStep.quiz,
      readingDuration: duration,
      rawWpm: rawWpm,
      answers: {},
    );
  }

  /// Records an answer to a quiz question.
  void selectAnswer(int questionIndex, int optionIndex) {
    final newAnswers = Map<int, int>.from(state.answers);
    newAnswers[questionIndex] = optionIndex;
    state = state.copyWith(answers: newAnswers);
  }

  /// Submits the quiz answers and calculates final results.
  Future<void> submitQuiz() async {
    final text = state.text;
    final wpm = state.rawWpm;
    if (text == null || wpm == null) return;

    // Calculate comprehension
    var correctCount = 0;
    for (var i = 0; i < text.questions.length; i++) {
      if (state.answers[i] == text.questions[i].correctOptionIndex) {
        correctCount++;
      }
    }
    final comprehension = ((correctCount / text.questions.length) * 100).round();
    final effectiveWpm = (wpm * (comprehension / 100)).round();

    // Map effective WPM to starting level (Level 1 to 6)
    int suggestedLevel;
    if (effectiveWpm < 200) {
      suggestedLevel = 1;
    } else if (effectiveWpm < 250) {
      suggestedLevel = 2;
    } else if (effectiveWpm < 300) {
      suggestedLevel = 3;
    } else if (effectiveWpm < 400) {
      suggestedLevel = 4;
    } else if (effectiveWpm < 500) {
      suggestedLevel = 5;
    } else {
      suggestedLevel = 6;
    }

    final StorageService storage = ref.read(storageServiceProvider);
    
    // Update profile
    final profile = await storage.getOrCreateTrainerProfile();
    final langProfile = profile.languageProfiles[languageCode] ??
        TrainerLanguageProfile(languageCode: languageCode);
    
    langProfile.currentLevel = suggestedLevel;
    langProfile.baselineCompletedAt = DateTime.now();
    langProfile.lastSessionAt = DateTime.now();
    if (effectiveWpm > langProfile.bestEffectiveWpm) {
      langProfile.bestEffectiveWpm = effectiveWpm;
    }
    profile.languageProfiles[languageCode] = langProfile;
    await storage.saveTrainerProfile(profile);

    // Log this assessment as a qualified training session
    final session = TrainingSession(
      id: const Uuid().v4(),
      languageCode: languageCode,
      startedAt: state.readingStartedAt ?? DateTime.now(),
      completedAt: DateTime.now(),
      level: 1, // baseline is level 1 entry
      textId: text.id,
      finalWpm: wpm,
      comprehensionPercent: comprehension,
      effectiveWpm: effectiveWpm,
      qualified: true,
      exerciseResults: [
        ExerciseResult(
          exerciseType: 'baseline_reading',
          durationSeconds: state.readingDuration?.inSeconds ?? 0,
          difficulty: 1,
          wpm: wpm,
          comprehensionPercent: comprehension,
          completed: true,
          qualified: true,
        ),
      ],
    );
    await storage.saveTrainingSession(session);

    // Refresh default language if needed
    if (profile.defaultLanguageCode != languageCode) {
      profile.defaultLanguageCode = languageCode;
      await storage.saveTrainerProfile(profile);
    }

    state = state.copyWith(
      step: BaselineStep.result,
      comprehensionPercent: comprehension,
      effectiveWpm: effectiveWpm,
      suggestedLevel: suggestedLevel,
    );

    // Trigger riverpod update on books_provider / trainer if needed
    ref.invalidate(trainerProfileProvider);
  }
}

/// Provides the state for the baseline assessment flow of a given language.
final baselineProvider = NotifierProvider.family<BaselineNotifier, BaselineState, String>(
  (arg) => BaselineNotifier(arg),
);

/// A provider that exposes the current TrainerProfile (loaded from DB).
final trainerProfileProvider = FutureProvider<TrainerProfile>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getOrCreateTrainerProfile();
});

/// Manages and persists the active training language.
class ActiveLanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final profileAsync = ref.watch(trainerProfileProvider);
    return profileAsync.maybeWhen(
      data: (profile) => profile.defaultLanguageCode,
      orElse: () => 'en',
    );
  }

  Future<void> setLanguage(String lang) async {
    final storage = ref.read(storageServiceProvider);
    final profile = await storage.getOrCreateTrainerProfile();
    if (profile.defaultLanguageCode != lang) {
      profile.defaultLanguageCode = lang;
      await storage.saveTrainerProfile(profile);
      ref.invalidate(trainerProfileProvider);
    }
  }
}

final activeTrainerLanguageProvider = NotifierProvider<ActiveLanguageNotifier, String>(
  () => ActiveLanguageNotifier(),
);

/// A provider that exposes the last 3 training sessions for the active language.
final recentSessionsProvider = FutureProvider.family<List<TrainingSession>, String>((ref, langCode) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getRecentSessions(3, languageCode: langCode);
});
