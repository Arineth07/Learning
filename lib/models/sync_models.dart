import 'dart:convert';

/// Sync status information tracked locally
class SyncStatus {
  final String userId;
  final DateTime? lastSyncedAt;
  final Map<String, DateTime> lastSyncByType;
  final int pendingOperations;
  final int failedOperations;
  final bool isSyncing;
  final String? lastError;

  SyncStatus({
    required this.userId,
    this.lastSyncedAt,
    Map<String, DateTime>? lastSyncByType,
    this.pendingOperations = 0,
    this.failedOperations = 0,
    this.isSyncing = false,
    this.lastError,
  }) : lastSyncByType = lastSyncByType ?? {};

  factory SyncStatus.initial([String userId = 'demo_user']) => SyncStatus(
    userId: userId,
    lastSyncedAt: null,
    lastSyncByType: {},
    pendingOperations: 0,
    failedOperations: 0,
    isSyncing: false,
    lastError: null,
  );

  bool isFullySynced() => pendingOperations == 0 && failedOperations == 0;

  Duration? getTimeSinceLastSync() {
    if (lastSyncedAt == null) return null;
    return DateTime.now().difference(lastSyncedAt!);
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'lastSyncByType': lastSyncByType.map(
      (k, v) => MapEntry(k, v.toIso8601String()),
    ),
    'pendingOperations': pendingOperations,
    'failedOperations': failedOperations,
    'isSyncing': isSyncing,
    'lastError': lastError,
  };

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    final map = <String, DateTime>{};
    if (json['lastSyncByType'] is Map) {
      (json['lastSyncByType'] as Map).forEach((k, v) {
        try {
          map[k as String] = DateTime.parse(v as String);
        } catch (_) {}
      });
    }
    return SyncStatus(
      userId: json['userId'] as String? ?? 'demo_user',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      lastSyncByType: map,
      pendingOperations: json['pendingOperations'] as int? ?? 0,
      failedOperations: json['failedOperations'] as int? ?? 0,
      isSyncing: json['isSyncing'] as bool? ?? false,
      lastError: json['lastError'] as String?,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Represents a conflict between local and server data
class SyncConflict {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localUpdatedAt;
  final DateTime serverUpdatedAt;
  final String resolutionStrategy;
  final DateTime detectedAt;

  SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.serverData,
    required this.localUpdatedAt,
    required this.serverUpdatedAt,
    required this.resolutionStrategy,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  bool shouldUseLocal() => localUpdatedAt.isAfter(serverUpdatedAt);
  bool shouldUseServer() => serverUpdatedAt.isAfter(localUpdatedAt);
  Duration getTimeDifference() =>
      localUpdatedAt.difference(serverUpdatedAt).abs();

  Map<String, dynamic> toJson() => {
    'entityType': entityType,
    'entityId': entityId,
    'localData': localData,
    'serverData': serverData,
    'localUpdatedAt': localUpdatedAt.toIso8601String(),
    'serverUpdatedAt': serverUpdatedAt.toIso8601String(),
    'resolutionStrategy': resolutionStrategy,
    'detectedAt': detectedAt.toIso8601String(),
  };

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    entityType: json['entityType'] as String,
    entityId: json['entityId'] as String,
    localData: Map<String, dynamic>.from(json['localData'] as Map? ?? {}),
    serverData: Map<String, dynamic>.from(json['serverData'] as Map? ?? {}),
    localUpdatedAt:
        DateTime.tryParse(json['localUpdatedAt'] as String? ?? '') ??
        DateTime.now(),
    serverUpdatedAt:
        DateTime.tryParse(json['serverUpdatedAt'] as String? ?? '') ??
        DateTime.now(),
    resolutionStrategy: json['resolutionStrategy'] as String? ?? 'unknown',
    detectedAt: DateTime.tryParse(json['detectedAt'] as String? ?? ''),
  );
}

/// Response wrapper for sync operations
class SyncResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final List<SyncConflict> conflicts;
  final int itemsSynced;
  final int itemsFailed;
  final DateTime timestamp;

  SyncResponse({
    required this.success,
    this.message,
    this.data,
    List<SyncConflict>? conflicts,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
    DateTime? timestamp,
  }) : conflicts = conflicts ?? [],
       timestamp = timestamp ?? DateTime.now();

  bool hasConflicts() => conflicts.isNotEmpty;
  bool isPartialSuccess() => itemsSynced > 0 && itemsFailed > 0;

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'conflicts': conflicts.map((c) => c.toJson()).toList(),
    'itemsSynced': itemsSynced,
    'itemsFailed': itemsFailed,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SyncResponse.fromJson(Map<String, dynamic> json) => SyncResponse(
    success: json['success'] as bool? ?? false,
    message: json['message'] as String?,
    data: json['data'] != null
        ? Map<String, dynamic>.from(json['data'] as Map)
        : null,
    conflicts: json['conflicts'] is List
        ? (json['conflicts'] as List)
              .map(
                (e) =>
                    SyncConflict.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
        : [],
    itemsSynced: json['itemsSynced'] as int? ?? 0,
    itemsFailed: json['itemsFailed'] as int? ?? 0,
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

/// Batch representation for syncing multiple items
class SyncBatch {
  final String batchId;
  final String type;
  final List<Map<String, dynamic>> items;
  final int itemCount;
  final DateTime createdAt;

  SyncBatch({
    required this.batchId,
    required this.type,
    required this.items,
    DateTime? createdAt,
  }) : itemCount = items.length,
       createdAt = createdAt ?? DateTime.now();

  bool isEmpty() => items.isEmpty;

  Map<String, dynamic> toJson() => {
    'batchId': batchId,
    'type': type,
    'items': items,
    'itemCount': itemCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SyncBatch.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final items = rawItems != null
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return SyncBatch(
      batchId: json['batchId'] as String,
      type: json['type'] as String,
      items: items,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  factory SyncBatch.fromModels(
    String batchId,
    String type,
    List<dynamic> models,
  ) {
    final items = models.map((m) {
      if (m is Map<String, dynamic>) return m;
      try {
        return (m as dynamic).toJson() as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).toList();
    return SyncBatch(batchId: batchId, type: type, items: items);
  }
}
