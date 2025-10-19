import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Repository interface for LearningSession operations
abstract interface class LearningSessionRepository {
  // Core operations
  Future<Result<LearningSession>> create(LearningSession session);
  Future<Result<LearningSession>> startSession(
    String userId,
    List<String> topicIds,
  );
  Future<Result<LearningSession>> getById(String id);
  Future<Result<LearningSession?>> getActiveSession(String userId);
  Future<Result<List<LearningSession>>> getByUserId(
    String userId, {
    int? limit,
  });
  Future<Result<List<LearningSession>>> getCompletedSessions(
    String userId, {
    int? limit,
  });
  Future<Result<List<LearningSession>>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Result<List<LearningSession>>> getSessionsByTopic(
    String userId,
    String topicId,
  );
  Stream<LearningSession?> watchActiveSession(String userId);

  // Update operations
  Future<Result<LearningSession>> update(LearningSession session);
  Future<Result<LearningSession>> addQuestionResult(
    String sessionId,
    String questionId,
    bool isCorrect,
    int timeSeconds,
  );
  Future<Result<LearningSession>> endSession(String id);

  // Delete operations
  Future<Result<void>> delete(String id);
  Future<Result<void>> deleteByUserId(String userId);
  Future<Result<void>> deleteOldSessions(String userId, {Duration? olderThan});

  // Analytics
  Future<Result<int>> getTotalSessionCount(String userId);
  Future<Result<int>> getTotalStudyTimeMinutes(String userId);
  Future<Result<Duration>> getAverageSessionDuration(String userId);
  Future<Result<double>> getAverageAccuracy(String userId);
  Future<Result<List<String>>> getTopSessions(String userId, {int limit = 5});
  Future<Result<Map<String, Duration>>> getStudyTimeByTopic(String userId);
  Future<Result<int>> getStudyStreak(String userId);
}

/// Concrete implementation of LearningSessionRepository using Hive
class LearningSessionRepositoryImpl implements LearningSessionRepository {
  final DatabaseService _databaseService;

  const LearningSessionRepositoryImpl(this._databaseService);

  @override
  Future<Result<LearningSession>> create(LearningSession session) async {
    try {
      final box = _databaseService.learningSessionBox;
      if (box.containsKey(session.id)) {
        return Result.error(
          AlreadyExistsFailure(
            'LearningSession with ID ${session.id} already exists',
          ),
        );
      }

      await box.put(session.id, session).timeout(QueryLimits.operationTimeout);
      return Result.success(session);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to create LearningSession: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error creating LearningSession',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<LearningSession>> startSession(
    String userId,
    List<String> topicIds,
  ) async {
    try {
      final box = _databaseService.learningSessionBox;

      // Check for existing active session
      final matches = box.values
          .where((s) => s.userId == userId && !s.isCompleted)
          .toList();
      final activeSession = matches.isNotEmpty ? matches.first : null;

      if (activeSession != null) {
        return Result.error(
          ValidationFailure('User already has an active session'),
        );
      }

      final now = DateTime.now();
      final session = LearningSession(
        id: now.millisecondsSinceEpoch.toString(),
        userId: userId,
        topicIds: topicIds,
        questionIds: const [],
        questionResults: const {},
        responseTimesSeconds: const {},
        startTime: now,
        totalTimeSpentMinutes: 0,
        accuracyRate: 0.0,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await box.put(session.id, session).timeout(QueryLimits.operationTimeout);
      return Result.success(session);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to start learning session: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error starting learning session',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<LearningSession>> getById(String id) async {
    try {
      final box = _databaseService.learningSessionBox;
      final session = box.get(id);
      if (session == null) {
        return Result.error(
          NotFoundFailure('LearningSession with ID $id not found'),
        );
      }
      return Result.success(session);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get LearningSession: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting LearningSession',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<LearningSession?>> getActiveSession(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final matches = box.values
          .where((s) => s.userId == userId && !s.isCompleted)
          .toList();
      final session = matches.isNotEmpty ? matches.first : null;
      return Result.success(session);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get active session: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting active session',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<LearningSession>>> getByUserId(
    String userId, {
    int? limit,
  }) async {
    try {
      final box = _databaseService.learningSessionBox;
      var sessions = box.values.where((s) => s.userId == userId).toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      if (limit != null && limit > 0) {
        sessions = sessions.take(limit).toList();
      }

      return Result.success(sessions);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get LearningSession list: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting LearningSession list',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<LearningSession>>> getCompletedSessions(
    String userId, {
    int? limit,
  }) async {
    try {
      final box = _databaseService.learningSessionBox;
      var sessions =
          box.values.where((s) => s.userId == userId && s.isCompleted).toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

      if (limit != null && limit > 0) {
        sessions = sessions.take(limit).toList();
      }

      return Result.success(sessions);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get completed sessions: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting completed sessions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<LearningSession>>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values
          .where(
            (s) =>
                s.userId == userId &&
                s.startTime.isAfter(startDate) &&
                s.startTime.isBefore(endDate),
          )
          .toList();
      return Result.success(sessions);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get sessions by date range: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting sessions by date range',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<LearningSession>>> getSessionsByTopic(
    String userId,
    String topicId,
  ) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values
          .where((s) => s.userId == userId && s.topicIds.contains(topicId))
          .toList();
      return Result.success(sessions);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get sessions by topic: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting sessions by topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<LearningSession?> watchActiveSession(String userId) {
    final box = _databaseService.learningSessionBox;
    return box
        .watch()
        .map((_) {
          final matches = box.values
              .where((s) => s.userId == userId && !s.isCompleted)
              .toList();
          return matches.isNotEmpty ? matches.first : null;
        })
        .handleError((error) {
          debugPrint('Error watching active session: $error');
          return null;
        });
  }

  @override
  Future<Result<LearningSession>> update(LearningSession session) async {
    try {
      final box = _databaseService.learningSessionBox;
      if (!box.containsKey(session.id)) {
        return Result.error(
          NotFoundFailure('LearningSession with ID ${session.id} not found'),
        );
      }

      final updated = LearningSession(
        id: session.id,
        userId: session.userId,
        topicIds: session.topicIds,
        questionIds: session.questionIds,
        questionResults: session.questionResults,
        responseTimesSeconds: session.responseTimesSeconds,
        startTime: session.startTime,
        endTime: session.endTime,
        totalTimeSpentMinutes: session.totalTimeSpentMinutes,
        accuracyRate: session.accuracyRate,
        isCompleted: session.isCompleted,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
      );

      await box.put(session.id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to update LearningSession: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error updating LearningSession',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<LearningSession>> addQuestionResult(
    String sessionId,
    String questionId,
    bool isCorrect,
    int timeSeconds,
  ) async {
    try {
      final box = _databaseService.learningSessionBox;
      final session = box.get(sessionId);
      if (session == null) {
        return Result.error(
          NotFoundFailure('LearningSession with ID $sessionId not found'),
        );
      }

      if (session.isCompleted) {
        return Result.error(
          ValidationFailure('Cannot add results to a completed session'),
        );
      }

      // Update session state
      final questionIds = [...session.questionIds, questionId];
      final questionResults = Map<String, bool>.from(session.questionResults)
        ..[questionId] = isCorrect;
      final responseTimesSeconds = Map<String, int>.from(
        session.responseTimesSeconds,
      )..[questionId] = timeSeconds;

      // Calculate new metrics
      final totalTimeSpentMinutes =
          (responseTimesSeconds.values.fold<int>(0, (sum, v) => sum + v) / 60)
              .round();
      final accuracyRate =
          questionResults.values.fold<double>(
            0.0,
            (sum, v) => sum + (v ? 1 : 0),
          ) /
          questionResults.length;

      final updated = LearningSession(
        id: session.id,
        userId: session.userId,
        topicIds: session.topicIds,
        questionIds: questionIds,
        questionResults: questionResults,
        responseTimesSeconds: responseTimesSeconds,
        startTime: session.startTime,
        endTime: session.endTime,
        totalTimeSpentMinutes: totalTimeSpentMinutes,
        accuracyRate: accuracyRate,
        isCompleted: session.isCompleted,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
      );

      await box.put(sessionId, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to add question result: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error adding question result',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<LearningSession>> endSession(String id) async {
    try {
      final box = _databaseService.learningSessionBox;
      final session = box.get(id);
      if (session == null) {
        return Result.error(
          NotFoundFailure('LearningSession with ID $id not found'),
        );
      }

      if (session.isCompleted) {
        return Result.error(ValidationFailure('Session is already completed'));
      }

      final updated = LearningSession(
        id: session.id,
        userId: session.userId,
        topicIds: session.topicIds,
        questionIds: session.questionIds,
        questionResults: session.questionResults,
        responseTimesSeconds: session.responseTimesSeconds,
        startTime: session.startTime,
        endTime: DateTime.now(),
        totalTimeSpentMinutes: session.totalTimeSpentMinutes,
        accuracyRate: session.accuracyRate,
        isCompleted: true,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
      );

      await box.put(id, updated).timeout(QueryLimits.operationTimeout);
      return Result.success(updated);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to end session: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error ending session',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final box = _databaseService.learningSessionBox;
      await box.delete(id).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete LearningSession: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting LearningSession',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteByUserId(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final keys = box.values
          .where((s) => s.userId == userId)
          .map((s) => s.id)
          .toList();
      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete LearningSession by user: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting LearningSession by user',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteOldSessions(
    String userId, {
    Duration? olderThan,
  }) async {
    try {
      final box = _databaseService.learningSessionBox;
      final cutoff = DateTime.now().subtract(
        olderThan ?? const Duration(days: 30),
      );

      final keys = box.values
          .where(
            (s) =>
                s.userId == userId &&
                s.isCompleted &&
                s.startTime.isBefore(cutoff),
          )
          .map((s) => s.id)
          .toList();

      await box.deleteAll(keys).timeout(QueryLimits.operationTimeout);
      return const Result.success(null);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to delete old sessions: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error deleting old sessions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getTotalSessionCount(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final count = box.values
          .where((s) => s.userId == userId && s.isCompleted)
          .length;
      return Result.success(count);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get total session count: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting total session count',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getTotalStudyTimeMinutes(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final totalMinutes = box.values
          .where((s) => s.userId == userId && s.isCompleted)
          .fold<int>(0, (sum, s) => sum + s.totalTimeSpentMinutes);
      return Result.success(totalMinutes);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get total study time: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting total study time',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Duration>> getAverageSessionDuration(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values.where(
        (s) => s.userId == userId && s.isCompleted,
      );

      if (sessions.isEmpty) {
        return Result.success(Duration.zero);
      }

      final totalMinutes = sessions.fold<int>(
        0,
        (sum, s) => sum + s.totalTimeSpentMinutes,
      );
      return Result.success(Duration(minutes: totalMinutes ~/ sessions.length));
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get average session duration: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting average session duration',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<double>> getAverageAccuracy(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values.where(
        (s) => s.userId == userId && s.isCompleted,
      );

      if (sessions.isEmpty) {
        return const Result.success(0.0);
      }

      final totalAccuracy = sessions.fold<double>(
        0.0,
        (sum, s) => sum + s.accuracyRate,
      );
      return Result.success(totalAccuracy / sessions.length);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get average accuracy: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting average accuracy',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getTopSessions(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions =
          box.values.where((s) => s.userId == userId && s.isCompleted).toList()
            ..sort((a, b) => b.accuracyRate.compareTo(a.accuracyRate));

      return Result.success(sessions.take(limit).map((s) => s.id).toList());
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get top sessions: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting top sessions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, Duration>>> getStudyTimeByTopic(
    String userId,
  ) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values.where(
        (s) => s.userId == userId && s.isCompleted,
      );

      final Map<String, int> minutesByTopic = {};
      for (final session in sessions) {
        final minutesPerTopic =
            session.totalTimeSpentMinutes ~/ session.topicIds.length;
        for (final topicId in session.topicIds) {
          minutesByTopic.update(
            topicId,
            (minutes) => minutes + minutesPerTopic,
            ifAbsent: () => minutesPerTopic,
          );
        }
      }

      return Result.success({
        for (var entry in minutesByTopic.entries)
          entry.key: Duration(minutes: entry.value),
      });
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get study time by topic: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting study time by topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getStudyStreak(String userId) async {
    try {
      final box = _databaseService.learningSessionBox;
      final sessions = box.values
          .where((s) => s.userId == userId && s.isCompleted)
          .toList();

      if (sessions.isEmpty) {
        return const Result.success(0);
      }

      // Get unique study dates sorted in descending order
      final studyDates =
          sessions
              .map(
                (s) => DateTime(
                  s.startTime.year,
                  s.startTime.month,
                  s.startTime.day,
                ),
              )
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      // Find current streak
      var streak = 1;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      // If no study today, check if studied yesterday to continue streak
      if (studyDates.first != today) {
        final yesterday = today.subtract(const Duration(days: 1));
        if (studyDates.first != yesterday) {
          return const Result.success(0);
        }
      }

      // Count consecutive days
      for (var i = 0; i < studyDates.length - 1; i++) {
        final difference = studyDates[i].difference(studyDates[i + 1]).inDays;
        if (difference == 1) {
          streak++;
        } else {
          break;
        }
      }

      return Result.success(streak);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to get study streak: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error getting study streak',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
