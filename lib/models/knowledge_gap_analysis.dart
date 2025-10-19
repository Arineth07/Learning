import 'package:ai_tutor_app/models/enums.dart';

/// Represents the result of analyzing a topic for knowledge gaps.
class GapAnalysisResult {
  final String topicId;
  final String topicName;
  final bool hasGap;
  final GapSeverity? severity;
  final double accuracyScore;
  final double paceScore;
  final double consistencyScore;
  final double compositeScore;
  final String analysisReason;
  final List<String> weaknessIndicators;
  final DateTime analyzedAt;

  GapAnalysisResult({
    required this.topicId,
    required this.topicName,
    required this.hasGap,
    this.severity,
    required this.accuracyScore,
    required this.paceScore,
    required this.consistencyScore,
    required this.compositeScore,
    required this.analysisReason,
    required this.weaknessIndicators,
    required this.analyzedAt,
  });

  factory GapAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GapAnalysisResult(
      topicId: json['topicId'],
      topicName: json['topicName'],
      hasGap: json['hasGap'],
      severity: json['severity'] != null
          ? GapSeverity.values.firstWhere(
              (e) => e.toString() == json['severity'],
            )
          : null,
      accuracyScore: json['accuracyScore'],
      paceScore: json['paceScore'],
      consistencyScore: json['consistencyScore'],
      compositeScore: json['compositeScore'],
      analysisReason: json['analysisReason'],
      weaknessIndicators: List<String>.from(json['weaknessIndicators']),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'topicName': topicName,
    'hasGap': hasGap,
    'severity': severity?.toString(),
    'accuracyScore': accuracyScore,
    'paceScore': paceScore,
    'consistencyScore': consistencyScore,
    'compositeScore': compositeScore,
    'analysisReason': analysisReason,
    'weaknessIndicators': weaknessIndicators,
    'analyzedAt': analyzedAt.toIso8601String(),
  };

  /// Returns the appropriate severity level based on a composite score.
  static GapSeverity getSeverityFromScore(double score) {
    if (score >= 0.8) return GapSeverity.critical;
    if (score >= 0.6) return GapSeverity.high;
    if (score >= 0.4) return GapSeverity.medium;
    return GapSeverity.low;
  }
}

/// Represents a targeted practice recommendation for addressing a knowledge gap.
class TargetedPracticeRecommendation {
  final String gapId;
  final String topicId;
  final List<String> questionIds;
  final List<String> prerequisiteTopicIds;
  final DifficultyLevel recommendedDifficulty;
  final String practiceStrategy;
  final int estimatedPracticeMinutes;
  final int priorityScore;

  TargetedPracticeRecommendation({
    required this.gapId,
    required this.topicId,
    required this.questionIds,
    required this.prerequisiteTopicIds,
    required this.recommendedDifficulty,
    required this.practiceStrategy,
    required this.estimatedPracticeMinutes,
    required this.priorityScore,
  });

  factory TargetedPracticeRecommendation.fromJson(Map<String, dynamic> json) {
    return TargetedPracticeRecommendation(
      gapId: json['gapId'],
      topicId: json['topicId'],
      questionIds: List<String>.from(json['questionIds']),
      prerequisiteTopicIds: List<String>.from(json['prerequisiteTopicIds']),
      recommendedDifficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == json['recommendedDifficulty'],
      ),
      practiceStrategy: json['practiceStrategy'],
      estimatedPracticeMinutes: json['estimatedPracticeMinutes'],
      priorityScore: json['priorityScore'],
    );
  }

  Map<String, dynamic> toJson() => {
    'gapId': gapId,
    'topicId': topicId,
    'questionIds': questionIds,
    'prerequisiteTopicIds': prerequisiteTopicIds,
    'recommendedDifficulty': recommendedDifficulty.toString(),
    'practiceStrategy': practiceStrategy,
    'estimatedPracticeMinutes': estimatedPracticeMinutes,
    'priorityScore': priorityScore,
  };

  String getPriorityLabel() {
    if (priorityScore >= 5) return 'Critical';
    if (priorityScore >= 4) return 'High';
    if (priorityScore >= 3) return 'Medium';
    return 'Low';
  }
}

/// Tracks progress in addressing a specific knowledge gap.
class GapProgressTracking {
  final String gapId;
  final String topicId;
  final GapSeverity initialSeverity;
  final GapSeverity currentSeverity;
  final double initialAccuracy;
  final double currentAccuracy;
  final int practiceSessionsCompleted;
  final int questionsAttempted;
  final int questionsCorrect;
  final double improvementRate;
  final bool isImproving;
  final String progressSummary;
  final DateTime lastPracticedAt;

  GapProgressTracking({
    required this.gapId,
    required this.topicId,
    required this.initialSeverity,
    required this.currentSeverity,
    required this.initialAccuracy,
    required this.currentAccuracy,
    required this.practiceSessionsCompleted,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.improvementRate,
    required this.isImproving,
    required this.progressSummary,
    required this.lastPracticedAt,
  });

  factory GapProgressTracking.fromJson(Map<String, dynamic> json) {
    return GapProgressTracking(
      gapId: json['gapId'],
      topicId: json['topicId'],
      initialSeverity: GapSeverity.values.firstWhere(
        (e) => e.toString() == json['initialSeverity'],
      ),
      currentSeverity: GapSeverity.values.firstWhere(
        (e) => e.toString() == json['currentSeverity'],
      ),
      initialAccuracy: json['initialAccuracy'],
      currentAccuracy: json['currentAccuracy'],
      practiceSessionsCompleted: json['practiceSessionsCompleted'],
      questionsAttempted: json['questionsAttempted'],
      questionsCorrect: json['questionsCorrect'],
      improvementRate: json['improvementRate'],
      isImproving: json['isImproving'],
      progressSummary: json['progressSummary'],
      lastPracticedAt: DateTime.parse(json['lastPracticedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'gapId': gapId,
    'topicId': topicId,
    'initialSeverity': initialSeverity.toString(),
    'currentSeverity': currentSeverity.toString(),
    'initialAccuracy': initialAccuracy,
    'currentAccuracy': currentAccuracy,
    'practiceSessionsCompleted': practiceSessionsCompleted,
    'questionsAttempted': questionsAttempted,
    'questionsCorrect': questionsCorrect,
    'improvementRate': improvementRate,
    'isImproving': isImproving,
    'progressSummary': progressSummary,
    'lastPracticedAt': lastPracticedAt.toIso8601String(),
  };

  String getImprovementTrend() {
    if (!isImproving) return 'Stagnant';
    if (improvementRate >= 0.1) return 'Rapid';
    if (improvementRate >= 0.05) return 'Steady';
    return 'Slow';
  }
}

/// Represents a batch analysis of knowledge gaps across multiple topics.
class BatchGapAnalysis {
  final String userId;
  final String subjectId;
  final List<GapAnalysisResult> topicAnalyses;
  final int totalGapsDetected;
  final Map<GapSeverity, int> gapsBySeverity;
  final List<String> criticalTopicIds;
  final List<String> improvingTopicIds;
  final String overallAssessment;
  final DateTime analyzedAt;

  BatchGapAnalysis({
    required this.userId,
    required this.subjectId,
    required this.topicAnalyses,
    required this.totalGapsDetected,
    required this.gapsBySeverity,
    required this.criticalTopicIds,
    required this.improvingTopicIds,
    required this.overallAssessment,
    required this.analyzedAt,
  });

  factory BatchGapAnalysis.fromJson(Map<String, dynamic> json) {
    return BatchGapAnalysis(
      userId: json['userId'],
      subjectId: json['subjectId'],
      topicAnalyses: (json['topicAnalyses'] as List)
          .map((e) => GapAnalysisResult.fromJson(e))
          .toList(),
      totalGapsDetected: json['totalGapsDetected'],
      gapsBySeverity: Map<GapSeverity, int>.fromEntries(
        (json['gapsBySeverity'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            GapSeverity.values.firstWhere((s) => s.toString() == e.key),
            e.value as int,
          ),
        ),
      ),
      criticalTopicIds: List<String>.from(json['criticalTopicIds']),
      improvingTopicIds: List<String>.from(json['improvingTopicIds']),
      overallAssessment: json['overallAssessment'],
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'subjectId': subjectId,
    'topicAnalyses': topicAnalyses.map((e) => e.toJson()).toList(),
    'totalGapsDetected': totalGapsDetected,
    'gapsBySeverity': gapsBySeverity.map((k, v) => MapEntry(k.toString(), v)),
    'criticalTopicIds': criticalTopicIds,
    'improvingTopicIds': improvingTopicIds,
    'overallAssessment': overallAssessment,
    'analyzedAt': analyzedAt.toIso8601String(),
  };

  List<GapAnalysisResult> getMostUrgentGaps(int limit) {
    final list = topicAnalyses.where((analysis) => analysis.hasGap).toList();
    list.sort((a, b) {
      // Sort by severity first (critical to low)
      int severityCompare = (b.severity?.index ?? -1).compareTo(
        a.severity?.index ?? -1,
      );
      if (severityCompare != 0) return severityCompare;
      // Then by composite score (higher score = more urgent)
      return b.compositeScore.compareTo(a.compositeScore);
    });
    return list.take(limit).toList();
  }
}
