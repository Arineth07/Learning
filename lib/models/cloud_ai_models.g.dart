// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_ai_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ABTestMetricsAdapter extends TypeAdapter<ABTestMetrics> {
  @override
  final int typeId = 17;

  @override
  ABTestMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ABTestMetrics(
      userId: fields[0] as String,
      group: fields[1] as String,
      assignedAt: fields[2] as DateTime,
      sessionsCompleted: fields[3] as int,
      averageAccuracy: fields[4] as double,
      averageSessionDuration: fields[5] as double,
      knowledgeGapsResolved: fields[6] as int,
      masteryGainRate: fields[7] as double,
      customMetrics: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ABTestMetrics obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.group)
      ..writeByte(2)
      ..write(obj.assignedAt)
      ..writeByte(3)
      ..write(obj.sessionsCompleted)
      ..writeByte(4)
      ..write(obj.averageAccuracy)
      ..writeByte(5)
      ..write(obj.averageSessionDuration)
      ..writeByte(6)
      ..write(obj.knowledgeGapsResolved)
      ..writeByte(7)
      ..write(obj.masteryGainRate)
      ..writeByte(8)
      ..write(obj.customMetrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ABTestMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
