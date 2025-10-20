// import 'dart:convert';
// kept minimal: no flutter foundation imports needed after replacing describeEnum

// --- Connectivity Status ---
enum ConnectivityStatus { online, offline, checking }

extension ConnectivityStatusX on ConnectivityStatus {
  String toJson() => name;
  static ConnectivityStatus fromJson(String value) =>
      ConnectivityStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ConnectivityStatus.offline,
      );
  bool isConnected() => this == ConnectivityStatus.online;
}

// --- Connectivity Type ---
enum ConnectivityType { wifi, mobile, ethernet, bluetooth, vpn, none, unknown }

extension ConnectivityTypeX on ConnectivityType {
  String toJson() => name;
  static ConnectivityType fromJson(String value) =>
      ConnectivityType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ConnectivityType.unknown,
      );
  bool isMobile() =>
      this == ConnectivityType.mobile || this == ConnectivityType.bluetooth;
  bool isReliable() =>
      this == ConnectivityType.wifi || this == ConnectivityType.ethernet;
}

// --- Connectivity State ---
class ConnectivityState {
  final ConnectivityStatus status;
  final ConnectivityType type;
  final bool hasInternet;
  final DateTime lastChecked;
  final DateTime? lastOnline;
  final Duration? offlineDuration;
  final String? errorMessage;

  ConnectivityState({
    required this.status,
    required this.type,
    required this.hasInternet,
    required this.lastChecked,
    this.lastOnline,
    this.offlineDuration,
    this.errorMessage,
  });

  bool isOnline() => status == ConnectivityStatus.online && hasInternet;
  bool canSync() => isOnline() && type.isReliable();

  factory ConnectivityState.initial() => ConnectivityState(
    status: ConnectivityStatus.checking,
    type: ConnectivityType.unknown,
    hasInternet: false,
    lastChecked: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'status': status.toJson(),
    'type': type.toJson(),
    'hasInternet': hasInternet,
    'lastChecked': lastChecked.toIso8601String(),
    'lastOnline': lastOnline?.toIso8601String(),
    'offlineDuration': offlineDuration?.inSeconds,
    'errorMessage': errorMessage,
  };

  static ConnectivityState fromJson(Map<String, dynamic> json) =>
      ConnectivityState(
        status: ConnectivityStatusX.fromJson(json['status'] as String),
        type: ConnectivityTypeX.fromJson(json['type'] as String),
        hasInternet: json['hasInternet'] as bool,
        lastChecked: DateTime.parse(json['lastChecked'] as String),
        lastOnline: json['lastOnline'] != null
            ? DateTime.parse(json['lastOnline'])
            : null,
        offlineDuration: json['offlineDuration'] != null
            ? Duration(seconds: json['offlineDuration'])
            : null,
        errorMessage: json['errorMessage'] as String?,
      );
}

// --- Sync Operation Status ---
enum SyncOperationStatus { pending, processing, completed, failed, cancelled }

extension SyncOperationStatusX on SyncOperationStatus {
  String toJson() => name;
  static SyncOperationStatus fromJson(String value) =>
      SyncOperationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SyncOperationStatus.pending,
      );
  bool isTerminal() =>
      this == SyncOperationStatus.completed ||
      this == SyncOperationStatus.failed ||
      this == SyncOperationStatus.cancelled;
}

// --- Sync Operation ---
class SyncOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final SyncOperationStatus status;
  final String? errorMessage;
  final int priority;

  SyncOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.status = SyncOperationStatus.pending,
    this.errorMessage,
    this.priority = 3,
  });

  bool canRetry(int maxAttempts) => attemptCount < maxAttempts;
  Duration getNextRetryDelay(int baseDelay, int maxDelay) {
    final delay = baseDelay * (1 << attemptCount);
    return Duration(seconds: delay > maxDelay ? maxDelay : delay);
  }

  factory SyncOperation.create({
    required String id,
    required String type,
    required Map<String, dynamic> data,
    int priority = 3,
  }) => SyncOperation(
    id: id,
    type: type,
    data: data,
    createdAt: DateTime.now(),
    priority: priority,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'attemptCount': attemptCount,
    'status': status.toJson(),
    'errorMessage': errorMessage,
    'priority': priority,
  };

  static SyncOperation fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAttemptAt: json['lastAttemptAt'] != null
        ? DateTime.parse(json['lastAttemptAt'])
        : null,
    attemptCount: json['attemptCount'] as int? ?? 0,
    status: SyncOperationStatusX.fromJson(json['status'] as String),
    errorMessage: json['errorMessage'] as String?,
    priority: json['priority'] as int? ?? 3,
  );
}

// --- Sync Queue State ---
class SyncQueueState {
  final int pendingCount;
  final int processingCount;
  final int failedCount;
  final int completedCount;
  final DateTime? lastProcessedAt;
  final bool isProcessing;

  SyncQueueState({
    required this.pendingCount,
    required this.processingCount,
    required this.failedCount,
    required this.completedCount,
    this.lastProcessedAt,
    this.isProcessing = false,
  });

  bool hasOperations() => pendingCount > 0;
  int getTotalCount() =>
      pendingCount + processingCount + failedCount + completedCount;

  factory SyncQueueState.empty() => SyncQueueState(
    pendingCount: 0,
    processingCount: 0,
    failedCount: 0,
    completedCount: 0,
    isProcessing: false,
  );

  Map<String, dynamic> toJson() => {
    'pendingCount': pendingCount,
    'processingCount': processingCount,
    'failedCount': failedCount,
    'completedCount': completedCount,
    'lastProcessedAt': lastProcessedAt?.toIso8601String(),
    'isProcessing': isProcessing,
  };

  static SyncQueueState fromJson(Map<String, dynamic> json) => SyncQueueState(
    pendingCount: json['pendingCount'] as int? ?? 0,
    processingCount: json['processingCount'] as int? ?? 0,
    failedCount: json['failedCount'] as int? ?? 0,
    completedCount: json['completedCount'] as int? ?? 0,
    lastProcessedAt: json['lastProcessedAt'] != null
        ? DateTime.parse(json['lastProcessedAt'])
        : null,
    isProcessing: json['isProcessing'] as bool? ?? false,
  );
}
