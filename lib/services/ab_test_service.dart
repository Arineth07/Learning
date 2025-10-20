import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/cloud_ai_models.dart';
import '../utils/constants.dart';
import '../utils/storage_keys.dart';

class ABTestService {
  ABTestService._internal();
  static final ABTestService instance = ABTestService._internal();
  factory ABTestService() => instance;

  SharedPreferences? _prefs;
  Box<ABTestMetrics>? _metricsBox;
  bool _isInitialized = false;
  ABTestGroup? _currentGroup;
  ABTestMetrics? _currentMetrics;

  /// Expose current metrics for debugging and avoid unused-field analyzer warning.
  ABTestMetrics? getCurrentMetrics() {
    return _currentMetrics;
  }

  Future<void> initialize(
    SharedPreferences prefs,
    Box<ABTestMetrics> metricsBox,
  ) async {
    _prefs = prefs;
    _metricsBox = metricsBox;
    _isInitialized = true;
    final groupStr = _prefs?.getString(CloudAIStorageKeys.abTestGroup);
    if (groupStr != null) {
      _currentGroup = ABTestGroupExt.fromJson(groupStr);
    } else {
      _currentGroup = await _assignGroup();
    }
    // load metrics if exist
    final metrics = _metricsBox?.get(_prefs?.getString('current_user_id'));
    _currentMetrics = metrics;
  }

  void _checkInitialized() {
    if (!_isInitialized) throw StateError('ABTestService not initialized');
  }

  Future<ABTestGroup> _assignGroup() async {
    _checkInitialized();
    if (!CloudAIConstants.enableABTesting) {
      return ABTestGroupExt.fromJson(CloudAIConstants.defaultABTestGroup);
    }
    final rnd = Random();
    final r = rnd.nextDouble();
    double cumulative = 0.0;
    for (final entry in CloudAIConstants.abTestSplitRatio.entries) {
      cumulative += entry.value;
      if (r <= cumulative) {
        await setGroup(ABTestGroupExt.fromJson(entry.key));
        return ABTestGroupExt.fromJson(entry.key);
      }
    }
    await setGroup(ABTestGroup.hybrid);
    return ABTestGroup.hybrid;
  }

  ABTestGroup getCurrentGroup() {
    if (_currentGroup != null) return _currentGroup!;
    final groupStr =
        _prefs?.getString(CloudAIStorageKeys.abTestGroup) ??
        CloudAIConstants.defaultABTestGroup;
    _currentGroup = ABTestGroupExt.fromJson(groupStr);
    return _currentGroup!;
  }

  Future<void> setGroup(ABTestGroup group) async {
    _checkInitialized();
    _currentGroup = group;
    await _prefs?.setString(CloudAIStorageKeys.abTestGroup, group.toJson());
    await _prefs?.setString(
      CloudAIStorageKeys.abTestAssignedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    // create initial metrics record if not present
    final userId = _prefs?.getString('current_user_id') ?? '';
    final metrics = ABTestMetrics(
      userId: userId,
      group: group.toJson(),
      assignedAt: DateTime.now().toUtc(),
    );
    await _metricsBox?.put(userId, metrics);
    _currentMetrics = metrics;
  }

  bool shouldUseCloudAI(String method) {
    final group = getCurrentGroup();
    if (group == ABTestGroup.ruleBased) return false;
    if (group == ABTestGroup.cloudAI) return true;
    // hybrid
    return true;
  }

  bool shouldUseRuleBased(String method) {
    final group = getCurrentGroup();
    if (group == ABTestGroup.ruleBased) return true;
    if (group == ABTestGroup.cloudAI) return false;
    return true; // hybrid
  }

  Future<void> trackRecommendationUsed(
    String method,
    String source, {
    double? accuracy,
    int? durationSeconds,
  }) async {
    _checkInitialized();
    final userId = _prefs?.getString('current_user_id') ?? '';
    if (userId.isEmpty) return;
    var metrics = _metricsBox?.get(userId);
    metrics ??= ABTestMetrics(
        userId: userId,
        group: getCurrentGroup().toJson(),
        assignedAt: DateTime.now().toUtc(),
      );
    // update per-source counters in customMetrics
    try {
      final keyTotal = '${method}_used_total';
      final keySource = '${method}_used_$source';
      final currentTotal = (metrics.customMetrics[keyTotal] as int?) ?? 0;
      final currentSource = (metrics.customMetrics[keySource] as int?) ?? 0;
      metrics.customMetrics[keyTotal] = currentTotal + 1;
      metrics.customMetrics[keySource] = currentSource + 1;
    } catch (_) {
      // ignore metric update errors
    }
    if (accuracy != null) {
      final count = metrics.sessionsCompleted;
      metrics.averageAccuracy = _calculateRunningAverage(
        metrics.averageAccuracy,
        accuracy,
        count,
      );
    }
    if (durationSeconds != null) {
      final count = metrics.sessionsCompleted;
      metrics.averageSessionDuration = _calculateRunningAverage(
        metrics.averageSessionDuration,
        durationSeconds.toDouble(),
        count,
      );
    }
    await _metricsBox?.put(userId, metrics);
  }

  Future<void> trackSessionCompleted(
    String userId,
    double accuracy,
    int durationMinutes,
  ) async {
    _checkInitialized();
    var metrics = _metricsBox?.get(userId);
    metrics ??= ABTestMetrics(
        userId: userId,
        group: getCurrentGroup().toJson(),
        assignedAt: DateTime.now().toUtc(),
      );
    final prevCount = metrics.sessionsCompleted;
    metrics.sessionsCompleted = prevCount + 1;
    metrics.averageAccuracy = _calculateRunningAverage(
      metrics.averageAccuracy,
      accuracy,
      prevCount,
    );
    metrics.averageSessionDuration = _calculateRunningAverage(
      metrics.averageSessionDuration,
      durationMinutes.toDouble(),
      prevCount,
    );
    await _metricsBox?.put(userId, metrics);
  }

  Future<void> trackKnowledgeGapResolved(String userId) async {
    _checkInitialized();
    var metrics = _metricsBox?.get(userId);
    metrics ??= ABTestMetrics(
        userId: userId,
        group: getCurrentGroup().toJson(),
        assignedAt: DateTime.now().toUtc(),
      );
    metrics.knowledgeGapsResolved += 1;
    await _metricsBox?.put(userId, metrics);
  }

  Future<void> trackMasteryGain(String userId, double masteryGain) async {
    _checkInitialized();
    var metrics = _metricsBox?.get(userId);
    metrics ??= ABTestMetrics(
        userId: userId,
        group: getCurrentGroup().toJson(),
        assignedAt: DateTime.now().toUtc(),
      );
    metrics.masteryGainRate = _calculateRunningAverage(
      metrics.masteryGainRate,
      masteryGain,
      metrics.sessionsCompleted,
    );
    await _metricsBox?.put(userId, metrics);
  }

  Future<Map<ABTestGroup, ABTestMetrics>> getMetricsByGroup() async {
    _checkInitialized();
    final map = <ABTestGroup, ABTestMetrics>{};
    if (_metricsBox == null) return map;
    for (final key in _metricsBox!.keys) {
      final m = _metricsBox!.get(key);
      if (m == null) continue;
      final group = ABTestGroupExt.fromJson(m.group);
      if (!map.containsKey(group)) {
        map[group] = m;
      } else {
        // aggregate basic metrics
        final existing = map[group]!;
        existing.sessionsCompleted += m.sessionsCompleted;
        existing.averageAccuracy =
            (existing.averageAccuracy + m.averageAccuracy) / 2.0;
        existing.averageSessionDuration =
            (existing.averageSessionDuration + m.averageSessionDuration) / 2.0;
        existing.knowledgeGapsResolved += m.knowledgeGapsResolved;
        existing.masteryGainRate =
            (existing.masteryGainRate + m.masteryGainRate) / 2.0;
      }
    }
    return map;
  }

  Future<Map<String, dynamic>> getABTestReport() async {
    final byGroup = await getMetricsByGroup();
    final report = <String, dynamic>{};
    for (final entry in byGroup.entries) {
      report[entry.key.toJson()] = entry.value.toJson();
    }
    return report;
  }

  double _calculateRunningAverage(
    double currentAverage,
    double newValue,
    int count,
  ) {
    return ((currentAverage * count) + newValue) / (count + 1);
  }
}
