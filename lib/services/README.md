The name 'MyApp' isn't a class.
Try correcting the name to match an existing class.# Services Directory

This directory contains business logic and external integration services for the AI Tutor App.

## Purpose
Services encapsulate complex operations, business logic, and external integrations. They can be injected via Provider for dependency management and state management.

## Planned Services

### DatabaseService (`database_service.dart`)
Manages Hive database operations:
- Initialize and configure Hive boxes
- CRUD operations for all models
- Data migration and versioning
- Database cleanup and maintenance

### ContentService (`content_service.dart`)
Handles content loading and management:
- Load questions from JSON files
- Parse and validate content
- Cache content in memory
- Content updates and synchronization

### AdaptiveLearningService (`adaptive_learning_service.dart`)
Implements adaptive learning algorithms:
- Analyze user performance
- Adjust difficulty levels
- Select appropriate questions
- Personalize learning paths

### KnowledgeGapService (`knowledge_gap_service.dart`)
Identifies and tracks knowledge gaps:
- Analyze incorrect answers
- Identify weak topics
- Calculate gap severity
- Generate improvement recommendations

### RecommendationService (`recommendation_service.dart`)
Provides personalized recommendations:
- Suggest next topics to study
- Recommend practice questions
- Identify optimal study times
- Generate learning strategies

### ConnectivityService (`connectivity_service.dart`)
Monitors network connectivity:
- Detect online/offline status
- Handle connectivity changes
- Queue operations for sync
- Notify app of connectivity state

### SyncService (`sync_service.dart`)
Synchronizes data with remote servers:
- Upload user progress
- Download new content
- Resolve sync conflicts
- Handle offline queue

## Architecture Pattern
Services follow the Provider pattern for state management:
- Extend `ChangeNotifier` for reactive updates
- Use `notifyListeners()` to update UI
- Injected via `Provider` or `ChangeNotifierProvider`
- Can depend on other services via constructor injection

## Usage Example
```dart
// In main.dart
ChangeNotifierProvider(create: (_) => DatabaseService()),

// In a widget
final dbService = Provider.of<DatabaseService>(context);
```

## Best Practices
- Keep services focused on a single responsibility
- Use async/await for asynchronous operations
- Handle errors gracefully with try-catch
- Log important operations for debugging
- Write unit tests for service logic
