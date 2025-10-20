import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/local/database_exception.dart';

import '../models/models.dart';
import '../repositories/content_repository.dart';
import '../repositories/learning_session_repository.dart';
import '../repositories/performance_metrics_repository.dart';
import '../repositories/user_progress_repository.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

class AdaptiveLearningService extends ChangeNotifier {
  // Singleton instance
  static final AdaptiveLearningService instance =
      AdaptiveLearningService._internal();
  factory AdaptiveLearningService() => instance;

  AdaptiveLearningService._internal();

  // Dependencies
  UserProgressRepository? _userProgressRepository;
  LearningSessionRepository? _learningSessionRepository;
  PerformanceMetricsRepository? _performanceMetricsRepository;
  ContentRepository? _contentRepository;

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void setRepositories({
    required UserProgressRepository userProgressRepository,
    required LearningSessionRepository learningSessionRepository,
    required PerformanceMetricsRepository performanceMetricsRepository,
    required ContentRepository contentRepository,
  }) {
    _userProgressRepository = userProgressRepository;
    _learningSessionRepository = learningSessionRepository;
    _performanceMetricsRepository = performanceMetricsRepository;
    _contentRepository = contentRepository;
    _isInitialized = true;
    notifyListeners();
  }

  // Difficulty Adaptation
  Future<Result<DifficultyRecommendation>> getRecommendedDifficulty(
    String userId,
    String topicId,
    DifficultyLevel currentDifficulty,
  ) async {
    try {
      _checkInitialized();

      // Get recent sessions sorted by start time (most recent first)
      final sessionsResult = await _learningSessionRepository!
          .getSessionsByTopic(userId, topicId)
          .timeout(QueryLimits.operationTimeout);

      final sessions = sessionsResult.fold((sessions) {
        // Sort sessions by start time (most recent first)
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        return sessions;
      }, (_) => <LearningSession>[]);

      // Get recent results across last N questions from the most recent session
      final recentResults = <bool>[];
      const maxRecentQuestions =
          AdaptiveLearningConstants.consecutiveCorrectToIncrease * 2;

      if (sessions.isNotEmpty) {
        final latestSession = sessions.first;
        // Convert questionResults map to list of entries for chronological ordering
        final orderedResults = latestSession.questionResults.entries.toList()
          ..sort((a, b) {
            final aIndex = latestSession.questionIds.indexOf(a.key);
            final bIndex = latestSession.questionIds.indexOf(b.key);
            return bIndex.compareTo(aIndex); // Most recent first
          });

        // Take up to maxRecentQuestions most recent results
        recentResults.addAll(
          orderedResults.take(maxRecentQuestions).map((e) => e.value).toList(),
        );
      }

      final consecutiveCorrect = _calculateConsecutiveCorrect(recentResults);
      final consecutiveIncorrect = _calculateConsecutiveIncorrect(
        recentResults,
      );

      // Get accuracy by difficulty from performance metrics
      final metricsResult = await _performanceMetricsRepository!
          .getByUserAndSubject(
            userId,
            topicId.split('_').first,
          ) // Get subject ID from topic ID
          .timeout(QueryLimits.operationTimeout);

      // Default to session-based accuracy if metrics are missing
      double accuracy = 0.0;

      final metrics = metricsResult.fold(
        (metrics) {
          if (metrics != null) {
            // Get accuracy for current difficulty level
            final accuracyByDifficultyResult =
                metrics.accuracyRates[currentDifficulty];
            if (accuracyByDifficultyResult != null) {
              return accuracyByDifficultyResult;
            }
          }
          // Fall back to calculating from sessions if no metrics or missing difficulty
          double correctAnswers = 0;
          double totalQuestions = 0;
          for (final session in sessions) {
            final results = session.questionResults.values;
            correctAnswers += results.where((r) => r).length;
            totalQuestions += results.length;
          }
          return totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
        },
        (_) {
          // Fall back to calculating from sessions on error
          double correctAnswers = 0;
          double totalQuestions = 0;
          for (final session in sessions) {
            final results = session.questionResults.values;
            correctAnswers += results.where((r) => r).length;
            totalQuestions += results.length;
          }
          return totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
        },
      );

      accuracy = metrics;

      // Apply difficulty adjustment rules
      bool shouldAdjust = false;
      DifficultyLevel recommendedDifficulty = currentDifficulty;
      String reason = 'No adjustment needed';

      if (consecutiveCorrect >=
              AdaptiveLearningConstants.consecutiveCorrectToIncrease &&
          accuracy >= AdaptiveLearningConstants.minimumAccuracyForIncrease) {
        final nextDifficulty = _getNextDifficultyUp(currentDifficulty);
        if (nextDifficulty != currentDifficulty) {
          shouldAdjust = true;
          recommendedDifficulty = nextDifficulty;
          reason =
              '$consecutiveCorrect consecutive correct answers with ${(accuracy * 100).toStringAsFixed(1)}% accuracy';
        }
      } else if (consecutiveIncorrect >=
          AdaptiveLearningConstants.consecutiveIncorrectToDecrease) {
        final nextDifficulty = _getNextDifficultyDown(currentDifficulty);
        if (nextDifficulty != currentDifficulty) {
          shouldAdjust = true;
          recommendedDifficulty = nextDifficulty;
          reason = '$consecutiveIncorrect consecutive incorrect answers';
        }
      }

      return Result.success(
        DifficultyRecommendation(
          currentDifficulty: currentDifficulty,
          recommendedDifficulty: recommendedDifficulty,
          reason: reason,
          consecutiveCorrect: consecutiveCorrect,
          consecutiveIncorrect: consecutiveIncorrect,
          recentAccuracy: accuracy,
          shouldAdjust: shouldAdjust,
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // Spaced Repetition
  Future<Result<List<TopicReviewSchedule>>> getTopicsForReview(
    String userId,
    String subjectId, {
    int limit = 10,
  }) async {
    try {
      _checkInitialized();

      // Get UserProgress for all topics in subject
      final progressResult = await _userProgressRepository!
          .getBySubjectId(userId, subjectId)
          .timeout(QueryLimits.operationTimeout);

      final progressList = progressResult.fold(
        (progress) => progress,
        (_) => <UserProgress>[],
      );

      // Get PerformanceMetrics for topic mastery scores
      final metricsResult = await _performanceMetricsRepository!
          .getByUserAndSubject(userId, subjectId)
          .timeout(QueryLimits.operationTimeout);

      final metrics = metricsResult.fold((metrics) => metrics, (_) => null);

      final schedules = <TopicReviewSchedule>[];

      for (final progress in progressList) {
        final lastAttempt = progress.lastAttemptAt;
        final daysSinceLastAttempt = DateTime.now()
            .difference(lastAttempt)
            .inDays;

        final masteryScore =
            metrics?.topicMasteryScores[progress.topicId] ?? 0.0;
        final intervalDays = _getReviewIntervalDays(masteryScore);

        final nextReviewAt = progress.lastAttemptAt.add(
          Duration(days: intervalDays),
        );

        final daysUntilNextReview = nextReviewAt
            .difference(DateTime.now())
            .inDays;
        final priority = _calculateReviewPriority(
          daysSinceLastAttempt,
          intervalDays,
          masteryScore,
        );

        // Get topic name
        final topicResult = await _contentRepository!
            .getTopicById(progress.topicId)
            .timeout(QueryLimits.operationTimeout);

        final topic = topicResult.fold((topic) => topic, (_) => null);

        if (topic == null) continue;

        schedules.add(
          TopicReviewSchedule(
            topicId: progress.topicId,
            topicName: topic.name,
            lastAttemptAt: progress.lastAttemptAt,
            nextReviewAt: nextReviewAt,
            daysSinceLastAttempt: daysSinceLastAttempt,
            daysUntilNextReview: daysUntilNextReview,
            masteryScore: masteryScore,
            priority: priority,
            isOverdue: daysUntilNextReview < 0,
          ),
        );
      }

      // Sort by priority (descending) and overdue days (descending)
      schedules.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;

        // Calculate overdue days (0 if not overdue, positive number if overdue)
        final aOverdueDays = a.daysUntilNextReview < 0
            ? -a.daysUntilNextReview
            : 0;
        final bOverdueDays = b.daysUntilNextReview < 0
            ? -b.daysUntilNextReview
            : 0;

        // Sort by overdue days descending (more overdue first)
        return bOverdueDays.compareTo(aOverdueDays);
      });

      return Result.success(schedules.take(limit).toList());
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // Learning Pace Analysis
  Future<Result<LearningPaceInsights>> analyzeLearningPace(
    String userId,
    String topicId,
  ) async {
    try {
      _checkInitialized();

      // Get topic details
      final topicResult = await _contentRepository!
          .getTopicById(topicId)
          .timeout(QueryLimits.operationTimeout);

      final topic = topicResult.fold((topic) => topic, (_) => null);

      if (topic == null) {
        return const Result.error(NotFoundFailure('Topic not found'));
      }

      // Get recent sessions
      final sessionsResult = await _learningSessionRepository!
          .getSessionsByTopic(userId, topicId)
          .timeout(QueryLimits.operationTimeout);

      final sessions = sessionsResult.fold(
        (sessions) => sessions,
        (_) => <LearningSession>[],
      );

      // Calculate accuracy separately from timing
      double correctAnswers = 0;
      int totalAnswers = 0;

      // Calculate response time separately
      double totalTime = 0;
      int timedQuestions = 0;

      for (final session in sessions) {
        // Handle accuracy calculation
        final results = session.questionResults.values;
        correctAnswers += results.where((result) => result).length;
        totalAnswers += results.length;

        // Handle timing calculation
        final responseTimes = session.responseTimesSeconds.values;
        if (responseTimes.isNotEmpty) {
          totalTime += responseTimes.reduce((a, b) => a + b);
          timedQuestions += responseTimes.length;
        }
      }

      final accuracy = totalAnswers > 0 ? correctAnswers / totalAnswers : 0.0;

      // Check if we have enough timing data
      if (timedQuestions == 0) {
        return Result.success(
          LearningPaceInsights(
            topicId: topicId,
            topicName: topic.name,
            averageResponseTime: 0.0,
            expectedResponseTime: 0.0,
            paceRatio: 0.0,
            paceCategory: 'Unknown',
            accuracy: accuracy,
            recommendation: accuracy >= 0.8
                ? 'Good accuracy! Complete more questions to analyze your learning pace.'
                : 'Practice more questions to help understand your learning pace and improve accuracy.',
          ),
        );
      }

      final averageResponseTime = totalTime / timedQuestions;

      // Get questions and calculate expected time
      final questionsResult = await _contentRepository!
          .getQuestionsByTopicId(topicId)
          .timeout(QueryLimits.operationTimeout);

      final questions = questionsResult.fold(
        (questions) => questions,
        (_) => <Question>[],
      );

      // If we don't have expected time data, return neutral insights
      if (questions.isEmpty) {
        return Result.success(
          LearningPaceInsights(
            topicId: topicId,
            topicName: topic.name,
            averageResponseTime: averageResponseTime,
            expectedResponseTime: 0.0,
            paceRatio: 0.0,
            paceCategory: 'Unknown',
            accuracy: accuracy,
            recommendation:
                'Topic timing data is being calibrated. Keep practicing to help establish baseline times.',
          ),
        );
      }

      final expectedResponseTime =
          questions.map((q) => q.estimatedTimeSeconds).reduce((a, b) => a + b) /
          questions.length;

      // If expected time is 0, avoid division by zero and return neutral insights
      if (expectedResponseTime == 0) {
        return Result.success(
          LearningPaceInsights(
            topicId: topicId,
            topicName: topic.name,
            averageResponseTime: averageResponseTime,
            expectedResponseTime: 0.0,
            paceRatio: 0.0,
            paceCategory: 'Unknown',
            accuracy: accuracy,
            recommendation:
                'Topic timing data needs calibration. Continue practicing to help establish expected completion times.',
          ),
        );
      }

      final paceRatio = averageResponseTime / expectedResponseTime;
      String paceCategory;
      String recommendation;

      if (paceRatio < AdaptiveLearningConstants.paceFastThreshold) {
        paceCategory = 'Fast';
        recommendation = accuracy >= 0.8
            ? 'Excellent! Consider advancing to harder topics.'
            : 'You\'re rushing. Take more time to understand each question.';
      } else if (paceRatio > AdaptiveLearningConstants.paceSlowThreshold) {
        paceCategory = 'Slow';
        recommendation = accuracy >= 0.8
            ? 'Good accuracy! Speed will improve with practice.'
            : 'Take time to review the fundamentals before proceeding.';
      } else {
        paceCategory = 'Normal';
        recommendation = accuracy >= 0.8
            ? 'Great work! Keep maintaining this balanced pace.'
            : 'Your pace is good, focus on improving accuracy.';
      }

      return Result.success(
        LearningPaceInsights(
          topicId: topicId,
          topicName: topic.name,
          averageResponseTime: averageResponseTime,
          expectedResponseTime: expectedResponseTime,
          paceRatio: paceRatio,
          paceCategory: paceCategory,
          accuracy: accuracy,
          recommendation: recommendation,
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // Performance Trend Analysis
  Future<Result<PerformanceTrend>> analyzePerformanceTrend(
    String userId,
    String subjectId,
  ) async {
    try {
      _checkInitialized();

      // Get recent completed sessions
      final sessionsResult = await _learningSessionRepository!
          .getCompletedSessions(
            userId,
            limit: AdaptiveLearningConstants.trendAnalysisSessionCount,
          )
          .timeout(QueryLimits.operationTimeout);

      final allSessions = sessionsResult.fold(
        (sessions) => sessions,
        (_) => <LearningSession>[],
      );

      // Filter sessions for this subject
      final sessions = <LearningSession>[];
      for (final session in allSessions) {
        // Check if any topic in the session belongs to this subject
        bool belongsToSubject = false;
        for (final topicId in session.topicIds) {
          final topicResult = await _contentRepository!
              .getTopicById(topicId)
              .timeout(QueryLimits.operationTimeout);

          final topic = topicResult.fold((topic) => topic, (_) => null);

          if (topic != null && topic.subjectId == subjectId) {
            belongsToSubject = true;
            break;
          }
        }

        if (belongsToSubject) {
          sessions.add(session);
        }
      }

      if (sessions.length < AdaptiveLearningConstants.minSessionsForTrend) {
        return const Result.error(
          ValidationFailure(
            'Insufficient data: need at least ${AdaptiveLearningConstants.minSessionsForTrend} sessions',
          ),
        );
      }

      // Sort sessions chronologically by start time
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Extract accuracy history and session dates (now in chronological order)
      final accuracyHistory = sessions.map((s) => s.accuracyRate).toList();
      final sessionDates = sessions.map((s) => s.startTime).toList();

      // Calculate trend from chronologically ordered data
      final firstHalf = accuracyHistory.sublist(0, accuracyHistory.length ~/ 2);
      final secondHalf = accuracyHistory.sublist(accuracyHistory.length ~/ 2);

      final firstHalfAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondHalfAvg =
          secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      final difference = secondHalfAvg - firstHalfAvg;
      final trendStrength = difference.abs();

      String trendDirection;
      String insight;

      if (difference > AdaptiveLearningConstants.improvementThreshold) {
        trendDirection = 'Improving';
        insight =
            'Great progress! Your accuracy has improved by ${(difference * 100).toStringAsFixed(1)}%.';
      } else if (difference < -AdaptiveLearningConstants.declineThreshold) {
        trendDirection = 'Declining';
        insight =
            'Your performance has declined by ${(difference.abs() * 100).toStringAsFixed(1)}%. Consider reviewing fundamentals.';
      } else {
        trendDirection = 'Stable';
        insight = 'Your performance is consistent. Keep practicing to improve!';
      }

      final averageAccuracy =
          accuracyHistory.reduce((a, b) => a + b) / accuracyHistory.length;
      final recentAccuracy = secondHalfAvg;

      return Result.success(
        PerformanceTrend(
          userId: userId,
          subjectId: subjectId,
          accuracyHistory: accuracyHistory,
          sessionDates: sessionDates,
          trendDirection: trendDirection,
          trendStrength: trendStrength,
          averageAccuracy: averageAccuracy,
          recentAccuracy: recentAccuracy,
          insight: insight,
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // Batch Analysis
  Future<Result<Map<String, LearningPaceInsights>>>
  analyzeLearningPaceForAllTopics(String userId, String subjectId) async {
    try {
      _checkInitialized();

      final topicsResult = await _contentRepository!
          .getTopicsBySubjectId(subjectId)
          .timeout(QueryLimits.operationTimeout);

      final topics = topicsResult.fold((topics) => topics, (_) => <Topic>[]);

      final insights = <String, LearningPaceInsights>{};

      for (final topic in topics) {
        final result = await analyzeLearningPace(userId, topic.id);
        result.fold(
          (insight) => insights[topic.id] = insight,
          (_) => null, // Skip failed analyses
        );
      }

      return Result.success(insights);
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // Helper Methods
  int _calculateConsecutiveCorrect(List<bool> recentResults) {
    int count = 0;
    for (int i = recentResults.length - 1; i >= 0; i--) {
      if (recentResults[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int _calculateConsecutiveIncorrect(List<bool> recentResults) {
    int count = 0;
    for (int i = recentResults.length - 1; i >= 0; i--) {
      if (!recentResults[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int _getReviewIntervalDays(double masteryScore) {
    if (masteryScore < AdaptiveLearningConstants.masteryLevelLow) {
      return AdaptiveLearningConstants.spacedRepetitionInterval1;
    } else if (masteryScore < AdaptiveLearningConstants.masteryLevelMedium) {
      return AdaptiveLearningConstants.spacedRepetitionInterval2;
    } else if (masteryScore < AdaptiveLearningConstants.masteryLevelHigh) {
      return AdaptiveLearningConstants.spacedRepetitionInterval3;
    } else {
      return AdaptiveLearningConstants.spacedRepetitionInterval4;
    }
  }

  int _calculateReviewPriority(
    int daysSinceLastAttempt,
    int intervalDays,
    double masteryScore,
  ) {
    if (daysSinceLastAttempt >= intervalDays * 2) {
      return 5; // Critical - overdue by 2x interval
    } else if (daysSinceLastAttempt >= intervalDays) {
      return 4; // High - overdue
    } else if (daysSinceLastAttempt >= intervalDays * 0.8) {
      return 3; // Medium - due soon
    } else if (masteryScore < AdaptiveLearningConstants.masteryLevelLow) {
      return 3; // Medium - needs practice
    } else {
      return 2; // Low - on track
    }
  }

  DifficultyLevel _getNextDifficultyUp(DifficultyLevel current) {
    switch (current) {
      case DifficultyLevel.beginner:
        return DifficultyLevel.intermediate;
      case DifficultyLevel.intermediate:
        return DifficultyLevel.advanced;
      case DifficultyLevel.advanced:
        return DifficultyLevel.expert;
      case DifficultyLevel.expert:
        return DifficultyLevel.expert; // No higher level
    }
  }

  DifficultyLevel _getNextDifficultyDown(DifficultyLevel current) {
    switch (current) {
      case DifficultyLevel.expert:
        return DifficultyLevel.advanced;
      case DifficultyLevel.advanced:
        return DifficultyLevel.intermediate;
      case DifficultyLevel.intermediate:
        return DifficultyLevel.beginner;
      case DifficultyLevel.beginner:
        return DifficultyLevel.beginner; // No lower level
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('AdaptiveLearningService not initialized');
    }
  }

  Failure _mapException(Object e, StackTrace st) {
    if (e is TimeoutException) {
      return const TimeoutFailure('Operation timed out');
    } else if (e is StateError) {
      return ValidationFailure(e.toString());
    } else if (e is DatabaseException) {
      return DatabaseFailure(e.toString(), cause: e, stackTrace: st);
    }
    return UnknownFailure(
      'An unexpected error occurred',
      cause: e,
      stackTrace: st,
    );
  }
}
