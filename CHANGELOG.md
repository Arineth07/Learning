# Changelog

## [Unreleased]

### Added
- Created model files:
  - Subject (typeId: 10)
  - Topic (typeId: 11)
  - Question (typeId: 12)
  - UserProgress (typeId: 13)
  - PerformanceMetrics (typeId: 14)
  - KnowledgeGap (typeId: 15)
  - LearningSession (typeId: 16)
  
- Created enum definitions:
  - DifficultyLevel (typeId: 0)
  - QuestionType (typeId: 1)
  - SubjectCategory (typeId: 2)
  - GapSeverity (typeId: 3)
  
- Added Hive type adapters for all models and enums
- Implemented JSON serialization/deserialization for all models
- Added proper null handling and default values
- Created models.dart barrel file for convenient exports
- Updated main.dart to register all Hive adapters