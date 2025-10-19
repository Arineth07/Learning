import 'package:hive/hive.dart';

part 'learning_session.g.dart';

@HiveType(typeId: 16)
class LearningSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final List<String> topicIds;

  @HiveField(3)
  final List<String> questionIds;

  @HiveField(4)
  final Map<String, bool> questionResults; // questionId -> correct

  @HiveField(5)
  final Map<String, int> responseTimesSeconds; // questionId -> seconds

  @HiveField(6)
  final DateTime startTime;

  @HiveField(7)
  final DateTime? endTime;

  @HiveField(8)
  final int totalTimeSpentMinutes;

  @HiveField(9)
  final double accuracyRate;

  @HiveField(10)
  final bool isCompleted;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  LearningSession({
    required this.id,
    required this.userId,
    List<String>? topicIds,
    List<String>? questionIds,
    Map<String, bool>? questionResults,
    Map<String, int>? responseTimesSeconds,
    DateTime? startTime,
    this.endTime,
    this.totalTimeSpentMinutes = 0,
    this.accuracyRate = 0.0,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : topicIds = topicIds ?? [],
       questionIds = questionIds ?? [],
       questionResults = questionResults ?? {},
       responseTimesSeconds = responseTimesSeconds ?? {},
       startTime = startTime ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'topicIds': topicIds,
    'questionIds': questionIds,
    'questionResults': questionResults,
    'responseTimesSeconds': responseTimesSeconds,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'totalTimeSpentMinutes': totalTimeSpentMinutes,
    'accuracyRate': accuracyRate,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LearningSession.fromJson(Map<String, dynamic> json) =>
      LearningSession(
        id: json['id'] as String,
        userId: json['userId'] as String,
        topicIds: (json['topicIds'] as List?)?.cast<String>() ?? [],
        questionIds: (json['questionIds'] as List?)?.cast<String>() ?? [],
        questionResults:
            (json['questionResults'] as Map?)?.map(
              (key, value) => MapEntry(key as String, value as bool),
            ) ??
            {},
        responseTimesSeconds:
            (json['responseTimesSeconds'] as Map?)?.map(
              (key, value) => MapEntry(key as String, value as int),
            ) ??
            {},
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : null,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        totalTimeSpentMinutes: json['totalTimeSpentMinutes'] as int? ?? 0,
        accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
