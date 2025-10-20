import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/connectivity_models.dart';
import '../utils/constants.dart';
import '../utils/result.dart';
import '../utils/failures.dart';
import 'sync_service.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityState _currentState = ConnectivityState.initial();
  List<SyncOperation> _syncQueue = [];
  SyncQueueState _queueState = SyncQueueState.empty();
  DateTime? _lastProcessedAt;
  Timer? _periodicCheckTimer;
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  SyncService? _syncService;
  final _connectivityController =
      StreamController<ConnectivityState>.broadcast();

  bool get isInitialized => _isInitialized;
  ConnectivityState get currentState => _currentState;
  bool get isOnline => _currentState.isOnline();
  bool get isOffline => !isOnline;
  ConnectivityType get connectionType => _currentState.type;
  SyncQueueState get queueState => _queueState;
  Stream<ConnectivityState> get connectivityStream =>
      _connectivityController.stream;

  void setSyncService(SyncService syncService) {
    _syncService = syncService;
    notifyListeners();
  }

  Future<Result<void>> initialize() async {
    if (_isInitialized) return Result.success(null);
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadQueueFromStorage();
      final results = await _connectivity.checkConnectivity();
      final type = _mapConnectivityResult(results);
      final hasInternet = await _checkInternetReachability();
      _currentState = ConnectivityState(
        status: hasInternet
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline,
        type: type,
        hasInternet: hasInternet,
        lastChecked: DateTime.now(),
        lastOnline: hasInternet ? DateTime.now() : null,
        offlineDuration: hasInternet ? null : Duration.zero,
      );
      _connectivityController.add(_currentState);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (result) => _onConnectivityChanged([result]),
      );
      if (ConnectivityConstants.enablePeriodicChecks) {
        _startPeriodicChecks();
      }
      _isInitialized = true;
      notifyListeners();
      return Result.success(null);
    } catch (e, st) {
      return Result.error(
        ConnectivityFailure(
          'Failed to initialize connectivity service',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final type = _mapConnectivityResult(results);
    final prevOnline = isOnline;
    final hasInternet = await _checkInternetReachability();
    final status = hasInternet
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
    final now = DateTime.now();
    _currentState = ConnectivityState(
      status: status,
      type: type,
      hasInternet: hasInternet,
      lastChecked: now,
      lastOnline: hasInternet ? now : _currentState.lastOnline,
      offlineDuration: hasInternet
          ? null
          : (now.difference(_currentState.lastOnline ?? now)),
    );
    _connectivityController.add(_currentState);
    if (!prevOnline &&
        hasInternet &&
        ConnectivityConstants.autoProcessOnConnect) {
      await _processQueueOnReconnect();
    }
    notifyListeners();
  }

  ConnectivityType _mapConnectivityResult(dynamic results) {
    if (results is List<ConnectivityResult>) {
      final primary = results.firstWhere(
        (r) => r != ConnectivityResult.none,
        orElse: () => ConnectivityResult.none,
      );
      return _mapSingleResult(primary);
    } else if (results is ConnectivityResult) {
      return _mapSingleResult(results);
    }
    return ConnectivityType.unknown;
  }

  ConnectivityType _mapSingleResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectivityType.wifi;
      case ConnectivityResult.mobile:
        return ConnectivityType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectivityType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectivityType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectivityType.vpn;
      case ConnectivityResult.none:
        return ConnectivityType.none;
      default:
        return ConnectivityType.unknown;
    }
  }

  Future<bool> _checkInternetReachability() async {
    try {
      final response = await http
          .get(Uri.parse(ConnectivityConstants.reachabilityCheckUrl))
          .timeout(Duration(seconds: ConnectivityConstants.timeoutSeconds));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void _startPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      Duration(seconds: ConnectivityConstants.checkIntervalSeconds),
      (_) async {
        // Run reachability checks when device has a network interface (not strictly "online")
        if (_currentState.type != ConnectivityType.none) {
          final prevOnline = _currentState.hasInternet;
          final hasInternet = await _checkInternetReachability();
          if (hasInternet != _currentState.hasInternet) {
            _currentState = ConnectivityState(
              status: hasInternet
                  ? ConnectivityStatus.online
                  : ConnectivityStatus.offline,
              type: _currentState.type,
              hasInternet: hasInternet,
              lastChecked: DateTime.now(),
              lastOnline: hasInternet
                  ? DateTime.now()
                  : _currentState.lastOnline,
              offlineDuration: hasInternet
                  ? null
                  : (DateTime.now().difference(
                      _currentState.lastOnline ?? DateTime.now(),
                    )),
            );
            _connectivityController.add(_currentState);
            // If we just regained internet, process queue if configured
            if (!prevOnline &&
                hasInternet &&
                ConnectivityConstants.autoProcessOnConnect) {
              await _processQueueOnReconnect();
            }
            notifyListeners();
          }
        }
      },
    );
  }

  Future<Result<void>> addToSyncQueue(
    String type,
    Map<String, dynamic> data, {
    int priority = 3,
  }) async {
    if (_syncQueue.length >= ConnectivityConstants.maxQueueSize) {
      return Result.error(ValidationFailure('Sync queue is full'));
    }
    final op = SyncOperation.create(
      id: const Uuid().v4(),
      type: type,
      data: data,
      priority: priority,
    );
    _syncQueue.add(op);
    _updateQueueState();
    await _saveQueueToStorage();
    if (isOnline) {
      await _processQueueOnReconnect();
    }
    notifyListeners();
    return Result.success(null);
  }

  Future<void> _processQueueOnReconnect() async {
    final pending = _syncQueue
        .where((op) => op.status == SyncOperationStatus.pending)
        .toList();
    // Sort by priority (descending) then by createdAt (ascending) so that
    // higher priority items are processed first, and within the same
    // priority older (earlier created) operations are processed before newer ones.
    pending.sort((a, b) {
      final pCmp = b.priority.compareTo(a.priority); // higher priority first
      if (pCmp != 0) return pCmp;
      // FIFO for same priority
      return a.createdAt.compareTo(b.createdAt);
    });
    // Process fresh pending operations first (attemptCount == 0) so retries
    // with backoff don't starve the queue. Schedule retries with increasing
    // delay based on attempt count.
    final fresh = pending.where((op) => op.attemptCount == 0).toList();
    final retryCandidates = pending.where((op) => op.attemptCount > 0).toList();

    // Process fresh ops immediately (respecting priority ordering)
    for (final op in fresh) {
      await _processSyncOperation(op);
    }

    // Schedule retries with exponential backoff so they don't block fresh ops
    for (final op in retryCandidates) {
      // compute exponential backoff delay: base * 2^(attemptCount - 1)
      final base = ConnectivityConstants.retryDelaySeconds;
      final exponent = (op.attemptCount - 1).clamp(0, 30);
      final computed = base * (1 << exponent);
      final delaySeconds = computed > ConnectivityConstants.maxRetryDelaySeconds
          ? ConnectivityConstants.maxRetryDelaySeconds
          : computed;

      // Schedule processing after delay; do not await so other scheduled
      // retries can run concurrently after their delays.
      Future.delayed(Duration(seconds: delaySeconds), () async {
        // Before retrying, ensure the op is still pending and we are online
        final currentOp = _syncQueue.firstWhere(
          (o) => o.id == op.id,
          orElse: () => op,
        );
        if (currentOp.status == SyncOperationStatus.pending && isOnline) {
          await _processSyncOperation(currentOp);
        }
      });
    }
    _updateQueueState();
    await _saveQueueToStorage();
    notifyListeners();
  }

  Future<void> _processSyncOperation(SyncOperation op) async {
    final processingOp = SyncOperation(
      id: op.id,
      type: op.type,
      data: op.data,
      createdAt: op.createdAt,
      lastAttemptAt: DateTime.now(),
      attemptCount: op.attemptCount + 1,
      status: SyncOperationStatus.processing,
      errorMessage: null,
      priority: op.priority,
    );

    final index = _syncQueue.indexWhere((o) => o.id == op.id);
    if (index != -1) {
      _syncQueue[index] = processingOp;
    }

    if (_syncService != null && _syncService!.isInitialized) {
      final result = await _syncService!.syncOperation(processingOp);
      result.fold(
        (syncResponse) {
          // Success: remove from queue
          _syncQueue.removeWhere((o) => o.id == op.id);
          _lastProcessedAt = DateTime.now();
        },
        (failure) {
          final failedOp = SyncOperation(
            id: op.id,
            type: op.type,
            data: op.data,
            createdAt: op.createdAt,
            lastAttemptAt: DateTime.now(),
            attemptCount: processingOp.attemptCount,
            status: op.canRetry(ConnectivityConstants.maxRetryAttempts)
                ? SyncOperationStatus.pending
                : SyncOperationStatus.failed,
            errorMessage: failure.message,
            priority: op.priority,
          );

          final idx = _syncQueue.indexWhere((o) => o.id == op.id);
          if (idx != -1) {
            _syncQueue[idx] = failedOp;
          }
        },
      );
    } else {
      // SyncService is not available. Keep the operation pending for retry later.
      debugPrint(
        'SyncService not available, leaving operation pending for retry',
      );
      final idx = _syncQueue.indexWhere((o) => o.id == op.id);
      if (idx != -1) {
        final pendingOp = SyncOperation(
          id: op.id,
          type: op.type,
          data: op.data,
          createdAt: op.createdAt,
          lastAttemptAt: DateTime.now(),
          attemptCount: op.attemptCount, // preserve attempt count
          status: SyncOperationStatus.pending,
          errorMessage: 'SyncService unavailable',
          priority: op.priority,
        );
        _syncQueue[idx] = pendingOp;
      }
    }

    _updateQueueState();
    await _saveQueueToStorage();
  }

  Future<void> _saveQueueToStorage() async {
    if (!ConnectivityConstants.persistQueueToStorage || _prefs == null) return;
    final jsonList = _syncQueue.map((op) => op.toJson()).toList();
    await _prefs!.setString(
      ConnectivityConstants.queueStorageKey,
      jsonEncode(jsonList),
    );
  }

  Future<void> _loadQueueFromStorage() async {
    if (!ConnectivityConstants.persistQueueToStorage || _prefs == null) return;
    final jsonStr = _prefs!.getString(ConnectivityConstants.queueStorageKey);
    if (jsonStr == null) return;
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    _syncQueue = jsonList
        .map((j) => SyncOperation.fromJson(j as Map<String, dynamic>))
        .where((op) => !op.status.isTerminal())
        .toList();
    _updateQueueState();
  }

  Future<Result<void>> clearQueue() async {
    _syncQueue.clear();
    _queueState = SyncQueueState.empty();
    if (_prefs != null) {
      await _prefs!.remove(ConnectivityConstants.queueStorageKey);
    }
    notifyListeners();
    return Result.success(null);
  }

  Future<Result<void>> retryFailedOperations() async {
    final failed = _syncQueue
        .where(
          (op) =>
              op.status == SyncOperationStatus.failed &&
              op.canRetry(ConnectivityConstants.maxRetryAttempts),
        )
        .toList();
    for (var op in failed) {
      // convert to pending and schedule retry with backoff
      final pendingOp = SyncOperation(
        id: op.id,
        type: op.type,
        data: op.data,
        createdAt: op.createdAt,
        lastAttemptAt: DateTime.now(),
        attemptCount: op.attemptCount,
        status: SyncOperationStatus.pending,
        errorMessage: null,
        priority: op.priority,
      );
      final idx = _syncQueue.indexWhere((o) => o.id == op.id);
      if (idx != -1) _syncQueue[idx] = pendingOp;

      // compute delay using exponential backoff
      final base = ConnectivityConstants.retryDelaySeconds;
      final exponent = (op.attemptCount - 1).clamp(0, 30);
      final computed = base * (1 << exponent);
      final delaySeconds = computed > ConnectivityConstants.maxRetryDelaySeconds
          ? ConnectivityConstants.maxRetryDelaySeconds
          : computed;

      Future.delayed(Duration(seconds: delaySeconds), () async {
        final currentOp = _syncQueue.firstWhere(
          (o) => o.id == op.id,
          orElse: () => pendingOp,
        );
        if (currentOp.status == SyncOperationStatus.pending && isOnline) {
          await _processSyncOperation(currentOp);
        }
      });
    }
    _updateQueueState();
    await _saveQueueToStorage();
    notifyListeners();
    return Result.success(null);
  }

  bool isFeatureAvailable(String feature) {
    if (isOnline) return true;
    return ConnectivityConstants.offlineFeatures.contains(feature);
  }

  Result<void> requiresOnline(String feature) {
    if (isOnline) return Result.success(null);
    return Result.error(
      ConnectivityFailure('$feature requires internet connection'),
    );
  }

  @override
  void dispose() {
    // Cancel subscriptions/timers (fire-and-forget)
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();

    // Persist queue without awaiting to avoid changing signature
    unawaited(_saveQueueToStorage());

    _connectivityController.close();
    super.dispose();
  }

  void _updateQueueState() {
    final pending = _syncQueue
        .where((op) => op.status == SyncOperationStatus.pending)
        .length;
    final processing = _syncQueue
        .where((op) => op.status == SyncOperationStatus.processing)
        .length;
    final failed = _syncQueue
        .where((op) => op.status == SyncOperationStatus.failed)
        .length;
    final completed = _syncQueue
        .where((op) => op.status == SyncOperationStatus.completed)
        .length;
    _queueState = SyncQueueState(
      pendingCount: pending,
      processingCount: processing,
      failedCount: failed,
      completedCount: completed,
      lastProcessedAt: _lastProcessedAt,
      isProcessing: processing > 0,
    );
  }
}
