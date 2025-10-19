import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/learning_session_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/knowledge_gap_repository.dart';
import '../utils/constants.dart';
import '../utils/result.dart';
import '../utils/failures.dart';

/// A service for detecting, analyzing, and managing knowledge gaps.
class KnowledgeGapService extends ChangeNotifier {
  // Private constructor
  KnowledgeGapService._internal();

  // Singleton instance
  static final KnowledgeGapService _instance = KnowledgeGapService._internal();
  
  // Public instance access
  static KnowledgeGapService get instance => _instance;

  // Dependencies
  LearningSessionRepository? _learningSessionRepository;
  ContentRepository? _contentRepository;
  KnowledgeGapRepository? _knowledgeGapRepository;

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Sets the required repositories for the service to function.
  void setRepositories({
    required LearningSessionRepository learningSessionRepository,
    required ContentRepository contentRepository,
    required KnowledgeGapRepository knowledgeGapRepository,
  }) {
    _learningSessionRepository = learningSessionRepository;
    _contentRepository = contentRepository;
    _knowledgeGapRepository = knowledgeGapRepository;
    _isInitialized = true;
    notifyListeners();
  }

  /// Helper method to determine appropriate difficulty level based on gap severity.
  DifficultyLevel _getDifficultyForSeverity(
    GapSeverity severity,
    DifficultyLevel? topicDifficulty,
  ) {
    switch (severity) {
      case GapSeverity.critical:
      case GapSeverity.high:
        return DifficultyLevel.beginner;
      case GapSeverity.medium:
        return DifficultyLevel.intermediate;
      case GapSeverity.low:
        return topicDifficulty ?? DifficultyLevel.beginner;
    }
  }

  /// Helper method to build descriptive practice strategy based on gap severity and failures.
  String _buildPracticeStrategy(GapSeverity severity, bool hasFailures) {
    final severityText = severity.toString().split('.').last.toLowerCase();
    final approachText = hasFailures 
        ? 'focusing on previously failed questions'
        : 'starting with fundamentals';
    return 'Targeted $severityText-severity practice $approachText';
  }

  /// Helper method to map gap severity to priority score.
  int _getPriorityScore(GapSeverity severity) {
    switch (severity) {
      case GapSeverity.critical:
        return 5;
      case GapSeverity.high:
        return 4;
      case GapSeverity.medium:
        return 3;
      case GapSeverity.low:
        return 2;
    }
  }

  /// Builds a targeted practice recommendation for a specific gap.
  Future<Result<TargetedPracticeRecommendation>> buildTargetedPractice(
    String userId,
    String gapId,
  ) async {
    _checkInitialized();
    try {
      // 1. Get the gap
      final gapResult = await _knowledgeGapRepository!.getById(gapId);
      
      return await gapResult.fold((gap) async {
        // 2. Get recent sessions to determine failures and successes
        final sessionsResult = await _learningSessionRepository!
            .getSessionsByTopic(userId, gap.topicId);
        
        final Set<String> failedQuestionIds = {};
        final Set<String> recentCorrectQuestionIds = {};
        
        await sessionsResult.fold((sessions) async {
          // Sessions come sorted by endTime/startTime descending
          for (final session in sessions) {
            session.questionResults.forEach((id, wasCorrect) {
              if (wasCorrect) {
                recentCorrectQuestionIds.add(id);
              } else {
                failedQuestionIds.add(id);
              }
            });
          }
        }, (failure) async {});

        // 3. Get topic details and determine appropriate difficulty
        final topicResult = await _contentRepository!.getTopicById(gap.topicId);
        
        return await topicResult.fold((topic) async {
          final targetDifficulty = _getDifficultyForSeverity(
            gap.severity, 
            topic.difficulty,
          );
          
          // 4. Get questions at target difficulty
          var questionsResult = await _contentRepository!
              .getQuestionsByTopicAndDifficulty(gap.topicId, targetDifficulty);
              
          List<Question> availableQuestions = [];
          
          await questionsResult.fold((questions) async {
            availableQuestions = questions;
          }, (failure) async {});
          
          // Backfill with adjacent difficulties if needed
          if (availableQuestions.length < KnowledgeGapConstants.recommendedQuestionsPerGap) {
            final backfillDifficulties = [
              if (targetDifficulty != DifficultyLevel.beginner) DifficultyLevel.beginner,
              if (targetDifficulty != DifficultyLevel.intermediate) DifficultyLevel.intermediate,
              if (targetDifficulty != DifficultyLevel.advanced) DifficultyLevel.advanced,
            ];
            
            for (final difficulty in backfillDifficulties) {
              if (availableQuestions.length >= KnowledgeGapConstants.recommendedQuestionsPerGap) break;
              
              final backfillResult = await _contentRepository!
                  .getQuestionsByTopicAndDifficulty(gap.topicId, difficulty);
                  
              await backfillResult.fold((questions) async {
                availableQuestions.addAll(questions);
              }, (failure) async {});
            }
          }
          
          // 5. Filter and prioritize questions
          final activeQuestions = availableQuestions.where((q) => q.isActive).toList();
          
          final prioritizedQuestions = <Question>[];
          
          // Add failed questions that haven't been recently corrected
          prioritizedQuestions.addAll(
            activeQuestions.where((q) => 
              failedQuestionIds.contains(q.id) && 
              !recentCorrectQuestionIds.contains(q.id)
            ),
          );
          
          // Add unattempted questions
          prioritizedQuestions.addAll(
            activeQuestions.where((q) => 
              !failedQuestionIds.contains(q.id) && 
              !recentCorrectQuestionIds.contains(q.id)
            ),
          );

          // 6. Include prerequisite questions if enabled
          if (KnowledgeGapConstants.includePrerequisites && gap.relatedTopicIds.isNotEmpty) {
            for (final prereqId in gap.relatedTopicIds) {
              final prereqResult = await _contentRepository!
                  .getQuestionsByTopicAndDifficulty(prereqId, DifficultyLevel.beginner);
                  
              await prereqResult.fold((prereqQuestions) async {
                final filtered = prereqQuestions.where((q) => 
                  q.isActive && !recentCorrectQuestionIds.contains(q.id)
                );
                prioritizedQuestions.addAll(filtered);
              }, (failure) async {});
            }
          }
          
          // 7. Deduplicate and limit questions
          final uniqueQuestions = <String, Question>{};
          for (final q in prioritizedQuestions) {
            uniqueQuestions[q.id] = q;
            if (uniqueQuestions.length >= KnowledgeGapConstants.recommendedQuestionsPerGap) break;
          }
          
          final selectedQuestions = uniqueQuestions.values.toList();
          final questionIds = selectedQuestions.map((q) => q.id).toList();
          
          // 8. Calculate recommendation metadata
          final estimatedTime = selectedQuestions.fold<int>(
            0,
            (sum, q) => sum + (q.estimatedTimeSeconds ~/ 60),
          );
          
          final hasFailures = selectedQuestions
              .any((q) => failedQuestionIds.contains(q.id));
              
          final practiceStrategy = _buildPracticeStrategy(gap.severity, hasFailures);
          final priorityScore = _getPriorityScore(gap.severity);
          
          // 9. Persist recommendations
          await _knowledgeGapRepository!.addRecommendedQuestions(gapId, questionIds);
          
          // 10. Build and return recommendation
          final recommendation = TargetedPracticeRecommendation(
            gapId: gap.id,
            topicId: gap.topicId,
            questionIds: questionIds,
            prerequisiteTopicIds: gap.relatedTopicIds,
            recommendedDifficulty: targetDifficulty,
            practiceStrategy: practiceStrategy,
            estimatedPracticeMinutes: estimatedTime,
            priorityScore: priorityScore,
          );
          
          return Result.success(recommendation);
        }, (failure) async => Result.error(failure));
      }, (failure) async => Result.error(failure));
    } catch (e, st) {
      return Result.error(UnknownFailure(
        'Failed to build targeted practice',
        cause: e,
        stackTrace: st,
      ));
    }
  }

  /// Builds targeted practice recommendations for all unresolved gaps for a user.
  Future<Result<List<TargetedPracticeRecommendation>>> buildPracticeForAllGaps(
    String userId, {
    int maxGaps = 3,
  }) async {
    _checkInitialized();
    // 1. Get unresolved gaps
    final gapsResult = await _knowledgeGapRepository!.getUnresolvedGaps(userId);
    return await gapsResult.fold((gaps) async {
      // 2. Sort by severity/priority
      gaps.sort((a, b) => b.severity.index.compareTo(a.severity.index));
      final selectedGaps = gaps.take(maxGaps).toList();
      final recommendations = <TargetedPracticeRecommendation>[];
      for (final gap in selectedGaps) {
        final recResult = await buildTargetedPractice(userId, gap.id);
        await recResult.fold((rec) async {
          recommendations.add(rec);
        }, (failure) async {});
      }
      return Result.success(recommendations);
    }, (failure) async => Result.error(failure));
  }

  /// Helper method to validate initialization
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('KnowledgeGapService not initialized');
    }
  }
}