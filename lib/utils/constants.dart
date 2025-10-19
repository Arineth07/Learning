/// Constants for database configuration and box names.
class DatabaseConstants {
  // Box names for models
  static const String userProgressBox = 'user_progress';
  static const String performanceMetricsBox = 'performance_metrics';
  static const String knowledgeGapBox = 'knowledge_gaps';
  static const String learningSessionBox = 'learning_sessions';
  static const String subjectsBox = 'subjects';
  static const String topicsBox = 'topics';
  static const String questionsBox = 'questions';
  static const String appSettingsBox = 'app_settings';

  // Database versioning
  static const int databaseVersion = 1;
  static const String versionKey = 'db_version';
}

/// Constants for storage keys used in SharedPreferences.
class StorageKeys {
  static const String currentUserId = 'current_user_id';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String offlineMode = 'offline_mode';
  static const String encryptionEnabled = 'encryption_enabled';
}

/// Constants for query limits and timeouts.
class QueryLimits {
  static const int defaultPageSize = 20;
  static const int maxBatchSize = 100;
  static const Duration operationTimeout = Duration(seconds: 5);
  static const Duration cacheExpiry = Duration(hours: 24);
}

/// Constants for content management and asset paths.
class ContentConstants {
  // Asset paths for bundled content
  static const String mathematicsAsset = 'lib/data/mathematics.json';
  static const String programmingAsset = 'lib/data/programming.json';
  
  // Content validation limits
  static const int minQuestionsPerTopic = 5;
  static const int maxQuestionsPerTopic = 20;
  static const int minTopicsPerSubject = 3;
  
  // Content cache settings
  static const Duration contentCacheExpiry = Duration(hours: 24);
  static const bool enableContentValidation = true;
}
