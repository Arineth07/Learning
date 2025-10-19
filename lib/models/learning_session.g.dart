// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LearningSessionAdapter extends TypeAdapter<LearningSession> {
  @override
  final int typeId = 16;

  @override
  LearningSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LearningSession(
      id: fields[0] as String,
      userId: fields[1] as String,
      topicIds: (fields[2] as List?)?.cast<String>(),
      questionIds: (fields[3] as List?)?.cast<String>(),
      questionResults: (fields[4] as Map?)?.cast<String, bool>(),
      responseTimesSeconds: (fields[5] as Map?)?.cast<String, int>(),
      startTime: fields[6] as DateTime?,
      endTime: fields[7] as DateTime?,
      totalTimeSpentMinutes: fields[8] as int,
      accuracyRate: fields[9] as double,
      isCompleted: fields[10] as bool,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LearningSession obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.topicIds)
      ..writeByte(3)
      ..write(obj.questionIds)
      ..writeByte(4)
      ..write(obj.questionResults)
      ..writeByte(5)
      ..write(obj.responseTimesSeconds)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.totalTimeSpentMinutes)
      ..writeByte(9)
      ..write(obj.accuracyRate)
      ..writeByte(10)
      ..write(obj.isCompleted)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
