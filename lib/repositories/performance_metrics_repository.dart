import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Repository interface for PerformanceMetrics operations
abstract interface class PerformanceMetricsRepository {
  // Core operations
  Future<Result<PerformanceMetrics>> create(PerformanceMetrics metrics);
  Future<Result<PerformanceMetrics>> createOrUpdate(PerformanceMetrics metrics);
  Future<Result<PerformanceMetrics>> getById(String id);
  Future<Result<PerformanceMetrics?>> getByUserAndSubject(
    String userId,
    String subjectId,
  );
  Future<Result<List<PerformanceMetrics>>> getByUserId(String userId);
  Stream<PerformanceMetrics?> watchByUserAndSubject(
    String userId,
    String subjectId,
  );

  // Metric updates
  Future<Result<PerformanceMetrics>> incrementQuestionCount(
    String userId,
    String subjectId, {
    required bool isCorrect,
  });
  Future<Result<PerformanceMetrics>> updateAccuracyRate(
    String userId,
    String subjectId,
    DifficultyLevel level,
    double rate,
  );
  Future<Result<PerformanceMetrics>> updateTopicMastery(
    String userId,
    String subjectId,
    String topicId,
    double score,
  );

  // Delete operations
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteByUserId(String userId);

  // Analytics queries (scoped to userId and subjectId)
  Future<Result<double>> getOverallAccuracy(String userId, String subjectId);
  Future<Result<Map<DifficultyLevel, double>>> getAccuracyByDifficulty(
    String userId,
    String subjectId,
  );
  Future<Result<List<String>>> getStrengthTopics(
    String userId,
    String subjectId,
  );
  Future<Result<List<String>>> getWeaknessTopics(
    String userId,
    String subjectId,
  );
  Future<Result<Map<String, int>>> getAverageResponseTimes(
    String userId,
    String subjectId,
  );
}

/// Concrete implementation of PerformanceMetricsRepository using Hive
class PerformanceMetricsRepositoryImpl implements PerformanceMetricsRepository {
  final DatabaseService _databaseService;

  const PerformanceMetricsRepositoryImpl(this._databaseService);

  @override
  Future<Result<PerformanceMetrics>> create(PerformanceMetrics metrics) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      if (box.containsKey(metrics.id)) {
        return Result.error(
          AlreadyExistsFailure(
            'PerformanceMetrics with ID ${metrics.id} already exists',
          ),
        );
      }

      await box.put(metrics.id, metrics).timeout(QueryLimits.operationTimeout);
      return Result.success(metrics);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create PerformanceMetrics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating PerformanceMetrics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<PerformanceMetrics>> createOrUpdate(
    PerformanceMetrics metrics,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final existing = box.values.firstWhere(
        (m) => m.userId == metrics.userId && m.subjectId == metrics.subjectId,
        orElse: () => metrics,
      );

      // If existing found, merge values
      if (existing != metrics) {
        // Create a new instance with merged values
        metrics = PerformanceMetrics(
          id: existing.id,
          userId: existing.userId,
          subjectId: existing.subjectId,
          accuracyRates: {...existing.accuracyRates, ...metrics.accuracyRates},
          averageResponseTimes: {
            ...existing.averageResponseTimes,
            ...metrics.averageResponseTimes,
          },
          topicMasteryScores: {
            ...existing.topicMasteryScores,
            ...metrics.topicMasteryScores,
          },
          strengthTopicIds: {
            ...existing.strengthTopicIds,
            ...metrics.strengthTopicIds,
          }.toList(),
          weaknessTopicIds: {
            ...existing.weaknessTopicIds,
            ...metrics.weaknessTopicIds,
          }.toList(),
          totalQuestionsAttempted:
              existing.totalQuestionsAttempted +
              metrics.totalQuestionsAttempted,
          totalCorrectAnswers:
              existing.totalCorrectAnswers + metrics.totalCorrectAnswers,
          lastUpdated: DateTime.now(),
          createdAt: existing.createdAt,
        );
      }

      await box.put(metrics.id, metrics).timeout(QueryLimits.operationTimeout);
      return Result.success(metrics);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create/update PerformanceMetrics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error in create/update PerformanceMetrics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<PerformanceMetrics>> getById(String id) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final metrics = box.get(id);
      if (metrics == null) {
        return Result.error(
          NotFoundFailure('PerformanceMetrics with ID $id not found'),
        );
      }
      return Result.success(metrics);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get PerformanceMetrics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting PerformanceMetrics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<PerformanceMetrics?>> getByUserAndSubject(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final metrics = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .firstOrNull;
      return Result.success(metrics);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get PerformanceMetrics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting PerformanceMetrics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<PerformanceMetrics>>> getByUserId(String userId) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final metrics = box.values.where((m) => m.userId == userId).toList();
      return Result.success(metrics);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get PerformanceMetrics list: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting PerformanceMetrics list',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<PerformanceMetrics?> watchByUserAndSubject(
    String userId,
    String subjectId,
  ) {
    final box = _databaseService.performanceMetricsBox;
    return box
        .watch()
        .map((_) {
          return box.values
              .where((m) => m.userId == userId && m.subjectId == subjectId)
              .firstOrNull;
        })
        .handleError((error) {
          debugPrint('Error watching PerformanceMetrics: $error');
          return null;
        });
  }

  @override
  Future<Result<PerformanceMetrics>> incrementQuestionCount(
    String userId,
    String subjectId, {
    required bool isCorrect,
  }) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return Result.error(
          NotFoundFailure(
            'No PerformanceMetrics found for user $userId and subject $subjectId',
          ),
        );
      }

      final metrics = matches.first;
      final updated = PerformanceMetrics(
        id: metrics.id,
        userId: metrics.userId,
        subjectId: metrics.subjectId,
        accuracyRates: metrics.accuracyRates,
        averageResponseTimes: metrics.averageResponseTimes,
        topicMasteryScores: metrics.topicMasteryScores,
        strengthTopicIds: metrics.strengthTopicIds,
        weaknessTopicIds: metrics.weaknessTopicIds,
        totalQuestionsAttempted: metrics.totalQuestionsAttempted + 1,
        totalCorrectAnswers: metrics.totalCorrectAnswers + (isCorrect ? 1 : 0),
        lastUpdated: DateTime.now(),
        createdAt: metrics.createdAt,
      );

      await box.put(metrics.id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to increment question count: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error incrementing question count',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<PerformanceMetrics>> updateAccuracyRate(
    String userId,
    String subjectId,
    DifficultyLevel level,
    double rate,
  ) async {
    try {
      if (rate < 0 || rate > 1) {
        return Result.error(
          ValidationFailure('Accuracy rate must be between 0 and 1'),
        );
      }

      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return Result.error(
          NotFoundFailure(
            'No PerformanceMetrics found for user $userId and subject $subjectId',
          ),
        );
      }

      final metrics = matches.first;
      final accuracyRates = Map<DifficultyLevel, double>.from(
        metrics.accuracyRates,
      )..[level] = rate;

      final updated = PerformanceMetrics(
        id: metrics.id,
        userId: metrics.userId,
        subjectId: metrics.subjectId,
        accuracyRates: accuracyRates,
        averageResponseTimes: metrics.averageResponseTimes,
        topicMasteryScores: metrics.topicMasteryScores,
        strengthTopicIds: metrics.strengthTopicIds,
        weaknessTopicIds: metrics.weaknessTopicIds,
        totalQuestionsAttempted: metrics.totalQuestionsAttempted,
        totalCorrectAnswers: metrics.totalCorrectAnswers,
        lastUpdated: DateTime.now(),
        createdAt: metrics.createdAt,
      );

      await box.put(metrics.id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update accuracy rate: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating accuracy rate',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<PerformanceMetrics>> updateTopicMastery(
    String userId,
    String subjectId,
    String topicId,
    double score,
  ) async {
    try {
      if (score < 0 || score > 1) {
        return Result.error(
          ValidationFailure('Mastery score must be between 0 and 1'),
        );
      }

      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return Result.error(
          NotFoundFailure(
            'No PerformanceMetrics found for user $userId and subject $subjectId',
          ),
        );
      }

      final metrics = matches.first;
      final topicMasteryScores = Map<String, double>.from(
        metrics.topicMasteryScores,
      )..[topicId] = score;

      // Recompute strength and weakness topic lists
      final strengthTopicIds = topicMasteryScores.entries
          .where((e) => e.value > 0.8)
          .map((e) => e.key)
          .toList();
      final weaknessTopicIds = topicMasteryScores.entries
          .where((e) => e.value < 0.5)
          .map((e) => e.key)
          .toList();

      final updated = PerformanceMetrics(
        id: metrics.id,
        userId: metrics.userId,
        subjectId: metrics.subjectId,
        accuracyRates: metrics.accuracyRates,
        averageResponseTimes: metrics.averageResponseTimes,
        topicMasteryScores: topicMasteryScores,
        strengthTopicIds: strengthTopicIds,
        weaknessTopicIds: weaknessTopicIds,
        totalQuestionsAttempted: metrics.totalQuestionsAttempted,
        totalCorrectAnswers: metrics.totalCorrectAnswers,
        lastUpdated: DateTime.now(),
        createdAt: metrics.createdAt,
      );

      await box.put(metrics.id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update topic mastery: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating topic mastery',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      await box.delete(id).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete PerformanceMetrics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting PerformanceMetrics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteByUserId(String userId) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final keys = box.values
          .where((m) => m.userId == userId)
          .map((m) => m.id)
          .toList();
      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete PerformanceMetrics by user: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting PerformanceMetrics by user',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<double>> getOverallAccuracy(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return const Result.success(0.0);
      }

      final metrics = matches.first;
      return Result.success(
        metrics.totalQuestionsAttempted > 0
            ? metrics.totalCorrectAnswers / metrics.totalQuestionsAttempted
            : 0.0,
      );
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get overall accuracy: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting overall accuracy',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<DifficultyLevel, double>>> getAccuracyByDifficulty(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return Result.success({
          for (final level in DifficultyLevel.values) level: 0.0,
        });
      }

      final metrics = matches.first;
      final results = Map<DifficultyLevel, double>.from(metrics.accuracyRates);

      // Fill in missing difficulty levels with 0.0
      for (final level in DifficultyLevel.values) {
        results.putIfAbsent(level, () => 0.0);
      }

      return Result.success(results);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get accuracy by difficulty: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting accuracy by difficulty',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getStrengthTopics(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return const Result.success([]);
      }

      final metrics = matches.first;
      return Result.success(metrics.strengthTopicIds);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get strength topics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting strength topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getWeaknessTopics(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return const Result.success([]);
      }

      final metrics = matches.first;
      return Result.success(metrics.weaknessTopicIds);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get weakness topics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting weakness topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, int>>> getAverageResponseTimes(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.performanceMetricsBox;
      final matches = box.values
          .where((m) => m.userId == userId && m.subjectId == subjectId)
          .toList();

      if (matches.isEmpty) {
        return const Result.success({});
      }

      final metrics = matches.first;
      return Result.success(metrics.averageResponseTimes);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get average response times: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting average response times',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
