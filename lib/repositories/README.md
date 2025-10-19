# Repositories Directory

This directory contains repository classes that abstract the data access layer.

## Purpose
Repositories provide a clean API for data operations, hiding implementation details of whether data comes from Hive, JSON files, or remote APIs. This pattern enables easy testing and future data source changes without affecting business logic.

## Benefits

### Abstraction
- Separates data access logic from business logic
- Provides a consistent interface regardless of data source
- Makes it easy to switch between local and remote data

### Testability
- Easy to mock for unit testing
- Can test business logic without database dependencies
- Simplifies integration testing

### Maintainability
- Centralized data access logic
- Easy to modify data sources
- Reduces code duplication

## Planned Repositories

### QuestionRepository (`question_repository.dart`)
Manages question data access:
- Fetch questions by topic/subject
- Filter questions by difficulty
- Search questions
- Cache frequently accessed questions

### UserProgressRepository (`user_progress_repository.dart`)
Handles user progress data:
- Save progress updates
- Retrieve progress history
- Calculate statistics
- Export progress data

### SubjectRepository (`subject_repository.dart`)
Manages subject and topic data:
- Load subject hierarchies
- Get topics by subject
- Update subject metadata
- Track subject completion

### PerformanceRepository (`performance_repository.dart`)
Stores and retrieves performance metrics:
- Record session performance
- Aggregate performance data
- Generate performance reports
- Track trends over time

## Architecture Pattern

### Repository Interface
```dart
abstract class QuestionRepository {
  Future<List<Question>> getQuestionsByTopic(String topicId);
  Future<Question?> getQuestionById(String id);
  Future<void> saveQuestion(Question question);
  Future<void> deleteQuestion(String id);
}
```

### Implementation
```dart
class QuestionRepositoryImpl implements QuestionRepository {
  final DatabaseService _dbService;
  final ContentService _contentService;
  
  QuestionRepositoryImpl(this._dbService, this._contentService);
  
  @override
  Future<List<Question>> getQuestionsByTopic(String topicId) async {
    // Implementation details hidden from consumers
  }
}
```

## Usage Example
```dart
// Inject repository
final questionRepo = QuestionRepositoryImpl(dbService, contentService);

// Use in service or UI
final questions = await questionRepo.getQuestionsByTopic('algebra');
```

## Best Practices
- Define interfaces for repositories
- Use dependency injection for services
- Handle errors at repository level
- Implement caching strategies
- Log data access operations
- Write comprehensive tests
