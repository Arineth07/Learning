import 'package:hive/hive.dart';
import 'enums.dart';

part 'performance_metrics.g.dart';

@HiveType(typeId: 14)
class PerformanceMetrics {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String subjectId;

  @HiveField(3)
  final Map<DifficultyLevel, double> accuracyRates;

  @HiveField(4)
  final Map<String, int> averageResponseTimes; // topicId -> seconds

  @HiveField(5)
  final Map<String, double> topicMasteryScores; // topicId -> score

  @HiveField(6)
  final List<String> strengthTopicIds;

  @HiveField(7)
  final List<String> weaknessTopicIds;

  @HiveField(8)
  final int totalQuestionsAttempted;

  @HiveField(9)
  final int totalCorrectAnswers;

  @HiveField(10)
  final DateTime lastUpdated;

  @HiveField(11)
  final DateTime createdAt;

  PerformanceMetrics({
    required this.id,
    required this.userId,
    required this.subjectId,
    Map<DifficultyLevel, double>? accuracyRates,
    Map<String, int>? averageResponseTimes,
    Map<String, double>? topicMasteryScores,
    List<String>? strengthTopicIds,
    List<String>? weaknessTopicIds,
    this.totalQuestionsAttempted = 0,
    this.totalCorrectAnswers = 0,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) : accuracyRates = accuracyRates ?? {},
       averageResponseTimes = averageResponseTimes ?? {},
       topicMasteryScores = topicMasteryScores ?? {},
       strengthTopicIds = strengthTopicIds ?? [],
       weaknessTopicIds = weaknessTopicIds ?? [],
       lastUpdated = lastUpdated ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'subjectId': subjectId,
    'accuracyRates': accuracyRates.map(
      (key, value) => MapEntry(key.toJson(), value),
    ),
    'averageResponseTimes': averageResponseTimes,
    'topicMasteryScores': topicMasteryScores,
    'strengthTopicIds': strengthTopicIds,
    'weaknessTopicIds': weaknessTopicIds,
    'totalQuestionsAttempted': totalQuestionsAttempted,
    'totalCorrectAnswers': totalCorrectAnswers,
    'lastUpdated': lastUpdated.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory PerformanceMetrics.fromJson(
    Map<String, dynamic> json,
  ) => PerformanceMetrics(
    id: json['id'] as String,
    userId: json['userId'] as String,
    subjectId: json['subjectId'] as String,
    accuracyRates:
        (json['accuracyRates'] as Map?)?.map(
          (key, value) => MapEntry(
            DifficultyLevel.fromJson(key as String),
            (value as num).toDouble(),
          ),
        ) ??
        {},
    averageResponseTimes:
        (json['averageResponseTimes'] as Map?)?.map(
          (key, value) => MapEntry(key as String, value as int),
        ) ??
        {},
    topicMasteryScores:
        (json['topicMasteryScores'] as Map?)?.map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ) ??
        {},
    strengthTopicIds: (json['strengthTopicIds'] as List?)?.cast<String>() ?? [],
    weaknessTopicIds: (json['weaknessTopicIds'] as List?)?.cast<String>() ?? [],
    totalQuestionsAttempted: json['totalQuestionsAttempted'] as int? ?? 0,
    totalCorrectAnswers: json['totalCorrectAnswers'] as int? ?? 0,
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'] as String)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
  );
}
