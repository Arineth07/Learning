// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 0;

  @override
  DifficultyLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DifficultyLevel.beginner;
      case 1:
        return DifficultyLevel.intermediate;
      case 2:
        return DifficultyLevel.advanced;
      case 3:
        return DifficultyLevel.expert;
      default:
        return DifficultyLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, DifficultyLevel obj) {
    switch (obj) {
      case DifficultyLevel.beginner:
        writer.writeByte(0);
        break;
      case DifficultyLevel.intermediate:
        writer.writeByte(1);
        break;
      case DifficultyLevel.advanced:
        writer.writeByte(2);
        break;
      case DifficultyLevel.expert:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestionTypeAdapter extends TypeAdapter<QuestionType> {
  @override
  final int typeId = 1;

  @override
  QuestionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionType.multipleChoice;
      case 1:
        return QuestionType.trueFalse;
      case 2:
        return QuestionType.shortAnswer;
      case 3:
        return QuestionType.essay;
      case 4:
        return QuestionType.coding;
      default:
        return QuestionType.multipleChoice;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionType obj) {
    switch (obj) {
      case QuestionType.multipleChoice:
        writer.writeByte(0);
        break;
      case QuestionType.trueFalse:
        writer.writeByte(1);
        break;
      case QuestionType.shortAnswer:
        writer.writeByte(2);
        break;
      case QuestionType.essay:
        writer.writeByte(3);
        break;
      case QuestionType.coding:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubjectCategoryAdapter extends TypeAdapter<SubjectCategory> {
  @override
  final int typeId = 2;

  @override
  SubjectCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SubjectCategory.mathematics;
      case 1:
        return SubjectCategory.programming;
      case 2:
        return SubjectCategory.science;
      case 3:
        return SubjectCategory.language;
      case 4:
        return SubjectCategory.history;
      default:
        return SubjectCategory.mathematics;
    }
  }

  @override
  void write(BinaryWriter writer, SubjectCategory obj) {
    switch (obj) {
      case SubjectCategory.mathematics:
        writer.writeByte(0);
        break;
      case SubjectCategory.programming:
        writer.writeByte(1);
        break;
      case SubjectCategory.science:
        writer.writeByte(2);
        break;
      case SubjectCategory.language:
        writer.writeByte(3);
        break;
      case SubjectCategory.history:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GapSeverityAdapter extends TypeAdapter<GapSeverity> {
  @override
  final int typeId = 3;

  @override
  GapSeverity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GapSeverity.low;
      case 1:
        return GapSeverity.medium;
      case 2:
        return GapSeverity.high;
      case 3:
        return GapSeverity.critical;
      default:
        return GapSeverity.low;
    }
  }

  @override
  void write(BinaryWriter writer, GapSeverity obj) {
    switch (obj) {
      case GapSeverity.low:
        writer.writeByte(0);
        break;
      case GapSeverity.medium:
        writer.writeByte(1);
        break;
      case GapSeverity.high:
        writer.writeByte(2);
        break;
      case GapSeverity.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GapSeverityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
