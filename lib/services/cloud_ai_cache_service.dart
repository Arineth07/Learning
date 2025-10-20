import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cloud_ai_models.dart';
import '../utils/constants.dart';
import '../utils/storage_keys.dart';

class CloudAICacheService {
  CloudAICacheService._internal();
  static final CloudAICacheService instance = CloudAICacheService._internal();
  factory CloudAICacheService() => instance;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  final Map<String, CachedCloudAIResponse> _memoryCache = {};
  int _cacheHits = 0;
  int _cacheMisses = 0;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;
    await _loadCacheMetadata();
  }

  void setPreferences(SharedPreferences prefs) {
    _prefs = prefs;
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized)
      throw StateError('CloudAICacheService not initialized');
  }

  String generateCacheKey(
    String method,
    String userId,
    String subjectId, {
    Map<String, dynamic>? params,
  }) {
    final buffer = StringBuffer();
    buffer.write(method);
    buffer.write('|');
    buffer.write(userId);
    buffer.write('|');
    buffer.write(subjectId);
    if (params != null && params.isNotEmpty) {
      final json = jsonEncode(params);
      buffer.write('|');
      buffer.write(json);
    }
    final digest = sha1.convert(utf8.encode(buffer.toString())).toString();
    return '${CloudAIConstants.cacheKeyPrefix}${method}_$digest';
  }

  Future<CachedCloudAIResponse?> get(String cacheKey) async {
    _checkInitialized();
    if (_memoryCache.containsKey(cacheKey)) {
      final val = _memoryCache[cacheKey]!;
      if (!val.isExpired()) {
        val.hitCount += 1;
        _cacheHits += 1;
        return val;
      } else {
        await invalidate(cacheKey);
        _cacheMisses += 1;
        return null;
      }
    }
    final raw = _prefs?.getString(cacheKey);
    if (raw == null) {
      _cacheMisses += 1;
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cached = CachedCloudAIResponse.fromJson(map);
      if (cached.isExpired()) {
        await invalidate(cacheKey);
        _cacheMisses += 1;
        return null;
      }
      _memoryCache[cacheKey] = cached;
      _cacheHits += 1;
      return cached;
    } catch (_) {
      await invalidate(cacheKey);
      _cacheMisses += 1;
      return null;
    }
  }

  Future<void> put(
    String cacheKey,
    Map<String, dynamic> responseData, {
    Duration? ttl,
  }) async {
    _checkInitialized();
    final now = DateTime.now().toUtc();
    final expires = now.add(ttl ?? CloudAIConstants.cacheDuration);
    final entry = CachedCloudAIResponse(
      cacheKey: cacheKey,
      responseData: responseData,
      cachedAt: now,
      expiresAt: expires,
      hitCount: 0,
    );
    _memoryCache[cacheKey] = entry;
    try {
      await _prefs?.setString(cacheKey, jsonEncode(entry.toJson()));
      await _saveCacheMetadata();
      await enforceMaxCacheSize();
    } catch (_) {}
  }

  Future<void> invalidate(String cacheKey) async {
    _memoryCache.remove(cacheKey);
    try {
      await _prefs?.remove(cacheKey);
      await _saveCacheMetadata();
    } catch (_) {}
  }

  Future<void> invalidateAll() async {
    _memoryCache.clear();
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (k.startsWith(CloudAIConstants.cacheKeyPrefix))
        await _prefs?.remove(k);
    }
    await _saveCacheMetadata();
  }

  Future<void> invalidateByPattern(String pattern) async {
    _memoryCache.removeWhere((k, v) => k.contains(pattern));
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (k.startsWith(CloudAIConstants.cacheKeyPrefix) &&
          k.contains(pattern)) {
        await _prefs?.remove(k);
      }
    }
    await _saveCacheMetadata();
  }

  Future<void> cleanupExpiredCache() async {
    _checkInitialized();
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final k in keys) {
      if (!k.startsWith(CloudAIConstants.cacheKeyPrefix)) continue;
      final raw = _prefs?.getString(k);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final cached = CachedCloudAIResponse.fromJson(map);
        if (cached.isExpired()) await _prefs?.remove(k);
      } catch (_) {
        await _prefs?.remove(k);
      }
    }
    await _saveCacheMetadata();
  }

  Future<void> enforceMaxCacheSize() async {
    _checkInitialized();
    final keys =
        _prefs
            ?.getKeys()
            .where((k) => k.startsWith(CloudAIConstants.cacheKeyPrefix))
            .toList() ??
        [];
    if (keys.length <= CloudAIConstants.maxCacheSize) return;
    // Load entries with cachedAt / hitCount to sort
    final entries = <CachedCloudAIResponse>[];
    for (final k in keys) {
      final raw = _prefs?.getString(k);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        entries.add(CachedCloudAIResponse.fromJson(map));
      } catch (_) {}
    }
    entries.sort((a, b) {
      final aScore = a.hitCount + a.cachedAt.millisecondsSinceEpoch / 1000000.0;
      final bScore = b.hitCount + b.cachedAt.millisecondsSinceEpoch / 1000000.0;
      return aScore.compareTo(bScore);
    });
    while (entries.length > CloudAIConstants.maxCacheSize) {
      final remove = entries.removeAt(0);
      await invalidate(remove.cacheKey);
    }
    await _saveCacheMetadata();
  }

  Map<String, dynamic> getCacheStats() {
    final keys =
        _prefs
            ?.getKeys()
            .where((k) => k.startsWith(CloudAIConstants.cacheKeyPrefix))
            .toList() ??
        [];
    final storageSize = keys.length;
    final hitRate = (_cacheHits + _cacheMisses) > 0
        ? (_cacheHits / (_cacheHits + _cacheMisses))
        : 0.0;
    return {
      'totalEntries': storageSize,
      'memoryCacheSize': _memoryCache.length,
      'storageCacheSize': storageSize,
      'hitRate': hitRate,
      'totalHits': _cacheHits,
      'totalMisses': _cacheMisses,
      'lastCleanup': _prefs?.getString(CloudAIStorageKeys.cloudAILastCleanup),
    };
  }

  Future<void> _saveCacheMetadata() async {
    await _prefs?.setString(
      CloudAIStorageKeys.cloudAICacheMetadata,
      jsonEncode({
        'totalHits': _cacheHits,
        'totalMisses': _cacheMisses,
        'totalEntries':
            _prefs
                ?.getKeys()
                .where((k) => k.startsWith(CloudAIConstants.cacheKeyPrefix))
                .length ??
            0,
        'lastCleanup': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await _prefs?.setString(
      CloudAIStorageKeys.cloudAILastCleanup,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _loadCacheMetadata() async {
    final raw = _prefs?.getString(CloudAIStorageKeys.cloudAICacheMetadata);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cacheHits = (map['totalHits'] as num?)?.toInt() ?? 0;
      _cacheMisses = (map['totalMisses'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }
}
