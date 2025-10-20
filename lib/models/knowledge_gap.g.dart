// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_gap.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KnowledgeGapAdapter extends TypeAdapter<KnowledgeGap> {
  @override
  final int typeId = 15;

  @override
  KnowledgeGap read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KnowledgeGap(
      id: fields[0] as String,
      userId: fields[1] as String,
      topicId: fields[2] as String,
      description: fields[3] as String,
      severity: fields[4] as GapSeverity,
      relatedTopicIds: (fields[5] as List?)?.cast<String>(),
      recommendedQuestionIds: (fields[6] as List?)?.cast<String>(),
      isResolved: fields[7] as bool,
      identifiedAt: fields[8] as DateTime?,
      resolvedAt: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, KnowledgeGap obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.topicId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.relatedTopicIds)
      ..writeByte(6)
      ..write(obj.recommendedQuestionIds)
      ..writeByte(7)
      ..write(obj.isResolved)
      ..writeByte(8)
      ..write(obj.identifiedAt)
      ..writeByte(9)
      ..write(obj.resolvedAt)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeGapAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
