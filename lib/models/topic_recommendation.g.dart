// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicRecommendationScores _$TopicRecommendationScoresFromJson(
        Map<String, dynamic> json) =>
    TopicRecommendationScores(
      accuracy: (json['accuracy'] as num).toDouble(),
      retention: (json['retention'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      overall: (json['overall'] as num).toDouble(),
    );

Map<String, dynamic> _$TopicRecommendationScoresToJson(
        TopicRecommendationScores instance) =>
    <String, dynamic>{
      'accuracy': instance.accuracy,
      'retention': instance.retention,
      'speed': instance.speed,
      'overall': instance.overall,
    };

TopicRecommendation _$TopicRecommendationFromJson(Map<String, dynamic> json) =>
    TopicRecommendation(
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      recommendationReason: json['recommendationReason'] as String,
      recommendedDifficulty:
          $enumDecode(_$DifficultyLevelEnumMap, json['recommendedDifficulty']),
      isKnowledgeGap: json['isKnowledgeGap'] as bool,
      needsReview: json['needsReview'] as bool,
      scores: json['scores'] == null
          ? null
          : TopicRecommendationScores.fromJson(
              json['scores'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TopicRecommendationToJson(
        TopicRecommendation instance) =>
    <String, dynamic>{
      'topicId': instance.topicId,
      'topicName': instance.topicName,
      'recommendationReason': instance.recommendationReason,
      'recommendedDifficulty':
          _$DifficultyLevelEnumMap[instance.recommendedDifficulty]!,
      'isKnowledgeGap': instance.isKnowledgeGap,
      'needsReview': instance.needsReview,
      'scores': instance.scores,
    };

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
  DifficultyLevel.expert: 'expert',
};
