// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformanceMetricsAdapter extends TypeAdapter<PerformanceMetrics> {
  @override
  final int typeId = 14;

  @override
  PerformanceMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerformanceMetrics(
      id: fields[0] as String,
      userId: fields[1] as String,
      subjectId: fields[2] as String,
      accuracyRates: (fields[3] as Map?)?.cast<DifficultyLevel, double>(),
      averageResponseTimes: (fields[4] as Map?)?.cast<String, int>(),
      topicMasteryScores: (fields[5] as Map?)?.cast<String, double>(),
      strengthTopicIds: (fields[6] as List?)?.cast<String>(),
      weaknessTopicIds: (fields[7] as List?)?.cast<String>(),
      totalQuestionsAttempted: fields[8] as int,
      totalCorrectAnswers: fields[9] as int,
      lastUpdated: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceMetrics obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.accuracyRates)
      ..writeByte(4)
      ..write(obj.averageResponseTimes)
      ..writeByte(5)
      ..write(obj.topicMasteryScores)
      ..writeByte(6)
      ..write(obj.strengthTopicIds)
      ..writeByte(7)
      ..write(obj.weaknessTopicIds)
      ..writeByte(8)
      ..write(obj.totalQuestionsAttempted)
      ..writeByte(9)
      ..write(obj.totalCorrectAnswers)
      ..writeByte(10)
      ..write(obj.lastUpdated)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
