import 'package:hive_ce/hive.dart';

part 'training_content.g.dart';

@HiveType(typeId: 5)
class TrainingText extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int level;

  @HiveField(3)
  final String languageCode;

  @HiveField(4)
  final int wordCount;

  @HiveField(5)
  final String topic;

  @HiveField(6)
  final String body;

  @HiveField(7)
  final List<ComprehensionQuestion> questions;

  TrainingText({
    required this.id,
    required this.title,
    required this.level,
    required this.languageCode,
    required this.wordCount,
    required this.topic,
    required this.body,
    required this.questions,
  });
}

@HiveType(typeId: 6)
class ComprehensionQuestion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String prompt;

  @HiveField(2)
  final List<String> options;

  @HiveField(3)
  final int correctOptionIndex;

  @HiveField(4)
  final String? explanation;

  ComprehensionQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });
}
