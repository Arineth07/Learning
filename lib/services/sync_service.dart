import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sync_models.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/constants.dart';
import '../utils/result.dart';
import '../utils/failures.dart';
import 'api_client.dart';
import 'connectivity_service.dart';

class SyncService extends ChangeNotifier {
  SyncService._internal();

  static final SyncService instance = SyncService._internal();
  factory SyncService() => instance;

  UserProgressRepository? _userProgressRepository;
  PerformanceMetricsRepository? _performanceMetricsRepository;
  KnowledgeGapRepository? _knowledgeGapRepository;
  LearningSessionRepository? _learningSessionRepository;
  ConnectivityService? _connectivityService;
  SharedPreferences? _prefs;

  final ApiClient _apiClient = ApiClient.instance;

  bool _isInitialized = false;
  bool _isSyncing = false;
  SyncStatus _syncStatus = SyncStatus.initial();
  final List<SyncConflict> _recentConflicts = [];
  Timer? _autoSyncTimer;

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  SyncStatus get syncStatus => _syncStatus;
  List<SyncConflict> get recentConflicts => List.unmodifiable(_recentConflicts);

  void setRepositories({
    UserProgressRepository? userProgressRepository,
    PerformanceMetricsRepository? performanceMetricsRepository,
    KnowledgeGapRepository? knowledgeGapRepository,
    LearningSessionRepository? learningSessionRepository,
    ConnectivityService? connectivityService,
  }) {
    _userProgressRepository = userProgressRepository;
    _performanceMetricsRepository = performanceMetricsRepository;
    _knowledgeGapRepository = knowledgeGapRepository;
    _learningSessionRepository = learningSessionRepository;
    _connectivityService = connectivityService;
    notifyListeners();
  }

  Future<Result<void>> initialize() async {
    if (_isInitialized) return const Result.success(null);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSyncStatus();
      // If an explicit current user is stored in prefs, use it for sync operations
      try {
        final storedUser = _prefs?.getString(StorageKeys.currentUserId);
        if (storedUser != null && storedUser.isNotEmpty) {
          // preserve existing timestamps and maps when switching user id
          _syncStatus = SyncStatus(
            userId: storedUser,
            lastSyncedAt: _syncStatus.lastSyncedAt,
            lastSyncByType: _syncStatus.lastSyncByType,
            pendingOperations: _syncStatus.pendingOperations,
            failedOperations: _syncStatus.failedOperations,
            isSyncing: _syncStatus.isSyncing,
            lastError: _syncStatus.lastError,
          );
        }
      } catch (_) {}
      if (SyncConstants.enableAutoSync) _startAutoSync();
      _isInitialized = true;
      notifyListeners();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to initialize SyncService: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Update the current user id used by the SyncService and persist it.
  Future<Result<void>> setCurrentUser(String userId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(StorageKeys.currentUserId, userId);
      _syncStatus = SyncStatus(
        userId: userId,
        lastSyncedAt: _syncStatus.lastSyncedAt,
        lastSyncByType: _syncStatus.lastSyncByType,
        pendingOperations: _syncStatus.pendingOperations,
        failedOperations: _syncStatus.failedOperations,
        isSyncing: _syncStatus.isSyncing,
        lastError: _syncStatus.lastError,
      );
      _saveSyncStatus();
      notifyListeners();
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to set current user: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Result<SyncResponse>> syncOperation(SyncOperation operation) async {
    if (_connectivityService == null || !_connectivityService!.isOnline) {
      return const Result.error(ConnectivityFailure('Offline'));
    }
    try {
      switch (operation.type) {
        case 'progress':
          return await _syncProgress(operation.data);
        case 'metrics':
          return await _syncMetrics(operation.data);
        case 'gaps':
          return await _syncGaps(operation.data);
        case 'session':
          return await _syncSession(operation.data);
        default:
          return Result.error(
            ValidationFailure('Unknown sync type: ${operation.type}'),
          );
      }
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Sync operation failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<void>> syncAll(String userId) async {
    if (_connectivityService == null || !_connectivityService!.isOnline) {
      return const Result.error(ConnectivityFailure('Cannot sync while offline'));
    }
    _isSyncing = true;
    _syncStatus = SyncStatus(userId: userId, isSyncing: true);
    notifyListeners();
    try {
      // Progress
      final progressRes =
          await _userProgressRepository?.getByUserId(userId) ??
          const Result.success(<UserProgress>[]);
      final progressList = progressRes.fold<List<UserProgress>?>(
        (list) => list,
        (failure) {
          _isSyncing = false;
          _updateSyncStatus('progress', success: false, error: failure.message);
          notifyListeners();
          return null;
        },
      );
      if (progressList == null) return Result.error(progressRes.failureOrNull!);
      if (progressList.isNotEmpty) await syncProgressBatch(progressList);

      // Metrics
      final metricsRes =
          await _performanceMetricsRepository?.getByUserId(userId) ??
          const Result.success(<PerformanceMetrics>[]);
      final metricsList = metricsRes.fold<List<PerformanceMetrics>?>(
        (list) => list,
        (failure) {
          _isSyncing = false;
          _updateSyncStatus('metrics', success: false, error: failure.message);
          notifyListeners();
          return null;
        },
      );
      if (metricsList == null) return Result.error(metricsRes.failureOrNull!);
      if (metricsList.isNotEmpty) await syncMetricsBatch(metricsList);

      // Gaps
      final gapsRes =
          await _knowledgeGapRepository?.getByUserId(userId) ??
          const Result.success(<KnowledgeGap>[]);
      final gapsList = gapsRes.fold<List<KnowledgeGap>?>((list) => list, (
        failure,
      ) {
        _isSyncing = false;
        _updateSyncStatus('gaps', success: false, error: failure.message);
        notifyListeners();
        return null;
      });
      if (gapsList == null) return Result.error(gapsRes.failureOrNull!);
      if (gapsList.isNotEmpty) await syncGapsBatch(gapsList);

      // Sessions
      final sessionsRes =
          await _learningSessionRepository?.getByUserId(userId) ??
          const Result.success(<LearningSession>[]);
      final sessionsList = sessionsRes.fold<List<LearningSession>?>(
        (list) => list,
        (failure) {
          _isSyncing = false;
          _updateSyncStatus('sessions', success: false, error: failure.message);
          notifyListeners();
          return null;
        },
      );
      if (sessionsList == null) return Result.error(sessionsRes.failureOrNull!);
      if (sessionsList.isNotEmpty) await syncSessionsBatch(sessionsList);

      _updateSyncStatus('all', success: true);
      _isSyncing = false;
      notifyListeners();
      return const Result.success(null);
    } catch (e, st) {
      _isSyncing = false;
      _updateSyncStatus('all', success: false, error: e.toString());
      notifyListeners();
      return Result.error(
        UnknownFailure('Failed to sync all: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<SyncResponse>> _syncProgress(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post(
        SyncConstants.syncProgressEndpoint,
        data,
      );
      return resp.fold(
        (map) {
          final sr = SyncResponse.fromJson(map);
          if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
          _updateSyncStatus('progress', success: sr.success);
          return Result.success(sr);
        },
        (failure) async {
          if (failure is ConflictFailure) {
            return await _handleConflictForType('progress', data, failure);
          }
          return Result.error(failure);
        },
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Progress sync failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<SyncResponse>> _syncMetrics(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post(
        SyncConstants.syncMetricsEndpoint,
        data,
      );
      return resp.fold(
        (map) {
          final sr = SyncResponse.fromJson(map);
          if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
          _updateSyncStatus('metrics', success: sr.success);
          return Result.success(sr);
        },
        (failure) async {
          if (failure is ConflictFailure) {
            return await _handleConflictForType('metrics', data, failure);
          }
          return Result.error(failure);
        },
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Metrics sync failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<SyncResponse>> _syncGaps(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post(SyncConstants.syncGapsEndpoint, data);
      return resp.fold(
        (map) {
          final sr = SyncResponse.fromJson(map);
          if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
          _updateSyncStatus('gaps', success: sr.success);
          return Result.success(sr);
        },
        (failure) async {
          if (failure is ConflictFailure) {
            return await _handleConflictForType('gaps', data, failure);
          }
          return Result.error(failure);
        },
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Gaps sync failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  Future<Result<SyncResponse>> _syncSession(Map<String, dynamic> data) async {
    try {
      final resp = await _apiClient.post(
        SyncConstants.syncSessionsEndpoint,
        data,
      );
      return resp.fold(
        (map) {
          final sr = SyncResponse.fromJson(map);
          if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
          _updateSyncStatus('sessions', success: sr.success);
          return Result.success(sr);
        },
        (failure) async {
          if (failure is ConflictFailure) {
            return await _handleConflictForType('sessions', data, failure);
          }
          return Result.error(failure);
        },
      );
    } catch (e, st) {
      return Result.error(
        UnknownFailure('Session sync failed: $e', cause: e, stackTrace: st),
      );
    }
  }

  /// Resolve a conflict for a single entity type. This will attempt to fetch the
  /// server copy (via GET) when needed, detect the conflict, resolve using
  /// the configured strategy and then either update local storage (server wins)
  /// or re-upload the resolved local copy (local wins). Resolved conflicts are
  /// appended to [_recentConflicts] and will not be re-tried.
  Future<Result<SyncResponse>> _handleConflictForType(
    String type,
    Map<String, dynamic> localData,
    Failure failure,
  ) async {
    try {
      final id = (localData['id'] ?? localData['entityId'])?.toString();
      if (id == null || id.isEmpty) {
        return const Result.error(
          ValidationFailure('Conflict but no id available in local data'),
        );
      }

      final endpoint = _getEndpointForType(type);
      if (endpoint == null) {
        return Result.error(
          ValidationFailure('Unknown type for conflict resolution: $type'),
        );
      }

      // Try to fetch server version of the entity
      final getRes = await _apiClient.get('$endpoint/$id');
      if (getRes is Error) {
        // If we cannot fetch server data, bubble up conflict so queue may retry
        return Result.error(failure);
      }

      final serverMap = (getRes as Success<Map<String, dynamic>>).data;

      // Build conflict object and resolve using configured strategy
      final conflict = _detectConflict(localData, serverMap, type, id);
      final resolved = _resolveConflict(conflict);

      // Apply resolution
      final resolvedJson = Map<String, dynamic>.from(resolved);
      bool appliedToServer = false;
      bool appliedLocally = false;

      const encoder = JsonCodec();
      final sameAsServer =
          encoder.encode(resolvedJson) == encoder.encode(serverMap);

      if (sameAsServer) {
        // Server wins: update local repository with server copy
        switch (type) {
          case 'progress':
            if (_userProgressRepository != null) {
              final model = UserProgress.fromJson(serverMap);
              final r = await _userProgressRepository!.update(model);
              if (r is Success) appliedLocally = true;
            }
            break;
          case 'metrics':
            if (_performanceMetricsRepository != null) {
              final model = PerformanceMetrics.fromJson(serverMap);
              final r = await _performanceMetricsRepository!.createOrUpdate(
                model,
              );
              if (r is Success) appliedLocally = true;
            }
            break;
          case 'gaps':
            if (_knowledgeGapRepository != null) {
              final model = KnowledgeGap.fromJson(serverMap);
              final r = await _knowledgeGapRepository!.update(model);
              if (r is Success) appliedLocally = true;
            }
            break;
          case 'sessions':
            if (_learningSessionRepository != null) {
              final model = LearningSession.fromJson(serverMap);
              final r = await _learningSessionRepository!.update(model);
              if (r is Success) appliedLocally = true;
            }
            break;
        }
      } else {
        // Local wins: attempt to PUT the resolved local copy to server
        final putRes = await _apiClient.put('$endpoint/$id', resolvedJson);
        if (putRes is Success) appliedToServer = true;
      }

      // Record the conflict and mark as resolved if applied
      _recentConflicts.add(conflict);
      _updateSyncStatus(type, success: (appliedLocally || appliedToServer));

      final sr = SyncResponse(
        success: true,
        message: 'Conflict detected and resolved',
        data: {
          'resolvedOnServer': appliedToServer,
          'updatedLocally': appliedLocally,
        },
        conflicts: [conflict],
        itemsSynced: (appliedToServer || appliedLocally) ? 1 : 0,
        itemsFailed: (appliedToServer || appliedLocally) ? 0 : 1,
      );

      return Result.success(sr);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Conflict resolution failed: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  String? _getEndpointForType(String type) {
    switch (type) {
      case 'progress':
        return SyncConstants.syncProgressEndpoint;
      case 'metrics':
        return SyncConstants.syncMetricsEndpoint;
      case 'gaps':
        return SyncConstants.syncGapsEndpoint;
      case 'sessions':
        return SyncConstants.syncSessionsEndpoint;
      default:
        return null;
    }
  }

  Future<Result<SyncResponse>> syncProgressBatch(
    List<UserProgress> list,
  ) async {
    final items = list.map((e) => e.toJson()).toList();
    final resp = await _apiClient.postBatch(
      SyncConstants.syncProgressEndpoint,
      items,
    );
    return resp.fold((map) {
      final sr = SyncResponse.fromJson(map);
      if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
      _updateSyncStatus('progress', success: sr.success);
      return Result.success(sr);
    }, (failure) => Result.error(failure));
  }

  Future<Result<SyncResponse>> syncMetricsBatch(
    List<PerformanceMetrics> list,
  ) async {
    final items = list.map((e) => e.toJson()).toList();
    final resp = await _apiClient.postBatch(
      SyncConstants.syncMetricsEndpoint,
      items,
    );
    return resp.fold((map) {
      final sr = SyncResponse.fromJson(map);
      if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
      _updateSyncStatus('metrics', success: sr.success);
      return Result.success(sr);
    }, (failure) => Result.error(failure));
  }

  Future<Result<SyncResponse>> syncGapsBatch(List<KnowledgeGap> list) async {
    final items = list.map((e) => e.toJson()).toList();
    final resp = await _apiClient.postBatch(
      SyncConstants.syncGapsEndpoint,
      items,
    );
    return resp.fold((map) {
      final sr = SyncResponse.fromJson(map);
      if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
      _updateSyncStatus('gaps', success: sr.success);
      return Result.success(sr);
    }, (failure) => Result.error(failure));
  }

  Future<Result<SyncResponse>> syncSessionsBatch(
    List<LearningSession> list,
  ) async {
    final items = list.map((e) => e.toJson()).toList();
    final resp = await _apiClient.postBatch(
      SyncConstants.syncSessionsEndpoint,
      items,
    );
    return resp.fold((map) {
      final sr = SyncResponse.fromJson(map);
      if (sr.hasConflicts()) _recentConflicts.addAll(sr.conflicts);
      _updateSyncStatus('sessions', success: sr.success);
      return Result.success(sr);
    }, (failure) => Result.error(failure));
  }

  // ignore: unused_element
  SyncConflict _detectConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    String type,
    String id,
  ) {
    final localTs =
        DateTime.tryParse(
          local[SyncConstants.timestampField]?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final serverTs =
        DateTime.tryParse(
          server[SyncConstants.timestampField]?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return SyncConflict(
      entityType: type,
      entityId: id,
      localData: local,
      serverData: server,
      localUpdatedAt: localTs,
      serverUpdatedAt: serverTs,
      resolutionStrategy: SyncConstants.conflictResolutionStrategy,
    );
  }

  // ignore: unused_element
  Map<String, dynamic> _resolveConflict(SyncConflict conflict) {
    if (SyncConstants.conflictResolutionStrategy == 'last-write-wins') {
      if (conflict.shouldUseLocal()) return conflict.localData;
      return conflict.serverData;
    }
    // Default to server
    return conflict.serverData;
  }

  void _updateSyncStatus(String type, {bool success = true, String? error}) {
    final now = DateTime.now();
    final map = Map<String, DateTime>.from(_syncStatus.lastSyncByType);
    if (success) map[type] = now;
    _syncStatus = SyncStatus(
      userId: _syncStatus.userId,
      lastSyncedAt: success ? now : _syncStatus.lastSyncedAt,
      lastSyncByType: map,
      pendingOperations: _syncStatus.pendingOperations,
      failedOperations: success ? 0 : (_syncStatus.failedOperations + 1),
      isSyncing: false,
      lastError: error,
    );
    _saveSyncStatus();
    notifyListeners();
  }

  Future<void> _saveSyncStatus() async {
    if (_prefs == null) return;
    try {
      // Persist full SyncStatus JSON under a dedicated key to avoid
      // collisions with a simple timestamp key used elsewhere.
      await _prefs!.setString(
        StorageKeys.syncStatus,
        jsonEncode(_syncStatus.toJson()),
      );
      // For backward compatibility also store the ISO8601 last sync timestamp
      if (_syncStatus.lastSyncedAt != null) {
        await _prefs!.setString(
          StorageKeys.lastSyncTimestamp,
          _syncStatus.lastSyncedAt!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Failed to save sync status: $e');
    }
  }

  Future<void> _loadSyncStatus() async {
    if (_prefs == null) return;
    try {
      // Prefer the full JSON entry if available
      final jsonStr = _prefs!.getString(StorageKeys.syncStatus);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _syncStatus = SyncStatus.fromJson(map);
        return;
      }
      // Fallback: older format stored only the timestamp under lastSyncTimestamp
      final ts = _prefs!.getString(StorageKeys.lastSyncTimestamp);
      if (ts != null && ts.isNotEmpty) {
        final parsed = DateTime.tryParse(ts);
        if (parsed != null) {
          _syncStatus = SyncStatus(
            userId: _syncStatus.userId,
            lastSyncedAt: parsed,
            lastSyncByType: _syncStatus.lastSyncByType,
            pendingOperations: _syncStatus.pendingOperations,
            failedOperations: _syncStatus.failedOperations,
            isSyncing: _syncStatus.isSyncing,
            lastError: _syncStatus.lastError,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load sync status: $e');
      _syncStatus = SyncStatus.initial();
    }
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: SyncConstants.autoSyncIntervalMinutes),
      (_) async {
        if (_connectivityService != null &&
            _connectivityService!.isOnline &&
            !_isSyncing) {
          await syncAll(_syncStatus.userId);
        }
      },
    );
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  Future<Result<SyncStatus>> getSyncStatus(String userId) async {
    // Optionally merge with server status if available
    return Result.success(_syncStatus);
  }

  Future<Result<void>> forceSyncNow(String userId) async {
    return syncAll(userId);
  }

  @override
  void dispose() {
    _stopAutoSync();
    _saveSyncStatus();
    super.dispose();
  }
}
