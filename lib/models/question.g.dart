// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 12;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      text: fields[1] as String,
      correctAnswer: fields[3] as String,
      explanation: fields[4] as String,
      topicId: fields[5] as String,
      difficulty: fields[6] as DifficultyLevel,
      type: fields[7] as QuestionType,
      options: (fields[2] as List?)?.cast<String>(),
      estimatedTimeSeconds: fields[8] as int,
      points: fields[9] as int,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      isActive: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.correctAnswer)
      ..writeByte(4)
      ..write(obj.explanation)
      ..writeByte(5)
      ..write(obj.topicId)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(8)
      ..write(obj.estimatedTimeSeconds)
      ..writeByte(9)
      ..write(obj.points)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
