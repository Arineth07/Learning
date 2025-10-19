import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'utils/app_theme.dart';

// TODO: Import screens as they are created in subsequent phases
// import 'screens/dashboard_screen.dart';
// import 'screens/question_screen.dart';
// import 'screens/progress_screen.dart';
// import 'screens/settings_screen.dart';

// TODO: Import services as they are created in subsequent phases
// import 'services/database_service.dart';
// import 'services/content_service.dart';
// import 'services/adaptive_learning_service.dart';
// import 'services/knowledge_gap_service.dart';
// import 'services/recommendation_service.dart';
// import 'services/connectivity_service.dart';
// import 'services/sync_service.dart';

void main() async {
  // Ensure Flutter is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local database storage
    await Hive.initFlutter();

    // TODO: Register Hive type adapters as models are created
    // Example:
    // Hive.registerAdapter(QuestionAdapter());
    // Hive.registerAdapter(TopicAdapter());
    // Hive.registerAdapter(SubjectAdapter());
    // Hive.registerAdapter(UserProgressAdapter());
    // Hive.registerAdapter(PerformanceMetricsAdapter());
    // Hive.registerAdapter(KnowledgeGapAdapter());
    // Hive.registerAdapter(LearningSessionAdapter());

    runApp(const AITutorApp());
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
    // Since no services are implemented yet, return MaterialApp directly
    return 
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
          '/': (context) => const PlaceholderHomeScreen(),
          // TODO: Add routes as screens are created
          // '/question': (context) => const QuestionScreen(),
          // '/progress': (context) => const ProgressScreen(),
          // '/settings': (context) => const SettingsScreen(),
        },

        // Dynamic route handling for routes with parameters
        onGenerateRoute: (settings) {
          // TODO: Implement dynamic route handling as needed
          // Example:
          // if (settings.name == '/question') {
          //   final args = settings.arguments as Map<String, dynamic>;
          //   return MaterialPageRoute(
          //     builder: (context) => QuestionScreen(questionId: args['id']),
          //   );
          // }
          return null;
        },

        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const PlaceholderHomeScreen(),
          );
        },
      ),
    )
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
          ],
        ),
      ),
    );
  }
}

/// Error app displayed when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

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
              const Text(
                'Failed to Initialize App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
