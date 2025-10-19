import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Repository interface for KnowledgeGap operations
abstract interface class KnowledgeGapRepository {
  // Core operations
  Future<Result<KnowledgeGap>> create(KnowledgeGap gap);
  Future<Result<List<KnowledgeGap>>> createBatch(List<KnowledgeGap> gapList);
  Future<Result<KnowledgeGap>> getById(String id);
  Future<Result<List<KnowledgeGap>>> getByUserId(String userId);
  Future<Result<List<KnowledgeGap>>> getByTopicId(
    String userId,
    String topicId,
  );
  Future<Result<List<KnowledgeGap>>> getUnresolvedGaps(String userId);
  Future<Result<List<KnowledgeGap>>> getGapsBySeverity(
    String userId,
    GapSeverity severity,
  );
  Future<Result<List<KnowledgeGap>>> getPriorityGaps(
    String userId, {
    int limit = 5,
  });
  Stream<List<KnowledgeGap>> watchUnresolvedGaps(String userId);

  // Update operations
  Future<Result<KnowledgeGap>> update(KnowledgeGap gap);
  Future<Result<KnowledgeGap>> markAsResolved(String id);
  Future<Result<KnowledgeGap>> updateSeverity(String id, GapSeverity severity);
  Future<Result<KnowledgeGap>> addRecommendedQuestions(
    String id,
    List<String> questionIds,
  );

  // Delete operations
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteByUserId(String userId);
  Future<Result<void>> deleteResolvedGaps(String userId);

  // Analytics
  Future<Result<int>> getGapCount(String userId);
  Future<Result<Map<GapSeverity, int>>> getGapCountBySeverity(String userId);
  Future<Result<Map<String, int>>> getGapCountByTopic(String userId);
  Future<Result<double>> getResolutionRate(String userId);
  Future<Result<List<String>>> getMostProblematicTopics(
    String userId, {
    int limit = 5,
  });
}

/// Concrete implementation of KnowledgeGapRepository using Hive
class KnowledgeGapRepositoryImpl implements KnowledgeGapRepository {
  final DatabaseService _databaseService;

  const KnowledgeGapRepositoryImpl(this._databaseService);

  @override
  Future<Result<KnowledgeGap>> create(KnowledgeGap gap) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      if (box.containsKey(gap.id)) {
        return Result.error(
          AlreadyExistsFailure('KnowledgeGap with ID ${gap.id} already exists'),
        );
      }

      await box.put(gap.id, gap).timeout(QueryLimits.operationTimeout);
      return Result.success(gap);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create KnowledgeGap: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating KnowledgeGap',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> createBatch(
    List<KnowledgeGap> gapList,
  ) async {
    try {
      if (gapList.length > QueryLimits.maxBatchSize) {
        return Result.error(
          ValidationFailure(
            'Batch size ${gapList.length} exceeds maximum of ${QueryLimits.maxBatchSize}',
          ),
        );
      }

      final box = _databaseService.knowledgeGapBox;
      final map = {for (var gap in gapList) gap.id: gap};
      await box.putAll(map).timeout(QueryLimits.operationTimeout);
      return Result.success(gapList);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create KnowledgeGap batch: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating KnowledgeGap batch',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<KnowledgeGap>> getById(String id) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gap = box.get(id);
      if (gap == null) {
        return Result.error(
          NotFoundFailure('KnowledgeGap with ID $id not found'),
        );
      }
      return Result.success(gap);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get KnowledgeGap: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting KnowledgeGap',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> getByUserId(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values.where((gap) => gap.userId == userId).toList();
      return Result.success(gaps);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get KnowledgeGap list: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting KnowledgeGap list',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> getByTopicId(
    String userId,
    String topicId,
  ) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values
          .where((gap) => gap.userId == userId && gap.topicId == topicId)
          .toList();
      return Result.success(gaps);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get KnowledgeGap list by topic: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting KnowledgeGap list by topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> getUnresolvedGaps(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values
          .where((gap) => gap.userId == userId && !gap.isResolved)
          .toList();
      return Result.success(gaps);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get unresolved gaps: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting unresolved gaps',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> getGapsBySeverity(
    String userId,
    GapSeverity severity,
  ) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values
          .where((gap) => gap.userId == userId && gap.severity == severity)
          .toList();
      return Result.success(gaps);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get gaps by severity: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting gaps by severity',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeGap>>> getPriorityGaps(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps =
          box.values
              .where((gap) => gap.userId == userId && !gap.isResolved)
              .toList()
            ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
      return Result.success(gaps.take(limit).toList());
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get priority gaps: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting priority gaps',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<KnowledgeGap>> watchUnresolvedGaps(String userId) {
    final box = _databaseService.knowledgeGapBox;
    return box
        .watch()
        .map((_) {
          return box.values
              .where((gap) => gap.userId == userId && !gap.isResolved)
              .toList();
        })
        .handleError((error) {
          debugPrint('Error watching unresolved gaps: $error');
          return <KnowledgeGap>[];
        });
  }

  @override
  Future<Result<KnowledgeGap>> update(KnowledgeGap gap) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      if (!box.containsKey(gap.id)) {
        return Result.error(
          NotFoundFailure('KnowledgeGap with ID ${gap.id} not found'),
        );
      }

      await box.put(gap.id, gap).timeout(QueryLimits.operationTimeout);
      return Result.success(gap);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update KnowledgeGap: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating KnowledgeGap',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<KnowledgeGap>> markAsResolved(String id) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gap = box.get(id);
      if (gap == null) {
        return Result.error(
          NotFoundFailure('KnowledgeGap with ID $id not found'),
        );
      }

      final now = DateTime.now();
      final updated = KnowledgeGap(
        id: gap.id,
        userId: gap.userId,
        topicId: gap.topicId,
        description: gap.description,
        severity: gap.severity,
        relatedTopicIds: gap.relatedTopicIds,
        recommendedQuestionIds: gap.recommendedQuestionIds,
        isResolved: true,
        identifiedAt: gap.identifiedAt,
        resolvedAt: now,
        createdAt: gap.createdAt,
        updatedAt: now,
      );

      await box.put(id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to mark gap as resolved: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error marking gap as resolved',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<KnowledgeGap>> updateSeverity(
    String id,
    GapSeverity severity,
  ) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gap = box.get(id);
      if (gap == null) {
        return Result.error(
          NotFoundFailure('KnowledgeGap with ID $id not found'),
        );
      }

      final updated = KnowledgeGap(
        id: gap.id,
        userId: gap.userId,
        topicId: gap.topicId,
        description: gap.description,
        severity: severity,
        relatedTopicIds: gap.relatedTopicIds,
        recommendedQuestionIds: gap.recommendedQuestionIds,
        isResolved: gap.isResolved,
        identifiedAt: gap.identifiedAt,
        resolvedAt: gap.resolvedAt,
        createdAt: gap.createdAt,
        updatedAt: DateTime.now(),
      );

      await box.put(id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update gap severity: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating gap severity',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<KnowledgeGap>> addRecommendedQuestions(
    String id,
    List<String> questionIds,
  ) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gap = box.get(id);
      if (gap == null) {
        return Result.error(
          NotFoundFailure('KnowledgeGap with ID $id not found'),
        );
      }

      // Ensure idempotency by deduping IDs
      final existingIds = gap.recommendedQuestionIds.toSet();
      final newIds = questionIds
          .where((id) => !existingIds.contains(id))
          .toList();
      if (newIds.isEmpty) {
        return Result.success(gap);
      }

      final updated = KnowledgeGap(
        id: gap.id,
        userId: gap.userId,
        topicId: gap.topicId,
        description: gap.description,
        severity: gap.severity,
        relatedTopicIds: gap.relatedTopicIds,
        recommendedQuestionIds: [...gap.recommendedQuestionIds, ...newIds],
        isResolved: gap.isResolved,
        identifiedAt: gap.identifiedAt,
        resolvedAt: gap.resolvedAt,
        createdAt: gap.createdAt,
        updatedAt: DateTime.now(),
      );

      await box.put(id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to add recommended questions: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error adding recommended questions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      await box.delete(id).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete KnowledgeGap: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting KnowledgeGap',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteByUserId(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final keys = box.values
          .where((gap) => gap.userId == userId)
          .map((gap) => gap.id)
          .toList();
      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete KnowledgeGap by user: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting KnowledgeGap by user',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteResolvedGaps(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final keys = box.values
          .where((gap) => gap.userId == userId && gap.isResolved)
          .map((gap) => gap.id)
          .toList();
      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete resolved gaps: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting resolved gaps',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getGapCount(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final count = box.values.where((gap) => gap.userId == userId).length;
      return Result.success(count);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get gap count: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting gap count',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<GapSeverity, int>>> getGapCountBySeverity(
    String userId,
  ) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values.where((gap) => gap.userId == userId);

      final Map<GapSeverity, int> counts = {};
      for (final severity in GapSeverity.values) {
        counts[severity] = gaps.where((gap) => gap.severity == severity).length;
      }

      return Result.success(counts);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get gap count by severity: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting gap count by severity',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, int>>> getGapCountByTopic(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values.where((gap) => gap.userId == userId);

      final Map<String, int> counts = {};
      for (final gap in gaps) {
        counts.update(gap.topicId, (count) => count + 1, ifAbsent: () => 1);
      }

      return Result.success(counts);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get gap count by topic: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting gap count by topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<double>> getResolutionRate(String userId) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values.where((gap) => gap.userId == userId);

      if (gaps.isEmpty) {
        return const Result.success(0.0);
      }

      final total = gaps.length;
      final resolved = gaps.where((gap) => gap.isResolved).length;
      return Result.success(resolved / total);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get resolution rate: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting resolution rate',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getMostProblematicTopics(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final box = _databaseService.knowledgeGapBox;
      final gaps = box.values.where((gap) => gap.userId == userId);

      final Map<String, int> topicCounts = {};
      for (final gap in gaps) {
        topicCounts.update(
          gap.topicId,
          (count) => count + _getSeverityWeight(gap.severity),
          ifAbsent: () => _getSeverityWeight(gap.severity),
        );
      }

      final sortedTopics = topicCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Result.success(
        sortedTopics.take(limit).map((e) => e.key).toList(),
      );
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get problematic topics: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting problematic topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Helper method to weight gaps by severity for analytics
  int _getSeverityWeight(GapSeverity severity) {
    switch (severity) {
      case GapSeverity.critical:
        return 4;
      case GapSeverity.high:
        return 3;
      case GapSeverity.medium:
        return 2;
      case GapSeverity.low:
        return 1;
    }
  }
}
