// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_meta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookMetaAdapter extends TypeAdapter<BookMeta> {
  @override
  final typeId = 0;

  @override
  BookMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookMeta(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      sourceFilePath: fields[3] as String,
      format: fields[4] as String,
      totalWords: (fields[5] as num).toInt(),
      addedAt: fields[7] as DateTime,
      lastOpenedAt: fields[8] as DateTime,
      currentWordIndex: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      coverImagePath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BookMeta obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.sourceFilePath)
      ..writeByte(4)
      ..write(obj.format)
      ..writeByte(5)
      ..write(obj.totalWords)
      ..writeByte(6)
      ..write(obj.currentWordIndex)
      ..writeByte(7)
      ..write(obj.addedAt)
      ..writeByte(8)
      ..write(obj.lastOpenedAt)
      ..writeByte(9)
      ..write(obj.coverImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
