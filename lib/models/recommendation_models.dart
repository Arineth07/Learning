import 'enums.dart';
import 'question.dart';

class TopicRecommendation {
  final String topicId;
  final String topicName;
  final String subjectId;
  final double compositeScore;
  final double urgencyScore;
  final double readinessScore;
  final double impactScore;
  final double engagementScore;
  final DifficultyLevel recommendedDifficulty;
  final String recommendationReason;
  final List<String> prerequisiteTopicIds;
  final bool hasUnmetPrerequisites;
  final bool hasKnowledgeGap;
  final bool isOverdueForReview;
  final int estimatedMinutes;

  TopicRecommendation({
    required this.topicId,
    required this.topicName,
    required this.subjectId,
    required this.compositeScore,
    required this.urgencyScore,
    required this.readinessScore,
    required this.impactScore,
    required this.engagementScore,
    required this.recommendedDifficulty,
    required this.recommendationReason,
    required this.prerequisiteTopicIds,
    required this.hasUnmetPrerequisites,
    required this.hasKnowledgeGap,
    required this.isOverdueForReview,
    required this.estimatedMinutes,
  });

  factory TopicRecommendation.fromJson(Map<String, dynamic> json) =>
      TopicRecommendation(
        topicId: json['topicId'],
        topicName: json['topicName'],
        subjectId: json['subjectId'],
        compositeScore: (json['compositeScore'] as num).toDouble(),
        urgencyScore: (json['urgencyScore'] as num).toDouble(),
        readinessScore: (json['readinessScore'] as num).toDouble(),
        impactScore: (json['impactScore'] as num).toDouble(),
        engagementScore: (json['engagementScore'] as num).toDouble(),
        recommendedDifficulty:
            DifficultyLevel.values[json['recommendedDifficulty']],
        recommendationReason: json['recommendationReason'],
        prerequisiteTopicIds: List<String>.from(
          json['prerequisiteTopicIds'] ?? [],
        ),
        hasUnmetPrerequisites: json['hasUnmetPrerequisites'],
        hasKnowledgeGap: json['hasKnowledgeGap'],
        isOverdueForReview: json['isOverdueForReview'],
        estimatedMinutes: json['estimatedMinutes'],
      );

  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'topicName': topicName,
    'subjectId': subjectId,
    'compositeScore': compositeScore,
    'urgencyScore': urgencyScore,
    'readinessScore': readinessScore,
    'impactScore': impactScore,
    'engagementScore': engagementScore,
    'recommendedDifficulty': recommendedDifficulty.index,
    'recommendationReason': recommendationReason,
    'prerequisiteTopicIds': prerequisiteTopicIds,
    'hasUnmetPrerequisites': hasUnmetPrerequisites,
    'hasKnowledgeGap': hasKnowledgeGap,
    'isOverdueForReview': isOverdueForReview,
    'estimatedMinutes': estimatedMinutes,
  };

  String getPriorityLabel() {
    if (compositeScore >= 0.85) return 'Critical';
    if (compositeScore >= 0.7) return 'High';
    if (compositeScore >= 0.5) return 'Medium';
    return 'Low';
  }
}

class PracticeSetRecommendation {
  final String recommendationId;
  final String userId;
  final String primaryTopicId;
  final List<String> questionIds;
  final Map<String, int> questionsBySource;
  final Map<DifficultyLevel, int> questionsByDifficulty;
  final int totalQuestions;
  final int estimatedMinutes;
  final String practiceGoal;
  final List<String> focusAreas;
  final double expectedAccuracy;
  final DateTime generatedAt;

  PracticeSetRecommendation({
    required this.recommendationId,
    required this.userId,
    required this.primaryTopicId,
    required this.questionIds,
    required this.questionsBySource,
    required this.questionsByDifficulty,
    required this.totalQuestions,
    required this.estimatedMinutes,
    required this.practiceGoal,
    required this.focusAreas,
    required this.expectedAccuracy,
    required this.generatedAt,
  });

  factory PracticeSetRecommendation.fromJson(Map<String, dynamic> json) =>
      PracticeSetRecommendation(
        recommendationId: json['recommendationId'],
        userId: json['userId'],
        primaryTopicId: json['primaryTopicId'],
        questionIds: List<String>.from(json['questionIds'] ?? []),
        questionsBySource: Map<String, int>.from(
          json['questionsBySource'] ?? {},
        ),
        questionsByDifficulty:
            (json['questionsByDifficulty'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(DifficultyLevel.values[int.parse(k)], v),
            ),
        totalQuestions: json['totalQuestions'],
        estimatedMinutes: json['estimatedMinutes'],
        practiceGoal: json['practiceGoal'],
        focusAreas: List<String>.from(json['focusAreas'] ?? []),
        expectedAccuracy: (json['expectedAccuracy'] as num).toDouble(),
        generatedAt: DateTime.parse(json['generatedAt']),
      );

  Map<String, dynamic> toJson() => {
    'recommendationId': recommendationId,
    'userId': userId,
    'primaryTopicId': primaryTopicId,
    'questionIds': questionIds,
    'questionsBySource': questionsBySource,
    'questionsByDifficulty': questionsByDifficulty.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'totalQuestions': totalQuestions,
    'estimatedMinutes': estimatedMinutes,
    'practiceGoal': practiceGoal,
    'focusAreas': focusAreas,
    'expectedAccuracy': expectedAccuracy,
    'generatedAt': generatedAt.toIso8601String(),
  };

  String getSourceBreakdown() {
    final total = totalQuestions == 0 ? 1 : totalQuestions;
    final gap = ((questionsBySource['gap'] ?? 0) / total * 100).round();
    final review = ((questionsBySource['review'] ?? 0) / total * 100).round();
    final newQ = ((questionsBySource['new'] ?? 0) / total * 100).round();
    return '$gap% gaps, $review% review, $newQ% new';
  }
}

class LearningPath {
  final String pathId;
  final String userId;
  final String subjectId;
  final String strategy;
  final List<LearningPathStep> steps;
  final int totalSteps;
  final int completedSteps;
  final int estimatedTotalMinutes;
  final String goalDescription;
  final DateTime generatedAt;
  final DateTime? lastUpdatedAt;

  LearningPath({
    required this.pathId,
    required this.userId,
    required this.subjectId,
    required this.strategy,
    required this.steps,
    required this.totalSteps,
    required this.completedSteps,
    required this.estimatedTotalMinutes,
    required this.goalDescription,
    required this.generatedAt,
    this.lastUpdatedAt,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) => LearningPath(
    pathId: json['pathId'],
    userId: json['userId'],
    subjectId: json['subjectId'],
    strategy: json['strategy'],
    steps: (json['steps'] as List<dynamic>)
        .map((e) => LearningPathStep.fromJson(e))
        .toList(),
    totalSteps: json['totalSteps'],
    completedSteps: json['completedSteps'],
    estimatedTotalMinutes: json['estimatedTotalMinutes'],
    goalDescription: json['goalDescription'],
    generatedAt: DateTime.parse(json['generatedAt']),
    lastUpdatedAt: json['lastUpdatedAt'] != null
        ? DateTime.parse(json['lastUpdatedAt'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'pathId': pathId,
    'userId': userId,
    'subjectId': subjectId,
    'strategy': strategy,
    'steps': steps.map((e) => e.toJson()).toList(),
    'totalSteps': totalSteps,
    'completedSteps': completedSteps,
    'estimatedTotalMinutes': estimatedTotalMinutes,
    'goalDescription': goalDescription,
    'generatedAt': generatedAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
  };

  double getProgressPercentage() =>
      totalSteps == 0 ? 0.0 : (completedSteps / totalSteps) * 100.0;

  LearningPathStep? getNextStep() {
    if (steps.isEmpty) return null;
    final step = steps.firstWhere(
      (s) => !s.isCompleted,
      orElse: () => steps.last,
    );
    return step;
  }

  bool isCompleted() => completedSteps >= totalSteps && totalSteps > 0;
}

class LearningPathStep {
  final int stepNumber;
  final String topicId;
  final String topicName;
  final DifficultyLevel recommendedDifficulty;
  final String stepType;
  final String objective;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> prerequisiteStepNumbers;

  LearningPathStep({
    required this.stepNumber,
    required this.topicId,
    required this.topicName,
    required this.recommendedDifficulty,
    required this.stepType,
    required this.objective,
    required this.estimatedMinutes,
    required this.isCompleted,
    this.completedAt,
    required this.prerequisiteStepNumbers,
  });

  factory LearningPathStep.fromJson(Map<String, dynamic> json) =>
      LearningPathStep(
        stepNumber: json['stepNumber'],
        topicId: json['topicId'],
        topicName: json['topicName'],
        recommendedDifficulty:
            DifficultyLevel.values[json['recommendedDifficulty']],
        stepType: json['stepType'],
        objective: json['objective'],
        estimatedMinutes: json['estimatedMinutes'],
        isCompleted: json['isCompleted'],
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        prerequisiteStepNumbers: List<String>.from(
          json['prerequisiteStepNumbers'] ?? [],
        ),
      );

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'topicId': topicId,
    'topicName': topicName,
    'recommendedDifficulty': recommendedDifficulty.index,
    'stepType': stepType,
    'objective': objective,
    'estimatedMinutes': estimatedMinutes,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'prerequisiteStepNumbers': prerequisiteStepNumbers,
  };

  bool canStart(List<LearningPathStep> allSteps) {
    for (final prereq in prerequisiteStepNumbers) {
      LearningPathStep? match;
      for (final s in allSteps) {
        if (s.stepNumber.toString() == prereq) {
          match = s;
          break;
        }
      }
      // If prerequisite step is missing, treat as not startable
      if (match == null) return false;
      if (!match.isCompleted) return false;
    }
    return true;
  }
}

class PersonalizedQuestionSet {
  final String setId;
  final String userId;
  final String topicId;
  final List<Question> questions;
  final Map<String, String> questionSources;
  final DifficultyLevel averageDifficulty;
  final String selectionRationale;
  final DateTime generatedAt;

  PersonalizedQuestionSet({
    required this.setId,
    required this.userId,
    required this.topicId,
    required this.questions,
    required this.questionSources,
    required this.averageDifficulty,
    required this.selectionRationale,
    required this.generatedAt,
  });

  factory PersonalizedQuestionSet.fromJson(Map<String, dynamic> json) =>
      PersonalizedQuestionSet(
        setId: json['setId'],
        userId: json['userId'],
        topicId: json['topicId'],
        questions: (json['questions'] as List<dynamic>)
            .map((e) => Question.fromJson(e))
            .toList(),
        questionSources: Map<String, String>.from(
          json['questionSources'] ?? {},
        ),
        averageDifficulty: DifficultyLevel.values[json['averageDifficulty']],
        selectionRationale: json['selectionRationale'],
        generatedAt: DateTime.parse(json['generatedAt']),
      );

  Map<String, dynamic> toJson() => {
    'setId': setId,
    'userId': userId,
    'topicId': topicId,
    'questions': questions.map((e) => e.toJson()).toList(),
    'questionSources': questionSources,
    'averageDifficulty': averageDifficulty.index,
    'selectionRationale': selectionRationale,
    'generatedAt': generatedAt.toIso8601String(),
  };

  List<Question> getQuestionsByDifficulty(DifficultyLevel level) =>
      questions.where((q) => q.difficulty == level).toList();

  List<Question> getQuestionsBySource(String source) =>
      questions.where((q) => questionSources[q.id] == source).toList();
}

class RecommendationSummary {
  final String userId;
  final String subjectId;
  final TopicRecommendation? nextTopic;
  final List<TopicRecommendation> alternativeTopics;
  final PracticeSetRecommendation? suggestedPractice;
  final List<String> criticalGapTopics;
  final List<String> overdueReviewTopics;
  final String overallRecommendation;
  final DateTime generatedAt;

  RecommendationSummary({
    required this.userId,
    required this.subjectId,
    this.nextTopic,
    required this.alternativeTopics,
    this.suggestedPractice,
    required this.criticalGapTopics,
    required this.overdueReviewTopics,
    required this.overallRecommendation,
    required this.generatedAt,
  });

  factory RecommendationSummary.fromJson(Map<String, dynamic> json) =>
      RecommendationSummary(
        userId: json['userId'],
        subjectId: json['subjectId'],
        nextTopic: json['nextTopic'] != null
            ? TopicRecommendation.fromJson(json['nextTopic'])
            : null,
        alternativeTopics: (json['alternativeTopics'] as List<dynamic>)
            .map((e) => TopicRecommendation.fromJson(e))
            .toList(),
        suggestedPractice: json['suggestedPractice'] != null
            ? PracticeSetRecommendation.fromJson(json['suggestedPractice'])
            : null,
        criticalGapTopics: List<String>.from(json['criticalGapTopics'] ?? []),
        overdueReviewTopics: List<String>.from(
          json['overdueReviewTopics'] ?? [],
        ),
        overallRecommendation: json['overallRecommendation'],
        generatedAt: DateTime.parse(json['generatedAt']),
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'subjectId': subjectId,
    'nextTopic': nextTopic?.toJson(),
    'alternativeTopics': alternativeTopics.map((e) => e.toJson()).toList(),
    'suggestedPractice': suggestedPractice?.toJson(),
    'criticalGapTopics': criticalGapTopics,
    'overdueReviewTopics': overdueReviewTopics,
    'overallRecommendation': overallRecommendation,
    'generatedAt': generatedAt.toIso8601String(),
  };

  bool hasCriticalGaps() => criticalGapTopics.isNotEmpty;
  bool hasOverdueReviews() => overdueReviewTopics.isNotEmpty;
}
