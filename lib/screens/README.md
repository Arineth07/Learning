# Screens Directory

This directory contains full-page UI components representing distinct pages in the app navigation.

## Purpose
Screens are top-level widgets that represent complete pages in the application. Each screen is registered in the navigation routes defined in `lib/main.dart` and consumes data from services via Provider.

## Planned Screens

### DashboardScreen (`dashboard_screen.dart`)
Main landing page after app launch:
- Overview of learning progress
- Quick access to subjects
- Recent activity summary
- Recommended next steps
- Performance highlights

### QuestionScreen (`question_screen.dart`)
Interactive question-answering interface:
- Display current question
- Multiple choice options
- Submit answer functionality
- Immediate feedback
- Explanation display
- Navigation to next question

### ProgressScreen (`progress_screen.dart`)
Detailed progress tracking and analytics:
- Overall progress visualization
- Subject-wise breakdown
- Performance charts (using fl_chart)
- Knowledge gap identification
- Achievement badges
- Historical trends

### SettingsScreen (`settings_screen.dart`)
App configuration and preferences:
- User profile settings
- Notification preferences
- Theme selection (light/dark)
- Data management (clear cache, export data)
- About app information
- Privacy settings

### SubjectScreen (`subject_screen.dart`)
Subject-specific view:
- List of topics in subject
- Progress per topic
- Start learning button
- Subject statistics

### TopicScreen (`topic_screen.dart`)
Topic-specific learning interface:
- Topic description
- Learning objectives
- Start practice session
- View related topics
- Topic mastery level

### ResultsScreen (`results_screen.dart`)
Session results and feedback:
- Session summary
- Score and accuracy
- Time taken
- Correct/incorrect breakdown
- Knowledge gaps identified
- Recommendations for improvement

## Screen Structure

### Basic Template
```dart
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer<DatabaseService>(
        builder: (context, dbService, child) {
          // Build UI using service data
          return Container();
        },
      ),
    );
  }
}
```

## Navigation

### Route Registration (in main.dart)
```dart
routes: {
  '/': (context) => const DashboardScreen(),
  '/question': (context) => const QuestionScreen(),
  '/progress': (context) => const ProgressScreen(),
  '/settings': (context) => const SettingsScreen(),
}
```

### Navigation Usage
```dart
// Simple navigation
Navigator.pushNamed(context, '/progress');

// Navigation with arguments
Navigator.pushNamed(
  context,
  '/question',
  arguments: {'questionId': '123'},
);

// Replace current screen
Navigator.pushReplacementNamed(context, '/dashboard');
```

## State Management
Screens use Provider for state management:
- `Consumer` widget for reactive UI updates
- `Provider.of<T>(context)` for accessing services
- `context.watch<T>()` for listening to changes
- `context.read<T>()` for one-time access

## Best Practices
- Keep screens focused on UI presentation
- Delegate business logic to services
- Use stateful widgets when local state is needed
- Implement proper loading and error states
- Follow Material Design guidelines
- Ensure responsive layouts for different screen sizes
- Add proper accessibility features
- Handle back button navigation appropriately
