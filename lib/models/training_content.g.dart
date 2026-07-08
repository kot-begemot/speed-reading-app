// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingTextAdapter extends TypeAdapter<TrainingText> {
  @override
  final typeId = 5;

  @override
  TrainingText read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingText(
      id: fields[0] as String,
      title: fields[1] as String,
      level: (fields[2] as num).toInt(),
      languageCode: fields[3] as String,
      wordCount: (fields[4] as num).toInt(),
      topic: fields[5] as String,
      body: fields[6] as String,
      questions: (fields[7] as List).cast<ComprehensionQuestion>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrainingText obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.languageCode)
      ..writeByte(4)
      ..write(obj.wordCount)
      ..writeByte(5)
      ..write(obj.topic)
      ..writeByte(6)
      ..write(obj.body)
      ..writeByte(7)
      ..write(obj.questions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingTextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ComprehensionQuestionAdapter extends TypeAdapter<ComprehensionQuestion> {
  @override
  final typeId = 6;

  @override
  ComprehensionQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComprehensionQuestion(
      id: fields[0] as String,
      prompt: fields[1] as String,
      options: (fields[2] as List).cast<String>(),
      correctOptionIndex: (fields[3] as num).toInt(),
      explanation: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComprehensionQuestion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.prompt)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctOptionIndex)
      ..writeByte(4)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComprehensionQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
