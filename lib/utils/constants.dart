// --- Connectivity Service Configuration ---
class ConnectivityConstants {
  // Connectivity Monitoring
  static const int checkIntervalSeconds = 30;
  static const int timeoutSeconds = 10;
  static const String reachabilityCheckUrl = 'https://www.google.com';
  static const bool enablePeriodicChecks = true;
  static const bool cacheConnectivityState = true;

  // Sync Queue
  static const int maxQueueSize = 100;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 5;
  static const int maxRetryDelaySeconds = 60;
  static const bool persistQueueToStorage = true;
  static const bool autoProcessOnConnect = true;
  static const String queueStorageKey = 'sync_queue';

  // UI Indicator
  static const bool showBannerOnOffline = true;
  static const bool bannerDismissible = true;
  static const int bannerAutoDismissSeconds = 5;
  static const bool showSnackBarOnReconnect = true;
  static const String indicatorPosition = 'appBar';

  // Feature Availability
  static const List<String> offlineFeatures = [
    'practice',
    'review',
    'progress',
  ];
  static const List<String> onlineOnlyFeatures = [
    'cloud_ai',
    'sync',
    'leaderboard',
  ];
}

/// Recommendation engine configuration constants
class RecommendationConstants {
  // Scoring Weights
  static const double urgencyWeight = 0.35;
  static const double readinessWeight = 0.30;
  static const double impactWeight = 0.20;
  static const double engagementWeight = 0.15;

  // Topic Recommendation Thresholds
  static const double minimumMasteryForAdvancement = 0.7;
  static const double prerequisiteCompletionThreshold = 0.8;
  static const int maxRecommendedTopics = 5;
  static const int minSessionsBeforeRecommendation = 2;

  // Practice Set Configuration
  static const int defaultPracticeSetSize = 10;
  static const int minPracticeSetSize = 5;
  static const int maxPracticeSetSize = 20;
  static const double gapQuestionRatio = 0.6;
  static const double reviewQuestionRatio = 0.3;
  static const double newQuestionRatio = 0.1;

  // Learning Path Configuration
  static const int maxLearningPathLength = 10;
  static const int pathRecalculationIntervalDays = 7;
  static const bool allowSkipPrerequisites = false;
  static const double balancedPathGapRatio = 0.4;
  static const double balancedPathReviewRatio = 0.3;
  static const double balancedPathNewRatio = 0.3;

  // Question Selection Filters
  static const int avoidRecentlyAnsweredDays = 1;
  static const double prioritizeFailedQuestionsWeight = 2.0;
  static const double diversityFactor = 0.3;

  // Recommendation Refresh
  static const Duration recommendationCacheDuration = Duration(minutes: 30);
  static const bool forceRefreshOnNewSession = true;
}

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

/// Constants for adaptive learning algorithms and thresholds.
class AdaptiveLearningConstants {
  // Difficulty adaptation thresholds
  static const int consecutiveCorrectToIncrease = 3;
  static const int consecutiveIncorrectToDecrease = 2;
  static const double minimumAccuracyForIncrease = 0.75;

  // Spaced repetition intervals (in days)
  static const int spacedRepetitionInterval1 = 1; // First review
  static const int spacedRepetitionInterval2 = 3; // Second review
  static const int spacedRepetitionInterval3 = 7; // Third review
  static const int spacedRepetitionInterval4 = 14; // Fourth review
  static const int spacedRepetitionInterval5 = 30; // Fifth review

  // Mastery thresholds for spaced repetition
  static const double masteryLevelLow = 0.5; // Needs frequent review
  static const double masteryLevelMedium = 0.7; // Moderate review
  static const double masteryLevelHigh = 0.85; // Infrequent review

  // Learning pace thresholds
  static const double paceSlowThreshold = 1.5; // 1.5x expected time = slow
  static const double paceFastThreshold = 0.7; // 0.7x expected time = fast

  // Performance trend analysis
  static const int trendAnalysisSessionCount = 5; // Last N sessions to analyze
  static const double improvementThreshold = 0.1; // 10% improvement
  static const double declineThreshold = 0.1; // 10% decline

  // Session analysis limits
  static const int recentSessionsLimit =
      10; // Recent sessions for streak calculation
  static const int minSessionsForTrend = 3; // Minimum sessions needed for trend
}

/// Constants for knowledge gap detection and management.
class KnowledgeGapConstants {
  // Consistency threshold for weakness indicator
  static const double consistencyThreshold = 0.7;
  // Composite gap detection threshold
  static const double gapDetectionThreshold =
      0.3; // Default threshold for composite score
  // Gap Detection Thresholds
  static const double accuracyThresholdCritical =
      0.4; // Below 40% accuracy indicates critical gap
  static const double accuracyThresholdHigh =
      0.5; // Below 50% accuracy indicates high severity gap
  static const double accuracyThresholdMedium =
      0.6; // Below 60% accuracy indicates medium severity gap
  static const double accuracyThresholdLow =
      0.7; // Below 70% accuracy indicates low severity gap
  static const double paceThresholdSlow =
      1.5; // Taking 1.5x expected time indicates struggling
  static const double paceThresholdVerySlow =
      2.0; // Taking 2x expected time indicates severe struggling
  static const int minimumAttemptsForDetection =
      5; // Need at least 5 attempts to reliably detect gaps
  static const int recentSessionsForAnalysis =
      3; // Analyze last 3 sessions for gap detection

  // Severity Scoring Weights
  static const double accuracyWeight =
      0.4; // 40% weight for accuracy in severity calculation
  static const double paceWeight = 0.3; // 30% weight for learning pace
  static const double consistencyWeight =
      0.2; // 20% weight for performance consistency
  static const double recencyWeight = 0.1; // 10% weight for recent performance

  // Gap Resolution Criteria
  static const double resolutionAccuracyThreshold =
      0.8; // Need 80% accuracy to resolve gap
  static const int resolutionMinimumAttempts =
      5; // Need at least 5 correct attempts to confirm resolution
  static const int resolutionConsecutiveCorrect =
      3; // Need 3 consecutive correct answers

  // Targeted Practice Configuration
  static const int recommendedQuestionsPerGap =
      10; // Recommend 10 questions per identified gap
  static const int maxRecommendedQuestions =
      15; // Maximum questions to recommend at once
  static const bool includePrerequisites =
      true; // Include prerequisite topics in recommendations
  static const bool prioritizeFailedQuestions =
      true; // Prioritize previously failed questions

  // Gap Re-analysis Intervals
  static const int reanalysisIntervalDays = 7; // Re-analyze gaps every 7 days
  static const int autoResolveCheckDays =
      3; // Check for auto-resolution every 3 days
}
