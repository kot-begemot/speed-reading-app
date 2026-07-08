// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingSessionAdapter extends TypeAdapter<TrainingSession> {
  @override
  final typeId = 3;

  @override
  TrainingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingSession(
      id: fields[0] as String,
      languageCode: fields[1] as String,
      startedAt: fields[2] as DateTime,
      completedAt: fields[3] as DateTime?,
      level: (fields[4] as num).toInt(),
      textId: fields[5] as String?,
      exerciseResults: (fields[6] as List).cast<ExerciseResult>(),
      finalWpm: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      comprehensionPercent: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      effectiveWpm: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      qualified: fields[10] == null ? false : fields[10] as bool,
      failReason: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingSession obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.textId)
      ..writeByte(6)
      ..write(obj.exerciseResults)
      ..writeByte(7)
      ..write(obj.finalWpm)
      ..writeByte(8)
      ..write(obj.comprehensionPercent)
      ..writeByte(9)
      ..write(obj.effectiveWpm)
      ..writeByte(10)
      ..write(obj.qualified)
      ..writeByte(11)
      ..write(obj.failReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseResultAdapter extends TypeAdapter<ExerciseResult> {
  @override
  final typeId = 4;

  @override
  ExerciseResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseResult(
      exerciseType: fields[0] as String,
      languageCode: fields[1] as String?,
      textId: fields[2] as String?,
      durationSeconds: (fields[3] as num).toInt(),
      difficulty: (fields[4] as num).toInt(),
      accuracyPercent: (fields[5] as num?)?.toDouble(),
      reactionTimeMs: (fields[6] as num?)?.toDouble(),
      wpm: (fields[7] as num?)?.toInt(),
      comprehensionPercent: (fields[8] as num?)?.toInt(),
      mistakes: (fields[9] as num?)?.toInt(),
      completed: fields[10] == null ? false : fields[10] as bool,
      qualified: fields[11] == null ? false : fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseResult obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.exerciseType)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.textId)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.difficulty)
      ..writeByte(5)
      ..write(obj.accuracyPercent)
      ..writeByte(6)
      ..write(obj.reactionTimeMs)
      ..writeByte(7)
      ..write(obj.wpm)
      ..writeByte(8)
      ..write(obj.comprehensionPercent)
      ..writeByte(9)
      ..write(obj.mistakes)
      ..writeByte(10)
      ..write(obj.completed)
      ..writeByte(11)
      ..write(obj.qualified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
