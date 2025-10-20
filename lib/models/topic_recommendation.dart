import 'package:json_annotation/json_annotation.dart';

part 'topic_recommendation.g.dart';

@JsonSerializable()
class TopicRecommendationScores {
  final double accuracy;
  final double retention;
  final double speed;
  final double overall;

  const TopicRecommendationScores({
    required this.accuracy,
    required this.retention,
    required this.speed,
    required this.overall,
  });

  factory TopicRecommendationScores.fromJson(Map<String, dynamic> json) =>
      _$TopicRecommendationScoresFromJson(json);

  Map<String, dynamic> toJson() => _$TopicRecommendationScoresToJson(this);
}

@JsonSerializable()
class TopicRecommendation {
  final String topicId;
  final String topicName;
  final String recommendationReason;
  final DifficultyLevel recommendedDifficulty;
  final bool isKnowledgeGap;
  final bool needsReview;
  final TopicRecommendationScores? scores;

  const TopicRecommendation({
    required this.topicId,
    required this.topicName,
    required this.recommendationReason,
    required this.recommendedDifficulty,
    required this.isKnowledgeGap,
    required this.needsReview,
    this.scores,
  });

  factory TopicRecommendation.fromJson(Map<String, dynamic> json) =>
      _$TopicRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$TopicRecommendationToJson(this);
}

enum DifficultyLevel { beginner, intermediate, advanced, expert }
