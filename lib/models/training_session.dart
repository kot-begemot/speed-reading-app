import 'package:hive_ce/hive.dart';

part 'training_session.g.dart';

@HiveType(typeId: 3)
class TrainingSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String languageCode;

  @HiveField(2)
  final DateTime startedAt;

  @HiveField(3)
  DateTime? completedAt;

  @HiveField(4)
  final int level;

  @HiveField(5)
  String? textId;

  @HiveField(6)
  List<ExerciseResult> exerciseResults;

  @HiveField(7)
  int finalWpm;

  @HiveField(8)
  int comprehensionPercent;

  @HiveField(9)
  int effectiveWpm;

  @HiveField(10)
  bool qualified;

  @HiveField(11)
  String? failReason;

  TrainingSession({
    required this.id,
    required this.languageCode,
    required this.startedAt,
    this.completedAt,
    required this.level,
    this.textId,
    required this.exerciseResults,
    this.finalWpm = 0,
    this.comprehensionPercent = 0,
    this.effectiveWpm = 0,
    this.qualified = false,
    this.failReason,
  });
}

@HiveType(typeId: 4)
class ExerciseResult extends HiveObject {
  @HiveField(0)
  final String exerciseType;

  @HiveField(1)
  final String? languageCode;

  @HiveField(2)
  final String? textId;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final int difficulty;

  @HiveField(5)
  final double? accuracyPercent;

  @HiveField(6)
  final double? reactionTimeMs;

  @HiveField(7)
  final int? wpm;

  @HiveField(8)
  final int? comprehensionPercent;

  @HiveField(9)
  final int? mistakes;

  @HiveField(10)
  final bool completed;

  @HiveField(11)
  final bool qualified;

  ExerciseResult({
    required this.exerciseType,
    this.languageCode,
    this.textId,
    required this.durationSeconds,
    required this.difficulty,
    this.accuracyPercent,
    this.reactionTimeMs,
    this.wpm,
    this.comprehensionPercent,
    this.mistakes,
    this.completed = false,
    this.qualified = false,
  });
}
