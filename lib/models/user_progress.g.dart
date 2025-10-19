// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 13;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      id: fields[0] as String,
      userId: fields[1] as String,
      topicId: fields[2] as String,
      completedQuestionIds: (fields[3] as List?)?.cast<String>(),
      averageScore: fields[4] as double,
      totalTimeSpentMinutes: fields[5] as int,
      totalAttempts: fields[6] as int,
      correctAttempts: fields[7] as int,
      lastAttemptAt: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.topicId)
      ..writeByte(3)
      ..write(obj.completedQuestionIds)
      ..writeByte(4)
      ..write(obj.averageScore)
      ..writeByte(5)
      ..write(obj.totalTimeSpentMinutes)
      ..writeByte(6)
      ..write(obj.totalAttempts)
      ..writeByte(7)
      ..write(obj.correctAttempts)
      ..writeByte(8)
      ..write(obj.lastAttemptAt)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
