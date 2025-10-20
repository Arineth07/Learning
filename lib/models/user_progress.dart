import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 13)
class UserProgress {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final List<String> completedQuestionIds;

  @HiveField(4)
  final double averageScore;

  @HiveField(5)
  final int totalTimeSpentMinutes;

  @HiveField(6)
  final int totalAttempts;

  @HiveField(7)
  final int correctAttempts;

  @HiveField(8)
  final DateTime lastAttemptAt;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.topicId,
    List<String>? completedQuestionIds,
    this.averageScore = 0.0,
    this.totalTimeSpentMinutes = 0,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    DateTime? lastAttemptAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : completedQuestionIds = completedQuestionIds ?? [],
       lastAttemptAt = lastAttemptAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'topicId': topicId,
    'completedQuestionIds': completedQuestionIds,
    'averageScore': averageScore,
    'totalTimeSpentMinutes': totalTimeSpentMinutes,
    'totalAttempts': totalAttempts,
    'correctAttempts': correctAttempts,
    'lastAttemptAt': lastAttemptAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    id: json['id'] as String,
    userId: json['userId'] as String,
    topicId: json['topicId'] as String,
    completedQuestionIds:
        (json['completedQuestionIds'] as List?)?.cast<String>() ?? [],
    averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
    totalTimeSpentMinutes: json['totalTimeSpentMinutes'] as int? ?? 0,
    totalAttempts: json['totalAttempts'] as int? ?? 0,
    correctAttempts: json['correctAttempts'] as int? ?? 0,
    lastAttemptAt: json['lastAttemptAt'] != null
        ? DateTime.parse(json['lastAttemptAt'] as String)
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );

  // Time after which a topic should be reviewed (30 days)
  static const reviewIntervalDays = 30;

  // Time after which a topic with low score should be reviewed (14 days)
  static const lowScoreReviewIntervalDays = 14;

  bool get needsReview {
    final now = DateTime.now();
    final daysSinceLastAttempt = now.difference(lastAttemptAt).inDays;

    // If score is low, review more frequently
    if (averageScore < 0.8 &&
        daysSinceLastAttempt >= lowScoreReviewIntervalDays) {
      return true;
    }

    // Regular review interval for well-understood topics
    return daysSinceLastAttempt >= reviewIntervalDays;
  }
}
