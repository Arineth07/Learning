import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recommendation_models.dart';
import '../models/enums.dart';
import '../models/question.dart';
import '../models/knowledge_gap_analysis.dart';
import '../models/topic.dart';
import 'adaptive_learning_service.dart';
import 'knowledge_gap_service.dart';
import '../repositories/content_repository.dart';
import '../repositories/user_progress_repository.dart';
import '../repositories/learning_session_repository.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';
import '../utils/result.dart';
import '../utils/failures.dart';

class RecommendationService extends ChangeNotifier {
  RecommendationService._internal();
  static final RecommendationService instance =
      RecommendationService._internal();
  factory RecommendationService() => instance;

  AdaptiveLearningService? _adaptiveLearningService;
  KnowledgeGapService? _knowledgeGapService;
  ContentRepository? _contentRepository;
  // These fields are injected for future use; keep to match setRepositories signature
  // ignore: unused_field
  UserProgressRepository? _userProgressRepository;
  // ignore: unused_field
  LearningSessionRepository? _learningSessionRepository;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void setRepositories({
    required AdaptiveLearningService adaptiveLearningService,
    required KnowledgeGapService knowledgeGapService,
    required ContentRepository contentRepository,
    required UserProgressRepository userProgressRepository,
    required LearningSessionRepository learningSessionRepository,
  }) {
    _adaptiveLearningService = adaptiveLearningService;
    _knowledgeGapService = knowledgeGapService;
    _contentRepository = contentRepository;
    _userProgressRepository = userProgressRepository;
    _learningSessionRepository = learningSessionRepository;
    _isInitialized = true;
    notifyListeners();
  }

  // --- Next Topic Recommendation ---
  Future<Result<TopicRecommendation>> getNextTopicRecommendation(
    String userId,
    String subjectId,
  ) async {
    try {
      _checkInitialized();
      final topicsResult = await _contentRepository!.getTopicsBySubjectId(
        subjectId,
      );
      return await topicsResult.fold((topics) async {
        if (topics.isEmpty) {
          return Result.error(ValidationFailure('No topics found for subject'));
        }
        final recsResult = await getTopicRecommendations(
          userId,
          subjectId,
          limit: 1,
        );
        return recsResult.fold(
          (list) => Result.success(list.first),
          (failure) => Result.error(failure),
        );
      }, (failure) async => Result.error(failure));
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  Future<Result<List<TopicRecommendation>>> getTopicRecommendations(
    String userId,
    String subjectId, {
    int limit = 5,
  }) async {
    try {
      _checkInitialized();
      final topicsResult = await _contentRepository!.getTopicsBySubjectId(
        subjectId,
      );
      return await topicsResult.fold((topics) async {
        if (topics.isEmpty) {
          return Result.error(ValidationFailure('No topics found for subject'));
        }
        final List<TopicRecommendation> recommendations = [];
        for (final topic in topics) {
          final urgency = await _calculateUrgencyScore(userId, topic.id);
          final readiness = await _calculateReadinessScore(
            userId,
            topic.id,
            topic.prerequisiteTopicIds,
          );
          final impact = _calculateImpactScore(topic.id, topics);
          final engagement = await _calculateEngagementScore(userId, topic.id);
          final composite =
              urgency * RecommendationConstants.urgencyWeight +
              readiness * RecommendationConstants.readinessWeight +
              impact * RecommendationConstants.impactWeight +
              engagement * RecommendationConstants.engagementWeight;
          final diffResult = await _adaptiveLearningService!
              .getRecommendedDifficulty(userId, topic.id, topic.difficulty);
          final recommendedDifficulty = diffResult.fold(
            (d) => d.recommendedDifficulty,
            (_) => topic.difficulty,
          );
          final reason = _buildRecommendationReason(
            urgency,
            readiness,
            impact,
            engagement,
          );
          final hasGap = urgency > 0.7;
          final isOverdue = engagement > 0.7 && urgency > 0.5;
          final hasUnmetPrereqs =
              readiness <
              RecommendationConstants.prerequisiteCompletionThreshold;
          recommendations.add(
            TopicRecommendation(
              topicId: topic.id,
              topicName: topic.name,
              subjectId: subjectId,
              compositeScore: composite,
              urgencyScore: urgency,
              readinessScore: readiness,
              impactScore: impact,
              engagementScore: engagement,
              recommendedDifficulty: recommendedDifficulty,
              recommendationReason: reason,
              prerequisiteTopicIds: topic.prerequisiteTopicIds,
              hasUnmetPrerequisites: hasUnmetPrereqs,
              hasKnowledgeGap: hasGap,
              isOverdueForReview: isOverdue,
              estimatedMinutes: topic.estimatedDurationMinutes,
            ),
          );
        }
        recommendations.sort(
          (a, b) => b.compositeScore.compareTo(a.compositeScore),
        );
        return Result.success(recommendations.take(limit).toList());
      }, (failure) async => Result.error(failure));
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // --- Practice Set Recommendation ---
  Future<Result<PracticeSetRecommendation>> getRecommendedPracticeSet(
    String userId,
    String topicId, {
    int? questionCount,
  }) async {
    try {
      _checkInitialized();
      final count =
          questionCount ?? RecommendationConstants.defaultPracticeSetSize;
      // Find a valid gapId for this topic. buildTargetedPractice expects a gapId.
      final allGapsResult = await _knowledgeGapService!.buildPracticeForAllGaps(
        userId,
        maxGaps: 10,
      );
      final matchingGapId = allGapsResult.fold((recs) {
        try {
          final match = recs.firstWhere((r) => r.topicId == topicId);
          return match.gapId;
        } catch (_) {
          return null;
        }
      }, (_) => null);

      List<String> gapQuestions = <String>[];
      if (matchingGapId != null) {
        final gapResult = await _knowledgeGapService!.buildTargetedPractice(
          userId,
          matchingGapId,
        );
        gapQuestions = gapResult.fold((r) => r.questionIds, (_) => <String>[]);
      } else {
        // No gap for this topic; treat gap questions as empty (do not call with topicId)
        gapQuestions = <String>[];
      }
      // Ensure we pass a valid subjectId to getTopicsForReview by fetching the topic
      final topicResult = await _contentRepository!.getTopicById(topicId);
      final topic = topicResult.fold((t) => t, (_) => null);
      final subjectIdForReview = topic?.subjectId ?? topicId.split('_').first;
      final reviewResult = await _adaptiveLearningService!.getTopicsForReview(
        userId,
        subjectIdForReview,
        limit: 5,
      );
      // gapQuestions already available above
      final reviewTopics = reviewResult.fold(
        (r) => r.map((e) => e.topicId).toList(),
        (_) => <String>[],
      );
      final reviewQuestions = <String>[];
      for (final t in reviewTopics) {
        final qResult = await _contentRepository!.getQuestionsByTopicId(t);
        qResult.fold(
          (qs) => reviewQuestions.addAll(qs.map((q) => q.id)),
          (_) {},
        );
      }
      final gapCount = (count * RecommendationConstants.gapQuestionRatio)
          .round();
      final reviewCount = (count * RecommendationConstants.reviewQuestionRatio)
          .round();
      final newCount = count - gapCount - reviewCount;
      final selectedGap = gapQuestions.take(gapCount).toList();
      final selectedReview = reviewQuestions.take(reviewCount).toList();
      final newQuestionsResult = await _contentRepository!.getRandomQuestions(
        topicId,
        count: newCount,
      );
      final selectedNew = newQuestionsResult.fold(
        (qs) => qs.map((q) => q.id).toList(),
        (_) => <String>[],
      );
      final allIds = [...selectedGap, ...selectedReview, ...selectedNew];
      final bySource = {
        'gap': selectedGap.length,
        'review': selectedReview.length,
        'new': selectedNew.length,
      };
      final byDifficulty = <DifficultyLevel, int>{};
      // Fetch question objects individually (ContentRepository doesn't expose getQuestionsByIds)
      for (final id in allIds) {
        final qRes = await _contentRepository!.getQuestionById(id);
        qRes.fold((q) {
          byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] ?? 0) + 1;
        }, (_) {});
      }
      final estMinutes = allIds.length * 2; // Assume 2 min per question
      return Result.success(
        PracticeSetRecommendation(
          recommendationId: const Uuid().v4(),
          userId: userId,
          primaryTopicId: topicId,
          questionIds: allIds,
          questionsBySource: bySource,
          questionsByDifficulty: byDifficulty,
          totalQuestions: allIds.length,
          estimatedMinutes: estMinutes,
          practiceGoal: 'Address gaps and review for $topicId',
          focusAreas: [],
          expectedAccuracy: 0.75,
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  Future<Result<PersonalizedQuestionSet>> getPersonalizedQuestions(
    String userId,
    String topicId, {
    int? questionCount,
    DifficultyLevel? difficulty,
  }) async {
    try {
      _checkInitialized();
      final count =
          questionCount ?? RecommendationConstants.defaultPracticeSetSize;
      // Find a valid gapId for this topic. buildTargetedPractice expects a gapId.
      final allGapsResult = await _knowledgeGapService!.buildPracticeForAllGaps(
        userId,
        maxGaps: 10,
      );
      final matchingGapId = allGapsResult.fold((recs) {
        try {
          final match = recs.firstWhere((r) => r.topicId == topicId);
          return match.gapId;
        } catch (_) {
          return null;
        }
      }, (_) => null);

      List<String> gapQuestions = <String>[];
      if (matchingGapId != null) {
        final gapResult = await _knowledgeGapService!.buildTargetedPractice(
          userId,
          matchingGapId,
        );
        gapQuestions = gapResult.fold((r) => r.questionIds, (_) => <String>[]);
      } else {
        // No gap for this topic; treat gap questions as empty (do not call with topicId)
        gapQuestions = <String>[];
      }

      // Ensure we pass a valid subjectId to getTopicsForReview by fetching the topic
      final topicResult = await _contentRepository!.getTopicById(topicId);
      final topic = topicResult.fold((t) => t, (_) => null);
      final subjectIdForReview = topic?.subjectId ?? topicId.split('_').first;
      final reviewResult = await _adaptiveLearningService!.getTopicsForReview(
        userId,
        subjectIdForReview,
        limit: 5,
      );
      final reviewTopics = reviewResult.fold(
        (r) => r.map((e) => e.topicId).toList(),
        (_) => <String>[],
      );
      final reviewQuestions = <String>[];
      for (final t in reviewTopics) {
        final qResult = await _contentRepository!.getQuestionsByTopicId(t);
        qResult.fold(
          (qs) => reviewQuestions.addAll(qs.map((q) => q.id)),
          (_) {},
        );
      }
      final gapCount = (count * RecommendationConstants.gapQuestionRatio)
          .round();
      final reviewCount = (count * RecommendationConstants.reviewQuestionRatio)
          .round();
      final newCount = count - gapCount - reviewCount;
      final selectedGap = gapQuestions.take(gapCount).toList();
      final selectedReview = reviewQuestions.take(reviewCount).toList();
      final newQuestionsResult = await _contentRepository!.getRandomQuestions(
        topicId,
        count: newCount,
        difficulty: difficulty,
      );
      final selectedNew = newQuestionsResult.fold(
        (qs) => qs.map((q) => q.id).toList(),
        (_) => <String>[],
      );
      final allIds = [...selectedGap, ...selectedReview, ...selectedNew];
      final questions = <Question>[];
      final sources = <String, String>{};
      for (final id in allIds) {
        final qRes = await _contentRepository!.getQuestionById(id);
        qRes.fold((q) {
          questions.add(q);
          if (selectedGap.contains(q.id)) {
            sources[q.id] = 'gap';
          } else if (selectedReview.contains(q.id)) {
            sources[q.id] = 'review';
          } else {
            sources[q.id] = 'new';
          }
        }, (_) {});
      }
      final avgDiff = questions.isEmpty
          ? DifficultyLevel.beginner
          : (() {
              final total = questions
                  .map((q) => q.difficulty.index)
                  .reduce((a, b) => a + b);
              final avgIndexDouble = total / questions.length;
              var idx = avgIndexDouble.round();
              final maxIdx = DifficultyLevel.values.length - 1;
              if (idx < 0) idx = 0;
              if (idx > maxIdx) idx = maxIdx;
              return DifficultyLevel.values[idx];
            })();
      return Result.success(
        PersonalizedQuestionSet(
          setId: const Uuid().v4(),
          userId: userId,
          topicId: topicId,
          questions: questions,
          questionSources: sources,
          averageDifficulty: avgDiff,
          selectionRationale: 'Personalized set for $topicId',
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // --- Learning Path Generation ---
  Future<Result<LearningPath>> generateLearningPath(
    String userId,
    String subjectId, {
    String strategy = 'balanced',
    String? goalDescription,
  }) async {
    try {
      _checkInitialized();
      // 1) Load all topics for subject
      final topicsRes = await _contentRepository!.getTopicsBySubjectId(
        subjectId,
      );
      final topics = topicsRes.fold((t) => t, (_) => <Topic>[]);
      if (topics.isEmpty)
        return Result.error(ValidationFailure('No topics found'));

      // 2) Fetch knowledge gaps and user progress
      final gapsRes = await _knowledgeGapService!.buildPracticeForAllGaps(
        userId,
        maxGaps: 50,
      );
      final gaps = gapsRes.fold(
        (g) => g,
        (_) => <TargetedPracticeRecommendation>[],
      );

      final progressRes = await _userProgressRepository!.getByUserId(userId);
      final progressList = progressRes.fold((p) => p, (_) => <dynamic>[]);

      // no-op helper removed

      List<Topic> ordered = [];

      switch (strategy) {
        case 'gap-first':
          // Prioritize topics that have gaps
          final gapTopicIds = gaps.map((g) => g.topicId).toSet();
          final gapTopics = topics
              .where((t) => gapTopicIds.contains(t.id))
              .toList();
          final other = topics
              .where((t) => !gapTopicIds.contains(t.id))
              .toList();
          ordered = [...gapTopics, ...other];
          break;
        case 'sequential':
          // Use content order as-is (topics list assumed to be in sequence)
          ordered = List<Topic>.from(topics);
          break;
        case 'mastery-based':
          // Order by increasing mastery (less mastered first)
          final Map<String, double> mastery = {};
          for (final p in progressList) {
            mastery[p.topicId] = p.averageScore;
          }
          ordered = List<Topic>.from(topics)
            ..sort(
              (a, b) => (mastery[a.id] ?? 0.0).compareTo(mastery[b.id] ?? 0.0),
            );
          break;
        case 'balanced':
        default:
          // Mix gap, review urgency and mastery: compute composite similar to topic recommendations
          final List<TopicRecommendation> recs = [];
          for (final t in topics) {
            final u = await _calculateUrgencyScore(userId, t.id);
            final r = await _calculateReadinessScore(
              userId,
              t.id,
              t.prerequisiteTopicIds,
            );
            final imp = _calculateImpactScore(t.id, topics);
            final e = await _calculateEngagementScore(userId, t.id);
            final composite =
                u * RecommendationConstants.urgencyWeight +
                r * RecommendationConstants.readinessWeight +
                imp * RecommendationConstants.impactWeight +
                e * RecommendationConstants.engagementWeight;
            recs.add(
              TopicRecommendation(
                topicId: t.id,
                topicName: t.name,
                subjectId: subjectId,
                compositeScore: composite,
                urgencyScore: u,
                readinessScore: r,
                impactScore: imp,
                engagementScore: e,
                recommendedDifficulty: t.difficulty,
                recommendationReason: '',
                prerequisiteTopicIds: t.prerequisiteTopicIds,
                hasUnmetPrerequisites: false,
                hasKnowledgeGap: false,
                isOverdueForReview: false,
                estimatedMinutes: t.estimatedDurationMinutes,
              ),
            );
          }
          recs.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));
          final orderedIds = recs.map((r) => r.topicId).toList();
          ordered = orderedIds
              .map((id) => topics.firstWhere((t) => t.id == id))
              .toList();
      }

      // Build steps with actual recommended difficulties filled by awaiting adaptive service per topic
      final steps = <LearningPathStep>[];
      var stepIndex = 1;
      for (final t in ordered) {
        final diffRes = await _adaptiveLearningService!
            .getRecommendedDifficulty(userId, t.id, t.difficulty);
        final recommendedDifficulty = diffRes.fold(
          (d) => d.recommendedDifficulty,
          (_) => t.difficulty,
        );
        // Determine if already completed based on user progress
        final progRes = await _userProgressRepository!.getByUserAndTopic(
          userId,
          t.id,
        );
        final prog = progRes.fold((p) => p, (_) => null);
        final isCompleted =
            prog != null &&
            prog.averageScore >=
                RecommendationConstants.minimumMasteryForAdvancement;
        // map prereq topic ids to step numbers where possible
        final prereqStepNumbers = <String>[];
        for (final pid in t.prerequisiteTopicIds) {
          final idx = ordered.indexWhere((ot) => ot.id == pid);
          if (idx >= 0) prereqStepNumbers.add((idx + 1).toString());
        }
        steps.add(
          LearningPathStep(
            stepNumber: stepIndex,
            topicId: t.id,
            topicName: t.name,
            recommendedDifficulty: recommendedDifficulty,
            stepType: 'topic',
            objective: 'Master ${t.name}',
            estimatedMinutes: t.estimatedDurationMinutes,
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
            prerequisiteStepNumbers: prereqStepNumbers,
          ),
        );
        stepIndex++;
      }

      final totalMinutes = steps.fold<int>(0, (s, e) => s + e.estimatedMinutes);
      final completedCount = steps.where((s) => s.isCompleted).length;

      final path = LearningPath(
        pathId: const Uuid().v4(),
        userId: userId,
        subjectId: subjectId,
        strategy: strategy,
        steps: steps,
        totalSteps: steps.length,
        completedSteps: completedCount,
        estimatedTotalMinutes: totalMinutes,
        goalDescription: goalDescription ?? 'Learning path for $subjectId',
        generatedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      return Result.success(path);
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  Future<Result<LearningPath>> updateLearningPath(
    String userId,
    LearningPath path,
  ) async {
    try {
      _checkInitialized();
      // Refresh progress for topics in the path and update completion flags
      // track if any step changed (currently unused)
      final now = DateTime.now();
      // Recalculate if older than configured interval
      if (path.lastUpdatedAt != null) {
        final ageDays = now.difference(path.lastUpdatedAt!).inDays;
        if (ageDays >= RecommendationConstants.pathRecalculationIntervalDays) {
          // regenerate path using same strategy
          final regenerated = await generateLearningPath(
            userId,
            path.subjectId,
            strategy: path.strategy,
            goalDescription: path.goalDescription,
          );
          return regenerated.fold(
            (p) => Result.success(p),
            (f) => Result.error(f),
          );
        }
      }

      final updatedSteps = <LearningPathStep>[];
      for (final step in path.steps) {
        final progRes = await _userProgressRepository!.getByUserAndTopic(
          userId,
          step.topicId,
        );
        final prog = progRes.fold((p) => p, (_) => null);
        final nowCompleted =
            prog != null &&
            prog.averageScore >=
                RecommendationConstants.minimumMasteryForAdvancement;
        updatedSteps.add(
          LearningPathStep(
            stepNumber: step.stepNumber,
            topicId: step.topicId,
            topicName: step.topicName,
            recommendedDifficulty: step.recommendedDifficulty,
            stepType: step.stepType,
            objective: step.objective,
            estimatedMinutes: step.estimatedMinutes,
            isCompleted: nowCompleted,
            completedAt: nowCompleted ? DateTime.now() : null,
            prerequisiteStepNumbers: step.prerequisiteStepNumbers,
          ),
        );
      }

      final completedCount = updatedSteps.where((s) => s.isCompleted).length;
      final updatedPath = LearningPath(
        pathId: path.pathId,
        userId: path.userId,
        subjectId: path.subjectId,
        strategy: path.strategy,
        steps: updatedSteps,
        totalSteps: updatedSteps.length,
        completedSteps: completedCount,
        estimatedTotalMinutes: updatedSteps.fold<int>(
          0,
          (s, e) => s + e.estimatedMinutes,
        ),
        goalDescription: path.goalDescription,
        generatedAt: path.generatedAt,
        lastUpdatedAt: DateTime.now(),
      );

      return Result.success(updatedPath);
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // --- Recommendation Summary ---
  Future<Result<RecommendationSummary>> getRecommendationSummary(
    String userId,
    String subjectId,
  ) async {
    try {
      _checkInitialized();
      final nextTopicResult = await getNextTopicRecommendation(
        userId,
        subjectId,
      );
      final altTopicsResult = await getTopicRecommendations(
        userId,
        subjectId,
        limit: 3,
      );
      final practiceResult = await nextTopicResult.fold(
        (next) async => await getRecommendedPracticeSet(userId, next.topicId),
        (f) async => Result.error(UnknownFailure('No next topic')),
      );
      // Populate critical gaps (topics with high/critical severity)
      final criticalGaps = <String>[];
      final gapsResAll = await _knowledgeGapService!.buildPracticeForAllGaps(
        userId,
        maxGaps: 50,
      );
      gapsResAll.fold((recs) {
        for (final r in recs) {
          // Priority score 5 or 4 map to critical/high; we include 5 and 4
          if (r.priorityScore >= 4) criticalGaps.add(r.topicId);
        }
      }, (_) {});

      // Populate overdue reviews
      final overdueReviews = <String>[];
      final reviewRes = await _adaptiveLearningService!.getTopicsForReview(
        userId,
        subjectId,
        limit: 50,
      );
      reviewRes.fold((schedules) {
        for (final s in schedules) {
          if (s.isOverdue) overdueReviews.add(s.topicId);
        }
      }, (_) {});

      // Build overall recommendation message
      final hasCritical = criticalGaps.isNotEmpty;
      final hasOverdue = overdueReviews.isNotEmpty;
      final nextTopic = nextTopicResult.fold((t) => t, (_) => null);
      String overall;
      if (hasCritical && hasOverdue) {
        overall =
            'Critical gaps and overdue reviews detected. Prioritize gap-focused practice, then review overdue topics before advancing.';
      } else if (hasCritical) {
        overall =
            'Critical knowledge gaps detected. Start with targeted practice on the listed topics.';
      } else if (hasOverdue) {
        overall =
            'You have overdue reviews. Refresh these topics soon to maintain retention.';
      } else if (nextTopic != null) {
        overall =
            'Next recommended topic: ${nextTopic.topicName}. Focus here to continue progress.';
      } else {
        overall =
            'No critical issues detected. Continue with recommended practice and reviews.';
      }
      return Result.success(
        RecommendationSummary(
          userId: userId,
          subjectId: subjectId,
          nextTopic: nextTopicResult.fold((t) => t, (_) => null),
          alternativeTopics: altTopicsResult.fold((l) => l, (_) => []),
          suggestedPractice: practiceResult.fold((p) => p, (_) => null),
          criticalGapTopics: criticalGaps,
          overdueReviewTopics: overdueReviews,
          overallRecommendation: overall,
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // --- Question Selection for Practice Sessions ---
  Future<Result<List<Question>>> selectQuestionsForSession(
    String userId,
    String topicId,
    DifficultyLevel difficulty,
    int count,
  ) async {
    try {
      _checkInitialized();
      final result = await getPersonalizedQuestions(
        userId,
        topicId,
        questionCount: count,
        difficulty: difficulty,
      );
      return result.fold(
        (set) => Result.success(set.questions),
        (failure) => Result.error(failure),
      );
    } catch (e, st) {
      return Result.error(_mapException(e, st));
    }
  }

  // --- Private Helpers ---
  Future<double> _calculateUrgencyScore(String userId, String topicId) async {
    try {
      // 1) Check for knowledge gaps for this topic
      final gapsResult = await _knowledgeGapService!.buildPracticeForAllGaps(
        userId,
        maxGaps: 20,
      );
      final gapMatch = gapsResult.fold((recs) {
        try {
          return recs.firstWhere((r) => r.topicId == topicId);
        } catch (_) {
          return null;
        }
      }, (_) => null);

      double severityScore = 0.0; // 0..1
      if (gapMatch != null) {
        // priorityScore is 2..5 in KnowledgeGapService; normalize to 0..1
        severityScore = (gapMatch.priorityScore / 5.0).clamp(0.0, 1.0);
      }

      // 2) Check spaced-repetition / review overdue priority
      double reviewPriorityScore = 0.0;
      // Need subjectId to call getTopicsForReview; attempt to fetch topic
      final topicResult = await _contentRepository!.getTopicById(topicId);
      final topic = topicResult.fold((t) => t, (_) => null);
      final subjectId = topic?.subjectId ?? topicId.split('_').first;

      final reviewResult = await _adaptiveLearningService!.getTopicsForReview(
        userId,
        subjectId,
        limit: 50,
      );
      reviewResult.fold((schedules) {
        try {
          final schedule = schedules.firstWhere((s) => s.topicId == topicId);
          // priority is int; normalize to 0..1 assuming max 5
          reviewPriorityScore = (schedule.priority / 5.0).clamp(0.0, 1.0);
          // inflate if overdue
          if (schedule.isOverdue)
            reviewPriorityScore = reviewPriorityScore.clamp(0.6, 1.0);
        } catch (_) {
          // not in review list -> keep 0
        }
      }, (_) {});

      // 3) Combine signals: gap severity heavier than review priority
      final combined = (severityScore * 0.75) + (reviewPriorityScore * 0.25);
      return combined.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _calculateReadinessScore(
    String userId,
    String topicId,
    List<String> prereqs,
  ) async {
    try {
      // If there are no prerequisites, readiness is based on topic or subject mastery
      if (prereqs.isEmpty) {
        final progRes = await _userProgressRepository!.getByUserAndTopic(
          userId,
          topicId,
        );
        final prog = progRes.fold((p) => p, (_) => null);
        if (prog != null) return prog.averageScore.clamp(0.0, 1.0);

        // fallback to subject averages
        final topicRes = await _contentRepository!.getTopicById(topicId);
        final topic = topicRes.fold((t) => t, (_) => null);
        final subjectAverages = await _userProgressRepository!
            .getSubjectAverages(userId);
        final averages = subjectAverages.fold(
          (m) => m,
          (_) => <String, double>{},
        );
        final subjAvg = topic != null
            ? (averages[topic.subjectId] ?? 0.5)
            : 0.5;
        return subjAvg.clamp(0.0, 1.0);
      }

      // With prerequisites: compute proportion of prerequisites completed
      var completed = 0;
      var checked = 0;
      for (final pid in prereqs) {
        checked++;
        final pRes = await _userProgressRepository!.getByUserAndTopic(
          userId,
          pid,
        );
        final p = pRes.fold((v) => v, (_) => null);
        if (p != null &&
            p.averageScore >=
                RecommendationConstants.prerequisiteCompletionThreshold) {
          completed++;
        }
      }

      final prereqProportion = checked == 0 ? 1.0 : (completed / checked);

      // Also factor in any existing progress on the topic itself (light weight)
      final topicProgRes = await _userProgressRepository!.getByUserAndTopic(
        userId,
        topicId,
      );
      final topicProg = topicProgRes.fold((v) => v, (_) => null);
      final topicScore = topicProg?.averageScore ?? 0.0;

      final readiness = (prereqProportion * 0.8) + (topicScore * 0.2);
      return readiness.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  double _calculateImpactScore(String topicId, List<Topic> allTopics) {
    try {
      // Count how many topics depend on this topic (appear in their prerequisiteTopicIds)
      final Map<String, int> dependentCounts = {};
      for (final t in allTopics) {
        for (final pre in t.prerequisiteTopicIds) {
          dependentCounts[pre] = (dependentCounts[pre] ?? 0) + 1;
        }
      }

      final count = dependentCounts[topicId] ?? 0;
      final maxDependents = dependentCounts.values.isEmpty
          ? 0
          : dependentCounts.values.reduce((a, b) => a > b ? a : b);
      if (maxDependents == 0) return 0.5;
      final impact = (count / maxDependents).clamp(0.0, 1.0);
      return impact;
    } catch (e) {
      return 0.5;
    }
  }

  Future<double> _calculateEngagementScore(
    String userId,
    String topicId,
  ) async {
    try {
      // Get recent sessions for this topic
      final sessionsRes = await _learningSessionRepository!.getSessionsByTopic(
        userId,
        topicId,
      );
      final sessions = sessionsRes.fold((s) => s, (_) => <dynamic>[]);

      if (sessions.isEmpty) {
        // No sessions -> low-medium engagement
        return 0.4;
      }

      // Activity: number of sessions in recent window
      final now = DateTime.now();
      const recentDays = 14;
      final recentCount = sessions.where((s) {
        final end = s.endTime ?? s.startTime;
        return now.difference(end).inDays <= recentDays;
      }).length;

      final activityScore = (recentCount / 5.0).clamp(0.0, 1.0);

      // Accuracy: average accuracy across sessions for this topic
      double accuracy = 0.0;
      if (sessions.isNotEmpty) {
        final total = sessions.fold<double>(
          0.0,
          (sum, s) => sum + (s.accuracyRate ?? 0.0),
        );
        accuracy = total / sessions.length;
      } else {
        final avgRes = await _learningSessionRepository!.getAverageAccuracy(
          userId,
        );
        accuracy = avgRes.fold((a) => a, (_) => 0.0);
      }

      final engagement = (activityScore * 0.6) + (accuracy * 0.4);
      return engagement.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  String _buildRecommendationReason(
    double urgency,
    double readiness,
    double impact,
    double engagement,
  ) {
    if (urgency >= 0.85) return 'Critical knowledge gap detected';
    if (readiness >= 0.85)
      return 'Ready to advance after mastering prerequisites';
    if (impact >= 0.8) return 'Foundational topic for future learning';
    if (engagement >= 0.8) return 'High engagement, keep up the momentum!';
    return 'Balanced recommendation based on your progress.';
  }

  void _checkInitialized() {
    if (!_isInitialized)
      throw StateError('RecommendationService not initialized');
  }

  Failure _mapException(Object e, StackTrace st) {
    if (e is TimeoutException) return TimeoutFailure('Operation timed out');
    if (e is StateError) return ValidationFailure(e.toString());
    return UnknownFailure('Unknown error: $e');
  }
}
