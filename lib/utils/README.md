# Utils Directory

This directory contains helper functions, constants, and utility classes used throughout the application.

## Planned Files

### constants.dart
App-wide constants including:
- Color constants (AppColors)
- Text style constants (AppTextStyles)
- API endpoints (ApiEndpoints)
- App configuration (AppConfig)
- Storage keys (StorageKeys)

### helpers.dart
Utility functions for common operations:
- Date and time formatting
- String manipulation
- Number formatting
- Validation helpers
- List operations
- Color utilities

### enums.dart
Enumeration types for type-safe constants:
- DifficultyLevel (beginner, intermediate, advanced, expert)
- QuestionType (multipleChoice, trueFalse, fillInBlank, matching)
- SubjectCategory (mathematics, programming, science, language)
- SessionStatus (notStarted, inProgress, completed, abandoned)
- SyncStatus (synced, pending, failed, offline)
- GapSeverity (low, medium, high, critical)

### validators.dart
Input validation functions for forms

### extensions.dart
Dart extension methods for enhanced functionality

## Best Practices
- Keep utilities pure and stateless
- Document complex functions
- Write unit tests for utilities
- Group related utilities together
- Use descriptive names
