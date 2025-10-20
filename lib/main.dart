import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'utils/app_theme.dart';

import 'screens/question_screen.dart';
import 'screens/question_screen_arguments.dart';

import 'services/adaptive_learning_service.dart';
import 'services/database_service.dart';
import 'services/content_service.dart';
import 'services/knowledge_gap_service.dart';
import 'services/recommendation_service.dart';
import 'repositories/repositories.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/cloud_ai_cache_service.dart';
import 'services/ab_test_service.dart';
import 'services/api_client.dart';
import 'utils/constants.dart';
import 'screens/sync_debug_screen.dart';
import 'widgets/connectivity_indicator.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/sync_status_widget.dart';
import 'widgets/widgets.dart';
import 'screens/cloud_ai_debug_screen.dart';
import 'screens/dashboard_screen.dart';
// cloud AI models are exported via models/models.dart

void main() async {
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local database storage
    await Hive.initFlutter();

    // Register enum adapters
    // Enum adapters not needed - enums are serialized within model adapters
    // Hive.registerAdapter(DifficultyLevelAdapter());
    // Hive.registerAdapter(QuestionTypeAdapter());
    // Hive.registerAdapter(SubjectCategoryAdapter());
    // Hive.registerAdapter(GapSeverityAdapter());

    // Register model adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(TopicAdapter());
    Hive.registerAdapter(QuestionAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(PerformanceMetricsAdapter());
    Hive.registerAdapter(KnowledgeGapAdapter());
    Hive.registerAdapter(LearningSessionAdapter());
    // Register ABTestMetrics adapter (generated)
    try {
      Hive.registerAdapter(ABTestMetricsAdapter());
    } catch (_) {}

    // Initialize DatabaseService
    final db = DatabaseService();
    final dbInit = await db.initialize();
    dbInit.fold(
      (_) async {
        // Database initialized, now initialize ContentService
        final contentService = ContentService.instance;
        final contentInit = await contentService.initialize();
        contentInit.fold(
          (_) async {
            // All initialization successful - initialize connectivity service (non-critical)
            try {
              final connectivityService = ConnectivityService.instance;
              final connInit = await connectivityService.initialize();
              connInit.fold(
                (_) => debugPrint('Connectivity service initialized'),
                (failure) => debugPrint(
                  'Warning: Connectivity failed to initialize: ${failure.message}',
                ),
              );
              // Initialize SyncService (non-critical)
              try {
                final syncService = SyncService.instance;
                final syncInit = await syncService.initialize();
                syncInit.fold(
                  (_) => debugPrint('Sync service initialized'),
                  (failure) => debugPrint(
                    'Warning: Sync service failed to initialize: ${failure.message}',
                  ),
                );
              } catch (e) {
                debugPrint('Warning: Sync initialization threw: $e');
              }
              // Initialize Cloud AI cache and AB test services (non-critical)
              try {
                final prefs = await SharedPreferences.getInstance();
                final cacheService = CloudAICacheService.instance;
                await cacheService.initialize(prefs);
                await cacheService.cleanupExpiredCache();

                final abBox = await Hive.openBox<ABTestMetrics>(
                  CloudAIConstants.abTestMetricsBox,
                );
                final abTestService = ABTestService.instance;
                await abTestService.initialize(prefs, abBox);
              } catch (e) {
                debugPrint(
                  'Warning: Cloud AI services failed to initialize: $e',
                );
              }
            } catch (e) {
              debugPrint('Warning: Connectivity initialization threw: $e');
            }
            // Launch the app regardless of connectivity initialization result
            runApp(const AITutorApp());
          },
          (failure) async {
            debugPrint('Error loading content: ${failure.message}');
            runApp(const ErrorApp(message: 'Failed to load learning content'));
          },
        );
      },
      (failure) {
        debugPrint('Error initializing database: ${failure.message}');
        runApp(const ErrorApp(message: 'Failed to initialize database'));
      },
    );
  } catch (e) {
    // Handle initialization errors
    debugPrint('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

class AITutorApp extends StatelessWidget {
  const AITutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with MultiProvider for future service providers
    return MultiProvider(
      providers: [
        // Core services
        ChangeNotifierProvider.value(value: DatabaseService.instance),
        ChangeNotifierProvider.value(value: ContentService.instance),

        // Connectivity service (provides online/offline state and sync queue)
        ChangeNotifierProvider.value(value: ConnectivityService.instance),

        // Data repositories
        ProxyProvider<DatabaseService, UserProgressRepository>(
          update: (_, db, __) => UserProgressRepositoryImpl(db),
        ),
        ProxyProvider<DatabaseService, PerformanceMetricsRepository>(
          update: (_, db, __) => PerformanceMetricsRepositoryImpl(db),
        ),
        ProxyProvider<DatabaseService, KnowledgeGapRepository>(
          update: (_, db, __) => KnowledgeGapRepositoryImpl(db),
        ),
        ProxyProvider<DatabaseService, LearningSessionRepository>(
          update: (_, db, __) => LearningSessionRepositoryImpl(db),
        ),

        // Content repository
        ProxyProvider2<
          ContentService,
          UserProgressRepository,
          ContentRepository
        >(
          update: (_, contentService, userProgress, __) =>
              ContentRepositoryImpl(contentService, userProgress),
        ),

        // Adaptive learning service with dependencies injected via ProxyProvider
        ChangeNotifierProvider.value(value: AdaptiveLearningService.instance),
        ProxyProvider4<
          UserProgressRepository,
          LearningSessionRepository,
          PerformanceMetricsRepository,
          ContentRepository,
          AdaptiveLearningService
        >(
          update:
              (
                _,
                userProgress,
                learningSession,
                performanceMetrics,
                content,
                previous,
              ) {
                final service = previous ?? AdaptiveLearningService.instance;
                service.setRepositories(
                  userProgressRepository: userProgress,
                  learningSessionRepository: learningSession,
                  performanceMetricsRepository: performanceMetrics,
                  contentRepository: content,
                );
                return service;
              },
        ),

        // Knowledge gap service
        ChangeNotifierProvider.value(value: KnowledgeGapService.instance),
        ProxyProvider3<
          LearningSessionRepository,
          ContentRepository,
          KnowledgeGapRepository,
          KnowledgeGapService
        >(
          update: (_, learningSession, content, knowledgeGap, previous) {
            final knowledgeGapService =
                previous ?? KnowledgeGapService.instance;
            knowledgeGapService.setRepositories(
              learningSessionRepository: learningSession,
              contentRepository: content,
              knowledgeGapRepository: knowledgeGap,
            );
            return knowledgeGapService;
          },
        ),

        // Recommendation service
        ChangeNotifierProvider.value(value: RecommendationService.instance),
        ProxyProvider6<
          AdaptiveLearningService,
          KnowledgeGapService,
          ContentRepository,
          UserProgressRepository,
          LearningSessionRepository,
          ConnectivityService,
          RecommendationService
        >(
          update:
              (
                _,
                adaptiveLearning,
                knowledgeGap,
                content,
                userProgress,
                learningSession,
                connectivity,
                previous,
              ) {
                final recommendationService =
                    previous ?? RecommendationService.instance;
                // Inject cloud AI services and prefs if available
                final prefsFut = SharedPreferences.getInstance();
                prefsFut
                    .then((prefs) {
                      recommendationService.setRepositories(
                        adaptiveLearningService: adaptiveLearning,
                        knowledgeGapService: knowledgeGap,
                        contentRepository: content,
                        connectivityService: connectivity,
                        userProgressRepository: userProgress,
                        learningSessionRepository: learningSession,
                        cacheService: CloudAICacheService.instance,
                        abTestService: ABTestService.instance,
                        apiClient: ApiClient.instance,
                        prefs: prefs,
                      );
                    })
                    .catchError((_) {
                      recommendationService.setRepositories(
                        adaptiveLearningService: adaptiveLearning,
                        knowledgeGapService: knowledgeGap,
                        contentRepository: content,
                        connectivityService: connectivity,
                        userProgressRepository: userProgress,
                        learningSessionRepository: learningSession,
                        cacheService: null,
                        abTestService: null,
                        apiClient: ApiClient.instance,
                        prefs: null,
                      );
                    });
                return recommendationService;
              },
        ),

        // SyncService wiring: inject repositories and connectivity, then wire back to connectivity
        ChangeNotifierProvider.value(value: SyncService.instance),
        ProxyProvider5<
          UserProgressRepository,
          PerformanceMetricsRepository,
          KnowledgeGapRepository,
          LearningSessionRepository,
          ConnectivityService,
          SyncService
        >(
          update:
              (
                _,
                userProgress,
                performanceMetrics,
                knowledgeGap,
                learningSession,
                connectivity,
                previous,
              ) {
                final syncService = previous ?? SyncService.instance;
                syncService.setRepositories(
                  userProgressRepository: userProgress,
                  performanceMetricsRepository: performanceMetrics,
                  knowledgeGapRepository: knowledgeGap,
                  learningSessionRepository: learningSession,
                  connectivityService: connectivity,
                );
                // Wire back
                connectivity.setSyncService(syncService);
                return syncService;
              },
        ),
      ],
      child: MaterialApp(
        title: 'AI Tutor',
        debugShowCheckedModeBanner: false,

        // Use theme configurations from app_theme.dart
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,

        // Initial route
        initialRoute: '/',

        // Named routes for navigation
        routes: {
          '/': (context) => const DashboardScreen(),
          '/sync-debug': (context) => const SyncDebugScreen(),
          '/cloud-ai-debug': (context) => const CloudAIDebugScreen(),
          '/dashboard': (context) =>
              const DashboardScreen(), // Additional route for testing
        },

        // Dynamic route handling for routes with parameters
        onGenerateRoute: (settings) {
          if (settings.name == '/question') {
            final args = settings.arguments as QuestionScreenArguments?;
            if (args == null) {
              // Handle missing arguments - return error screen
              return MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const QuestionScreen(),
              settings: RouteSettings(name: '/question', arguments: args),
            );
          }
          return null;
        },

        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          );
        },
      ),
    );
  }
}

/// Error app displayed when initialization fails
class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({super.key, this.message = 'Failed to Initialize App'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 100, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Please restart the application. If the problem persists, try reinstalling.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
