import 'package:hive_ce/hive.dart';

part 'trainer_profile.g.dart';

@HiveType(typeId: 1)
class TrainerProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String defaultLanguageCode;

  @HiveField(2)
  Map<String, TrainerLanguageProfile> languageProfiles;

  TrainerProfile({
    required this.id,
    this.defaultLanguageCode = 'en',
    required this.languageProfiles,
  });
}

@HiveType(typeId: 2)
class TrainerLanguageProfile extends HiveObject {
  @HiveField(0)
  final String languageCode;

  @HiveField(1)
  int currentLevel;

  @HiveField(2)
  int successfulSessionsInRow;

  @HiveField(3)
  int bestEffectiveWpm;

  @HiveField(4)
  DateTime? baselineCompletedAt;

  @HiveField(5)
  DateTime? lastSessionAt;

  TrainerLanguageProfile({
    required this.languageCode,
    this.currentLevel = 1,
    this.successfulSessionsInRow = 0,
    this.bestEffectiveWpm = 0,
    this.baselineCompletedAt,
    this.lastSessionAt,
  });
}
