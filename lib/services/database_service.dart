import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Core service for managing all Hive database operations.
/// This is a singleton service that manages box lifecycle and provides
/// centralized error handling.
class DatabaseService extends ChangeNotifier {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;

  // Box references for each model type
  Box<UserProgress>? _userProgressBox;
  Box<PerformanceMetrics>? _performanceMetricsBox;
  Box<KnowledgeGap>? _knowledgeGapBox;
  Box<LearningSession>? _learningSessionBox;
  Box? _settingsBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Getters for box access with null checks
  Box<UserProgress> get userProgressBox =>
      _userProgressBox ??
      (throw StateError('UserProgress box not initialized'));

  Box<PerformanceMetrics> get performanceMetricsBox =>
      _performanceMetricsBox ??
      (throw StateError('PerformanceMetrics box not initialized'));

  Box<KnowledgeGap> get knowledgeGapBox =>
      _knowledgeGapBox ??
      (throw StateError('KnowledgeGap box not initialized'));

  Box<LearningSession> get learningSessionBox =>
      _learningSessionBox ??
      (throw StateError('LearningSession box not initialized'));

  Box get settingsBox =>
      _settingsBox ?? (throw StateError('Settings box not initialized'));

  /// Opens a box with corruption recovery attempt
  Future<Box<T>> _openBoxWithRecovery<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } on HiveError {
      debugPrint('Attempting to recover corrupted box: $name');
      await Hive.deleteBoxFromDisk(name);
      try {
        return await Hive.openBox<T>(name);
      } catch (e, st) {
        throw CorruptionFailure(
          'Failed to recover $name box after corruption',
          cause: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Initializes all Hive boxes and runs necessary migrations.
  Future<Result<void>> initialize() async {
    if (_isInitialized) {
      return const Result.success(null);
    }

    try {
      // Open boxes sequentially with recovery attempts
      _userProgressBox = await _openBoxWithRecovery<UserProgress>(
        DatabaseConstants.userProgressBox,
      );
      _performanceMetricsBox = await _openBoxWithRecovery<PerformanceMetrics>(
        DatabaseConstants.performanceMetricsBox,
      );
      _knowledgeGapBox = await _openBoxWithRecovery<KnowledgeGap>(
        DatabaseConstants.knowledgeGapBox,
      );
      _learningSessionBox = await _openBoxWithRecovery<LearningSession>(
        DatabaseConstants.learningSessionBox,
      );
      _settingsBox = await _openBoxWithRecovery(
        DatabaseConstants.appSettingsBox,
      );

      try {
        final box = settingsBox;
        final currentVersion =
            box.get(DatabaseConstants.versionKey, defaultValue: 0) as int;
        if (currentVersion < DatabaseConstants.databaseVersion) {
          await _runMigrations(
            currentVersion,
            DatabaseConstants.databaseVersion,
          );
          await box.put(
            DatabaseConstants.versionKey,
            DatabaseConstants.databaseVersion,
          );
        }
      } catch (e, st) {
        return Result.error(
          DatabaseFailure(
            'Failed to check/update database version',
            cause: e,
            stackTrace: st,
          ),
        );
      }

      _isInitialized = true;
      notifyListeners();
      return const Result.success(null);
    } on CorruptionFailure catch (e) {
      return Result.error(e);
    } on HiveError catch (e, st) {
      return Result.error(
        DatabaseFailure(
          'Failed to initialize database: ${e.message}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error during database initialization',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Runs database migrations between versions.
  Future<void> _runMigrations(int fromVersion, int toVersion) async {
    // No migrations needed for version 1
    if (fromVersion == 0 && toVersion == 1) {
      debugPrint('First time initialization, no migrations needed');
      return;
    }
    // Add future migrations here
  }

  /// Clears all data for a specific user.
  Future<Result<void>> clearUserData(String userId) async {
    try {
      await Future.wait([
        _clearUserProgress(userId),
        _clearPerformanceMetrics(userId),
        _clearKnowledgeGaps(userId),
        _clearLearningSessions(userId),
      ]);
      notifyListeners();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        DatabaseFailure('Failed to clear user data', cause: e, stackTrace: st),
      );
    }
  }

  Future<void> _clearUserProgress(String userId) async {
    final box = _userProgressBox;
    if (box == null) return;
    final keys = box.values
        .where((item) => item.userId == userId)
        .map((item) => item.id)
        .toList();
    await box.deleteAll(keys);
  }

  Future<void> _clearPerformanceMetrics(String userId) async {
    final box = _performanceMetricsBox;
    if (box == null) return;
    final keys = box.values
        .where((item) => item.userId == userId)
        .map((item) => item.id)
        .toList();
    await box.deleteAll(keys);
  }

  Future<void> _clearKnowledgeGaps(String userId) async {
    final box = _knowledgeGapBox;
    if (box == null) return;
    final keys = box.values
        .where((item) => item.userId == userId)
        .map((item) => item.id)
        .toList();
    await box.deleteAll(keys);
  }

  Future<void> _clearLearningSessions(String userId) async {
    final box = _learningSessionBox;
    if (box == null) return;
    final keys = box.values
        .where((item) => item.userId == userId)
        .map((item) => item.id)
        .toList();
    await box.deleteAll(keys);
  }

  /// Compacts all boxes to reclaim disk space.
  Future<Result<void>> compactAllBoxes() async {
    try {
      await Future.wait([
        _userProgressBox?.compact() ?? Future.value(),
        _performanceMetricsBox?.compact() ?? Future.value(),
        _knowledgeGapBox?.compact() ?? Future.value(),
        _learningSessionBox?.compact() ?? Future.value(),
        _settingsBox?.compact() ?? Future.value(),
      ]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        DatabaseFailure('Failed to compact boxes', cause: e, stackTrace: st),
      );
    }
  }

  @override
  void dispose() {
    // Use unawaited for box closures since ChangeNotifier.dispose is synchronous
    _userProgressBox?.close();
    _performanceMetricsBox?.close();
    _knowledgeGapBox?.close();
    _learningSessionBox?.close();
    _settingsBox?.close();

    _userProgressBox = null;
    _performanceMetricsBox = null;
    _knowledgeGapBox = null;
    _learningSessionBox = null;
    _settingsBox = null;

    _isInitialized = false;
    super.dispose();
  }
}

/// Mixin for models that have a userId field.
mixin HasUserId {
  String get userId;
}
