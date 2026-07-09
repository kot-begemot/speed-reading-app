// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trainer_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainerProfileAdapter extends TypeAdapter<TrainerProfile> {
  @override
  final typeId = 1;

  @override
  TrainerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainerProfile(
      id: fields[0] as String,
      defaultLanguageCode: fields[1] == null ? 'en' : fields[1] as String,
      languageProfiles: (fields[2] as Map)
          .cast<String, TrainerLanguageProfile>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrainerProfile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.defaultLanguageCode)
      ..writeByte(2)
      ..write(obj.languageProfiles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainerLanguageProfileAdapter
    extends TypeAdapter<TrainerLanguageProfile> {
  @override
  final typeId = 2;

  @override
  TrainerLanguageProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainerLanguageProfile(
      languageCode: fields[0] as String,
      currentLevel: fields[1] == null ? 1 : (fields[1] as num).toInt(),
      successfulSessionsInRow: fields[2] == null
          ? 0
          : (fields[2] as num).toInt(),
      bestEffectiveWpm: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      baselineCompletedAt: fields[4] as DateTime?,
      lastSessionAt: fields[5] as DateTime?,
      activeStepIndex: (fields[6] as num?)?.toInt(),
      activeSelectedTextId: fields[7] as String?,
      activeWarmUpErrors: (fields[8] as num?)?.toInt(),
      activeWarmUpDurationSecs: (fields[9] as num?)?.toInt(),
      activeRecognitionAccuracy: (fields[10] as num?)?.toInt(),
      activeRecognitionErrors: (fields[11] as num?)?.toInt(),
      activeReadingWpm: (fields[12] as num?)?.toInt(),
      activeWordsRead: (fields[13] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, TrainerLanguageProfile obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.languageCode)
      ..writeByte(1)
      ..write(obj.currentLevel)
      ..writeByte(2)
      ..write(obj.successfulSessionsInRow)
      ..writeByte(3)
      ..write(obj.bestEffectiveWpm)
      ..writeByte(4)
      ..write(obj.baselineCompletedAt)
      ..writeByte(5)
      ..write(obj.lastSessionAt)
      ..writeByte(6)
      ..write(obj.activeStepIndex)
      ..writeByte(7)
      ..write(obj.activeSelectedTextId)
      ..writeByte(8)
      ..write(obj.activeWarmUpErrors)
      ..writeByte(9)
      ..write(obj.activeWarmUpDurationSecs)
      ..writeByte(10)
      ..write(obj.activeRecognitionAccuracy)
      ..writeByte(11)
      ..write(obj.activeRecognitionErrors)
      ..writeByte(12)
      ..write(obj.activeReadingWpm)
      ..writeByte(13)
      ..write(obj.activeWordsRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerLanguageProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
