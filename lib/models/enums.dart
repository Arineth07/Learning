import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 0)
enum DifficultyLevel {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced,
  @HiveField(3)
  expert;

  String toJson() => name;
  static DifficultyLevel fromJson(String json) => values.byName(json);
}

@HiveType(typeId: 1)
enum QuestionType {
  @HiveField(0)
  multipleChoice,
  @HiveField(1)
  trueFalse,
  @HiveField(2)
  shortAnswer,
  @HiveField(3)
  essay,
  @HiveField(4)
  coding;

  String toJson() => name;
  static QuestionType fromJson(String json) => values.byName(json);
}

@HiveType(typeId: 2)
enum SubjectCategory {
  @HiveField(0)
  mathematics,
  @HiveField(1)
  programming,
  @HiveField(2)
  science,
  @HiveField(3)
  language,
  @HiveField(4)
  history;

  String toJson() => name;
  static SubjectCategory fromJson(String json) => values.byName(json);
}

@HiveType(typeId: 3)
enum GapSeverity {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  critical;

  String toJson() => name;
  static GapSeverity fromJson(String json) => values.byName(json);
}
