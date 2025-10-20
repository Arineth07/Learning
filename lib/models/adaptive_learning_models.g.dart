// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adaptive_learning_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DifficultyRecommendation _$DifficultyRecommendationFromJson(
  Map<String, dynamic> json,
) => DifficultyRecommendation(
  currentDifficulty: $enumDecode(
    _$DifficultyLevelEnumMap,
    json['currentDifficulty'],
  ),
  recommendedDifficulty: $enumDecode(
    _$DifficultyLevelEnumMap,
    json['recommendedDifficulty'],
  ),
  reason: json['reason'] as String,
  consecutiveCorrect: (json['consecutiveCorrect'] as num).toInt(),
  consecutiveIncorrect: (json['consecutiveIncorrect'] as num).toInt(),
  recentAccuracy: (json['recentAccuracy'] as num).toDouble(),
  shouldAdjust: json['shouldAdjust'] as bool,
);

Map<String, dynamic> _$DifficultyRecommendationToJson(
  DifficultyRecommendation instance,
) => <String, dynamic>{
  'currentDifficulty': instance.currentDifficulty,
  'recommendedDifficulty': instance.recommendedDifficulty,
  'reason': instance.reason,
  'consecutiveCorrect': instance.consecutiveCorrect,
  'consecutiveIncorrect': instance.consecutiveIncorrect,
  'recentAccuracy': instance.recentAccuracy,
  'shouldAdjust': instance.shouldAdjust,
};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
  DifficultyLevel.expert: 'expert',
};

TopicReviewSchedule _$TopicReviewScheduleFromJson(Map<String, dynamic> json) =>
    TopicReviewSchedule(
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      lastAttemptAt: DateTime.parse(json['lastAttemptAt'] as String),
      nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
      daysSinceLastAttempt: (json['daysSinceLastAttempt'] as num).toInt(),
      daysUntilNextReview: (json['daysUntilNextReview'] as num).toInt(),
      masteryScore: (json['masteryScore'] as num).toDouble(),
      priority: (json['priority'] as num).toInt(),
      isOverdue: json['isOverdue'] as bool,
    );

Map<String, dynamic> _$TopicReviewScheduleToJson(
  TopicReviewSchedule instance,
) => <String, dynamic>{
  'topicId': instance.topicId,
  'topicName': instance.topicName,
  'lastAttemptAt': instance.lastAttemptAt.toIso8601String(),
  'nextReviewAt': instance.nextReviewAt.toIso8601String(),
  'daysSinceLastAttempt': instance.daysSinceLastAttempt,
  'daysUntilNextReview': instance.daysUntilNextReview,
  'masteryScore': instance.masteryScore,
  'priority': instance.priority,
  'isOverdue': instance.isOverdue,
};

LearningPaceInsights _$LearningPaceInsightsFromJson(
  Map<String, dynamic> json,
) => LearningPaceInsights(
  topicId: json['topicId'] as String,
  topicName: json['topicName'] as String,
  averageResponseTime: (json['averageResponseTime'] as num).toDouble(),
  expectedResponseTime: (json['expectedResponseTime'] as num).toDouble(),
  paceRatio: (json['paceRatio'] as num).toDouble(),
  paceCategory: json['paceCategory'] as String,
  accuracy: (json['accuracy'] as num).toDouble(),
  recommendation: json['recommendation'] as String,
);

Map<String, dynamic> _$LearningPaceInsightsToJson(
  LearningPaceInsights instance,
) => <String, dynamic>{
  'topicId': instance.topicId,
  'topicName': instance.topicName,
  'averageResponseTime': instance.averageResponseTime,
  'expectedResponseTime': instance.expectedResponseTime,
  'paceRatio': instance.paceRatio,
  'paceCategory': instance.paceCategory,
  'accuracy': instance.accuracy,
  'recommendation': instance.recommendation,
};

PerformanceTrend _$PerformanceTrendFromJson(Map<String, dynamic> json) =>
    PerformanceTrend(
      userId: json['userId'] as String,
      subjectId: json['subjectId'] as String,
      accuracyHistory: (json['accuracyHistory'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      sessionDates: (json['sessionDates'] as List<dynamic>)
          .map((e) => DateTime.parse(e as String))
          .toList(),
      trendDirection: json['trendDirection'] as String,
      trendStrength: (json['trendStrength'] as num).toDouble(),
      averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
      recentAccuracy: (json['recentAccuracy'] as num).toDouble(),
      insight: json['insight'] as String,
    );

Map<String, dynamic> _$PerformanceTrendToJson(PerformanceTrend instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'subjectId': instance.subjectId,
      'accuracyHistory': instance.accuracyHistory,
      'sessionDates': instance.sessionDates
          .map((e) => e.toIso8601String())
          .toList(),
      'trendDirection': instance.trendDirection,
      'trendStrength': instance.trendStrength,
      'averageAccuracy': instance.averageAccuracy,
      'recentAccuracy': instance.recentAccuracy,
      'insight': instance.insight,
    };
