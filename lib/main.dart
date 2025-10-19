import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'utils/app_theme.dart';

import 'screens/question_screen.dart';
import 'screens/question_screen_arguments.dart';

import 'services/database_service.dart';
import 'services/content_service.dart';
import 'repositories/repositories.dart';

void main() async {
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local database storage
    await Hive.initFlutter();

    // Register enum adapters
    Hive.registerAdapter(DifficultyLevelAdapter());
    Hive.registerAdapter(QuestionTypeAdapter());
    Hive.registerAdapter(SubjectCategoryAdapter());
    Hive.registerAdapter(GapSeverityAdapter());

    // Register model adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(TopicAdapter());
    Hive.registerAdapter(QuestionAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(PerformanceMetricsAdapter());
    Hive.registerAdapter(KnowledgeGapAdapter());
    Hive.registerAdapter(LearningSessionAdapter());

    // Initialize DatabaseService
    final db = DatabaseService();
    final dbInit = await db.initialize();
    dbInit.fold(
      (_) async {
        // Database initialized, now initialize ContentService
        final contentService = ContentService.instance;
        final contentInit = await contentService.initialize();
        contentInit.fold(
          (_) {
            // All initialization successful
            runApp(const AITutorApp());
          },
          (failure) {
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
        routes: {'/': (context) => const PlaceholderHomeScreen()},

        // Dynamic route handling for routes with parameters
        onGenerateRoute: (settings) {
          if (settings.name == '/question') {
            final args = settings.arguments as QuestionScreenArguments?;
            if (args == null) {
              // Handle missing arguments - return error screen
              return MaterialPageRoute(
                builder: (context) => const PlaceholderHomeScreen(),
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
            builder: (context) => const PlaceholderHomeScreen(),
          );
        },
      ),
    );
  }
}

/// Placeholder home screen displayed during development
/// This will be replaced by DashboardScreen in subsequent phases
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'AI Tutor App',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Under Development',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Setting up your personalized learning experience...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Test navigation to QuestionScreen
                Navigator.pushNamed(
                  context,
                  '/question',
                  arguments: QuestionScreenArguments(
                    topicId: 'math_linear_equations', // Example topic ID
                    difficulty: DifficultyLevel.beginner,
                    questionCount: 5, // Shorter session for testing
                  ),
                );
              },
              child: const Text('Start Practice (Test)'),
            ),
          ],
        ),
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
