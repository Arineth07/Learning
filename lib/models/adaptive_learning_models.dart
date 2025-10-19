import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'adaptive_learning_models.g.dart';

@JsonSerializable()
class DifficultyRecommendation {
  final DifficultyLevel currentDifficulty;
  final DifficultyLevel recommendedDifficulty;
  final String reason;
  final int consecutiveCorrect;
  final int consecutiveIncorrect;
  final double recentAccuracy;
  final bool shouldAdjust;

  const DifficultyRecommendation({
    required this.currentDifficulty,
    required this.recommendedDifficulty,
    required this.reason,
    required this.consecutiveCorrect,
    required this.consecutiveIncorrect,
    required this.recentAccuracy,
    required this.shouldAdjust,
  });

  factory DifficultyRecommendation.fromJson(Map<String, dynamic> json) =>
      _$DifficultyRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$DifficultyRecommendationToJson(this);
}

@JsonSerializable()
class TopicReviewSchedule {
  final String topicId;
  final String topicName;
  final DateTime lastAttemptAt;
  final DateTime nextReviewAt;
  final int daysSinceLastAttempt;
  final int daysUntilNextReview;
  final double masteryScore;
  final int priority;
  final bool isOverdue;

  const TopicReviewSchedule({
    required this.topicId,
    required this.topicName,
    required this.lastAttemptAt,
    required this.nextReviewAt,
    required this.daysSinceLastAttempt,
    required this.daysUntilNextReview,
    required this.masteryScore,
    required this.priority,
    required this.isOverdue,
  });

  factory TopicReviewSchedule.fromJson(Map<String, dynamic> json) =>
      _$TopicReviewScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$TopicReviewScheduleToJson(this);

  String getPriorityLabel() {
    switch (priority) {
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Critical';
      case 1: // Keeping for exhaustiveness, but not used in current logic
        return 'Low/Unknown';
      default:
        return 'Unknown';
    }
  }
}

@JsonSerializable()
class LearningPaceInsights {
  final String topicId;
  final String topicName;
  final double averageResponseTime;
  final double expectedResponseTime;
  final double paceRatio;
  final String paceCategory;
  final double accuracy;
  final String recommendation;

  const LearningPaceInsights({
    required this.topicId,
    required this.topicName,
    required this.averageResponseTime,
    required this.expectedResponseTime,
    required this.paceRatio,
    required this.paceCategory,
    required this.accuracy,
    required this.recommendation,
  });

  factory LearningPaceInsights.fromJson(Map<String, dynamic> json) =>
      _$LearningPaceInsightsFromJson(json);

  Map<String, dynamic> toJson() => _$LearningPaceInsightsToJson(this);

  bool isFast() => paceRatio < 0.7;
  bool isSlow() => paceRatio > 1.5;
}

@JsonSerializable()
class PerformanceTrend {
  final String userId;
  final String subjectId;
  final List<double> accuracyHistory;
  final List<DateTime> sessionDates;
  final String trendDirection;
  final double trendStrength;
  final double averageAccuracy;
  final double recentAccuracy;
  final String insight;

  const PerformanceTrend({
    required this.userId,
    required this.subjectId,
    required this.accuracyHistory,
    required this.sessionDates,
    required this.trendDirection,
    required this.trendStrength,
    required this.averageAccuracy,
    required this.recentAccuracy,
    required this.insight,
  });

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) =>
      _$PerformanceTrendFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceTrendToJson(this);

  bool isImproving() => trendDirection == 'Improving';
  bool isDeclining() => trendDirection == 'Declining';
}
