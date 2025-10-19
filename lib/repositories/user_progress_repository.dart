import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/user_progress.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Repository interface for UserProgress operations
abstract interface class UserProgressRepository {
  // Create operations
  Future<Result<UserProgress>> create(UserProgress progress);
  Future<Result<List<UserProgress>>> createBatch(
    List<UserProgress> progressList,
  );

  // Read operations
  Future<Result<UserProgress>> getById(String id);
  Future<Result<UserProgress?>> getByUserAndTopic(
    String userId,
    String topicId,
  );
  Future<Result<List<UserProgress>>> getByUserId(String userId);
  Future<Result<List<UserProgress>>> getBySubjectId(
    String userId,
    String subjectId,
  );
  Future<Result<List<UserProgress>>> getAll();
  Stream<List<UserProgress>> watchByUserId(String userId);

  // Update operations
  Future<Result<UserProgress>> update(UserProgress progress);
  Future<Result<void>> updateBatch(List<UserProgress> progressList);

  // Delete operations
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteByUserId(String userId);

  // Query operations
  Future<Result<List<UserProgress>>> getRecentProgress(
    String userId, {
    int limit = 10,
  });
  Future<Result<List<UserProgress>>> getCompletedTopics(String userId);
  Future<Result<Map<String, double>>> getSubjectAverages(String userId);
}

/// Concrete implementation of UserProgressRepository using Hive
class UserProgressRepositoryImpl implements UserProgressRepository {
  final DatabaseService _databaseService;

  const UserProgressRepositoryImpl(this._databaseService);

  @override
  Future<Result<UserProgress>> create(UserProgress progress) async {
    try {
      final box = _databaseService.userProgressBox;
      if (box.containsKey(progress.id)) {
        return Result.error(
          AlreadyExistsFailure(
            'UserProgress with ID ${progress.id} already exists',
          ),
        );
      }

      await box
          .put(progress.id, progress)
          .timeout(QueryLimits.operationTimeout);
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> createBatch(
    List<UserProgress> progressList,
  ) async {
    try {
      if (progressList.length > QueryLimits.maxBatchSize) {
        return Result.error(
          ValidationFailure(
            'Batch size ${progressList.length} exceeds maximum of ${QueryLimits.maxBatchSize}',
          ),
        );
      }

      final box = _databaseService.userProgressBox;
      final map = {for (var p in progressList) p.id: p};
      await box.putAll(map).timeout(QueryLimits.operationTimeout);
      return Result.success(progressList);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create UserProgress batch: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating UserProgress batch',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<UserProgress>> getById(String id) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.get(id);
      if (progress == null) {
        return Result.error(
          NotFoundFailure('UserProgress with ID $id not found'),
        );
      }
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<UserProgress?>> getByUserAndTopic(
    String userId,
    String topicId,
  ) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values
          .where((p) => p.userId == userId && p.topicId == topicId)
          .firstOrNull;
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> getByUserId(String userId) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values.where((p) => p.userId == userId).toList();
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get UserProgress list: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting UserProgress list',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> getBySubjectId(
    String userId,
    String subjectId,
  ) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values
          .where((p) => p.userId == userId && p.topicId.startsWith(subjectId))
          .toList();
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get UserProgress by subject: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting UserProgress by subject',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> getAll() async {
    try {
      final box = _databaseService.userProgressBox;
      return Result.success(box.values.toList());
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get all UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting all UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<UserProgress>> watchByUserId(String userId) {
    final box = _databaseService.userProgressBox;
    return box
        .watch()
        .map((_) {
          return box.values.where((p) => p.userId == userId).toList();
        })
        .handleError((error) {
          debugPrint('Error watching UserProgress: $error');
          return <UserProgress>[];
        });
  }

  @override
  Future<Result<UserProgress>> update(UserProgress progress) async {
    try {
      final box = _databaseService.userProgressBox;
      if (!box.containsKey(progress.id)) {
        return Result.error(
          NotFoundFailure('UserProgress with ID ${progress.id} not found'),
        );
      }

      await box
          .put(progress.id, progress)
          .timeout(QueryLimits.operationTimeout);
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateBatch(List<UserProgress> progressList) async {
    try {
      if (progressList.length > QueryLimits.maxBatchSize) {
        return Result.error(
          ValidationFailure(
            'Batch size ${progressList.length} exceeds maximum of ${QueryLimits.maxBatchSize}',
          ),
        );
      }

      final box = _databaseService.userProgressBox;
      final map = {for (var p in progressList) p.id: p};
      await box.putAll(map).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update UserProgress batch: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating UserProgress batch',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final box = _databaseService.userProgressBox;
      await box.delete(id).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteByUserId(String userId) async {
    try {
      final box = _databaseService.userProgressBox;
      final keys = box.values
          .where((p) => p.userId == userId)
          .map((p) => p.id)
          .toList();
      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete UserProgress by user: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting UserProgress by user',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> getRecentProgress(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values.where((p) => p.userId == userId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Result.success(progress.take(limit).toList());
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get recent UserProgress: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting recent UserProgress',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<UserProgress>>> getCompletedTopics(String userId) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values
          .where((p) => p.userId == userId && p.averageScore >= 0.8)
          .toList();
      return Result.success(progress);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get completed topics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting completed topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, double>>> getSubjectAverages(String userId) async {
    try {
      final box = _databaseService.userProgressBox;
      final progress = box.values.where((p) => p.userId == userId);

      final Map<String, List<double>> scoresBySubject = {};
      for (final p in progress) {
        final subjectId = p.topicId.split('/').first;
        scoresBySubject.putIfAbsent(subjectId, () => []).add(p.averageScore);
      }

      final Map<String, double> averages = {};
      for (final entry in scoresBySubject.entries) {
        final scores = entry.value;
        if (scores.isNotEmpty) {
          averages[entry.key] = scores.reduce((a, b) => a + b) / scores.length;
        }
      }

      return Result.success(averages);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get subject averages: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting subject averages',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
