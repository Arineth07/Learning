class CloudAIStorageKeys {
  // Existing keys should remain in constants.dart; this file adds cloud AI specific keys
  // Cloud AI cache keys
  static const String cloudAICachePrefix = 'cloud_ai_cache_';
  static const String cloudAICacheMetadata = 'cloud_ai_cache_metadata';
  static const String cloudAILastCleanup = 'cloud_ai_last_cleanup';

  // A/B testing keys
  static const String abTestGroup = 'ab_test_group';
  static const String abTestAssignedAt = 'ab_test_assigned_at';
  static const String abTestMetricsLastSync = 'ab_test_metrics_last_sync';

  // Cloud AI feature keys
  static const String cloudAIEnabled = 'cloud_ai_enabled';
  static const String cloudAIConsentGiven = 'cloud_ai_consent_given';
  static const String cloudAIUsageCount = 'cloud_ai_usage_count';
}
