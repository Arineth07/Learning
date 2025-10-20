import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';
import '../models/recommendation_models.dart';

part 'cloud_ai_models.g.dart';

class CloudAIRequest {
  final String userId;
  final String requestId;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  CloudAIRequest({
    required this.userId,
    required this.requestId,
    required this.timestamp,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'requestId': requestId,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };

  factory CloudAIRequest.create(
    String userId, [
    Map<String, dynamic>? context,
  ]) {
    final id = const SimpleUuid().v4();
    return CloudAIRequest(
      userId: userId,
      requestId: id,
      timestamp: DateTime.now().toUtc(),
      context: context ?? {},
    );
  }
}

class CloudAITopicRequest extends CloudAIRequest {
  final String subjectId;
  final List<Map<String, dynamic>> performanceHistory;
  final List<Map<String, dynamic>> knowledgeGaps;
  final Map<String, double> topicMasteryScores;
  final String? currentTopicId;

  CloudAITopicRequest({
    required String userId,
    required String requestId,
    required DateTime timestamp,
    Map<String, dynamic>? context,
    required this.subjectId,
    required this.performanceHistory,
    required this.knowledgeGaps,
    required this.topicMasteryScores,
    this.currentTopicId,
  }) : super(
         userId: userId,
         requestId: requestId,
         timestamp: timestamp,
         context: context ?? {},
       );

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'subjectId': subjectId,
      'performanceHistory': performanceHistory,
      'knowledgeGaps': knowledgeGaps,
      'topicMasteryScores': topicMasteryScores,
      'currentTopicId': currentTopicId,
    });
    return base;
  }

  factory CloudAITopicRequest.fromUserData({
    required String userId,
    required String subjectId,
    List<Map<String, dynamic>>? performanceHistory,
    List<Map<String, dynamic>>? knowledgeGaps,
    Map<String, double>? topicMasteryScores,
    String? currentTopicId,
  }) {
    return CloudAITopicRequest(
      userId: userId,
      requestId: const SimpleUuid().v4(),
      timestamp: DateTime.now().toUtc(),
      subjectId: subjectId,
      performanceHistory: performanceHistory ?? [],
      knowledgeGaps: knowledgeGaps ?? [],
      topicMasteryScores: topicMasteryScores ?? {},
      currentTopicId: currentTopicId,
    );
  }
}

class CloudAIResponse {
  final String requestId;
  final bool success;
  final double confidenceScore;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  CloudAIResponse({
    required this.requestId,
    required this.success,
    required this.confidenceScore,
    this.errorMessage,
    required this.timestamp,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  factory CloudAIResponse.fromJson(Map<String, dynamic> json) {
    return CloudAIResponse(
      requestId: json['requestId'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['errorMessage'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  bool isHighConfidence() =>
      confidenceScore >= CloudAIConstants.highConfidenceThreshold;
  bool shouldFallback() =>
      confidenceScore < CloudAIConstants.minimumConfidenceScore;
}

class CloudAITopicRecommendation extends CloudAIResponse {
  final TopicRecommendation recommendation;
  final List<String> aiInsights;
  final Map<String, double> alternativeScores;
  final String reasoning;
  final List<String> suggestedPrerequisites;

  CloudAITopicRecommendation({
    required String requestId,
    required bool success,
    required double confidenceScore,
    String? errorMessage,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
    required this.recommendation,
    this.aiInsights = const [],
    this.alternativeScores = const {},
    this.reasoning = '',
    this.suggestedPrerequisites = const [],
  }) : super(
         requestId: requestId,
         success: success,
         confidenceScore: confidenceScore,
         errorMessage: errorMessage,
         timestamp: timestamp,
         metadata: metadata,
       );

  factory CloudAITopicRecommendation.fromJson(Map<String, dynamic> json) {
    final base = CloudAIResponse.fromJson(json);
    final recJson = json['recommendation'] as Map<String, dynamic>? ?? {};
    return CloudAITopicRecommendation(
      requestId: base.requestId,
      success: base.success,
      confidenceScore: base.confidenceScore,
      errorMessage: base.errorMessage,
      timestamp: base.timestamp,
      metadata: base.metadata,
      recommendation: TopicRecommendation.fromJson(recJson),
      aiInsights: (json['aiInsights'] as List<dynamic>?)?.cast<String>() ?? [],
      alternativeScores:
          (json['alternativeScores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      reasoning: json['reasoning'] as String? ?? '',
      suggestedPrerequisites:
          (json['suggestedPrerequisites'] as List<dynamic>?)?.cast<String>() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'success': success,
      'confidenceScore': confidenceScore,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'recommendation': recommendation.toJson(),
      'aiInsights': aiInsights,
      'alternativeScores': alternativeScores,
      'reasoning': reasoning,
      'suggestedPrerequisites': suggestedPrerequisites,
    };
  }
}

class CloudAIPracticeRecommendation extends CloudAIResponse {
  final PersonalizedQuestionSet questionSet;
  final List<String> aiInsights;
  final Map<String, double> questionDifficultyPredictions;
  final String practiceStrategy;
  final int estimatedMasteryGain;

  CloudAIPracticeRecommendation({
    required String requestId,
    required bool success,
    required double confidenceScore,
    String? errorMessage,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
    required this.questionSet,
    this.aiInsights = const [],
    this.questionDifficultyPredictions = const {},
    this.practiceStrategy = '',
    this.estimatedMasteryGain = 0,
  }) : super(
         requestId: requestId,
         success: success,
         confidenceScore: confidenceScore,
         errorMessage: errorMessage,
         timestamp: timestamp,
         metadata: metadata,
       );

  factory CloudAIPracticeRecommendation.fromJson(Map<String, dynamic> json) {
    final base = CloudAIResponse.fromJson(json);
    final qsJson = json['questionSet'] as Map<String, dynamic>? ?? {};
    return CloudAIPracticeRecommendation(
      requestId: base.requestId,
      success: base.success,
      confidenceScore: base.confidenceScore,
      errorMessage: base.errorMessage,
      timestamp: base.timestamp,
      metadata: base.metadata,
      questionSet: PersonalizedQuestionSet.fromJson(qsJson),
      aiInsights: (json['aiInsights'] as List<dynamic>?)?.cast<String>() ?? [],
      questionDifficultyPredictions:
          (json['questionDifficultyPredictions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      practiceStrategy: json['practiceStrategy'] as String? ?? '',
      estimatedMasteryGain:
          (json['estimatedMasteryGain'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'success': success,
      'confidenceScore': confidenceScore,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'questionSet': questionSet.toJson(),
      'aiInsights': aiInsights,
      'questionDifficultyPredictions': questionDifficultyPredictions,
      'practiceStrategy': practiceStrategy,
      'estimatedMasteryGain': estimatedMasteryGain,
    };
  }
}

class CloudAILearningPath extends CloudAIResponse {
  final LearningPath path;
  final List<String> aiInsights;
  final Map<String, String> stepRationale;
  final double predictedCompletionDays;
  final List<String> riskFactors;

  CloudAILearningPath({
    required String requestId,
    required bool success,
    required double confidenceScore,
    String? errorMessage,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
    required this.path,
    this.aiInsights = const [],
    this.stepRationale = const {},
    this.predictedCompletionDays = 0.0,
    this.riskFactors = const [],
  }) : super(
         requestId: requestId,
         success: success,
         confidenceScore: confidenceScore,
         errorMessage: errorMessage,
         timestamp: timestamp,
         metadata: metadata,
       );

  factory CloudAILearningPath.fromJson(Map<String, dynamic> json) {
    final base = CloudAIResponse.fromJson(json);
    final pathJson = json['path'] as Map<String, dynamic>? ?? {};
    return CloudAILearningPath(
      requestId: base.requestId,
      success: base.success,
      confidenceScore: base.confidenceScore,
      errorMessage: base.errorMessage,
      timestamp: base.timestamp,
      metadata: base.metadata,
      path: LearningPath.fromJson(pathJson),
      aiInsights: (json['aiInsights'] as List<dynamic>?)?.cast<String>() ?? [],
      stepRationale:
          (json['stepRationale'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      predictedCompletionDays:
          (json['predictedCompletionDays'] as num?)?.toDouble() ?? 0.0,
      riskFactors:
          (json['riskFactors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'success': success,
      'confidenceScore': confidenceScore,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'path': path.toJson(),
      'aiInsights': aiInsights,
      'stepRationale': stepRationale,
      'predictedCompletionDays': predictedCompletionDays,
      'riskFactors': riskFactors,
    };
  }
}

class CachedCloudAIResponse {
  final String cacheKey;
  final Map<String, dynamic> responseData;
  final DateTime cachedAt;
  final DateTime expiresAt;
  int hitCount;

  CachedCloudAIResponse({
    required this.cacheKey,
    required this.responseData,
    required this.cachedAt,
    required this.expiresAt,
    this.hitCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'cacheKey': cacheKey,
    'responseData': responseData,
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'hitCount': hitCount,
  };

  factory CachedCloudAIResponse.fromJson(Map<String, dynamic> json) {
    return CachedCloudAIResponse(
      cacheKey: json['cacheKey'] as String? ?? '',
      responseData: (json['responseData'] as Map<String, dynamic>?) ?? {},
      cachedAt:
          DateTime.tryParse(json['cachedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      hitCount: (json['hitCount'] as num?)?.toInt() ?? 0,
    );
  }

  bool isExpired() => DateTime.now().toUtc().isAfter(expiresAt);
  bool isValid() => !isExpired() && responseData.isNotEmpty;
}

@HiveType(typeId: 17)
class ABTestMetrics extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String group;
  @HiveField(2)
  final DateTime assignedAt;
  @HiveField(3)
  int sessionsCompleted;
  @HiveField(4)
  double averageAccuracy;
  @HiveField(5)
  double averageSessionDuration;
  @HiveField(6)
  int knowledgeGapsResolved;
  @HiveField(7)
  double masteryGainRate;
  @HiveField(8)
  Map<String, dynamic> customMetrics;

  ABTestMetrics({
    required this.userId,
    required this.group,
    required this.assignedAt,
    this.sessionsCompleted = 0,
    this.averageAccuracy = 0.0,
    this.averageSessionDuration = 0.0,
    this.knowledgeGapsResolved = 0,
    this.masteryGainRate = 0.0,
    Map<String, dynamic>? customMetrics,
  }) : customMetrics = customMetrics ?? {};

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'group': group,
    'assignedAt': assignedAt.toIso8601String(),
    'sessionsCompleted': sessionsCompleted,
    'averageAccuracy': averageAccuracy,
    'averageSessionDuration': averageSessionDuration,
    'knowledgeGapsResolved': knowledgeGapsResolved,
    'masteryGainRate': masteryGainRate,
    'customMetrics': customMetrics,
  };

  factory ABTestMetrics.fromJson(Map<String, dynamic> json) => ABTestMetrics(
    userId: json['userId'] as String,
    group: json['group'] as String,
    assignedAt:
        DateTime.tryParse(json['assignedAt'] as String? ?? '') ??
        DateTime.now().toUtc(),
    sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
    averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
    averageSessionDuration:
        (json['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
    knowledgeGapsResolved:
        (json['knowledgeGapsResolved'] as num?)?.toInt() ?? 0,
    masteryGainRate: (json['masteryGainRate'] as num?)?.toDouble() ?? 0.0,
    customMetrics: (json['customMetrics'] as Map<String, dynamic>?) ?? {},
  );
}

enum ABTestGroup { ruleBased, cloudAI, hybrid }

extension ABTestGroupExt on ABTestGroup {
  String toJson() {
    switch (this) {
      case ABTestGroup.ruleBased:
        return 'rule_based';
      case ABTestGroup.cloudAI:
        return 'cloud_ai';
      case ABTestGroup.hybrid:
        return 'hybrid';
    }
  }

  static ABTestGroup fromJson(String value) {
    switch (value) {
      case 'rule_based':
        return ABTestGroup.ruleBased;
      case 'cloud_ai':
        return ABTestGroup.cloudAI;
      case 'hybrid':
      default:
        return ABTestGroup.hybrid;
    }
  }

  bool usesCloudAI() =>
      this == ABTestGroup.cloudAI || this == ABTestGroup.hybrid;
  bool usesRuleBased() =>
      this == ABTestGroup.ruleBased || this == ABTestGroup.hybrid;
}

// Simple UUID helper to avoid adding package dependency automatically
class SimpleUuid {
  const SimpleUuid();
  String v4() {
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(now);
    return sha1.convert(bytes).toString();
  }
}
