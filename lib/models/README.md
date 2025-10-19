# Models Directory

This directory contains all data model classes for the AI Tutor App.

## Purpose
Models represent the core data structures used throughout the application. Each model is defined in its own file following Flutter's snake_case naming convention.

## Planned Models

### Question (`question.dart`)
Represents a single question with properties like:
- Question text
- Answer options
- Correct answer
- Difficulty level
- Topic/subject association
- Explanation

### Topic (`topic.dart`)
Represents a learning topic within a subject:
- Topic name
- Description
- Associated questions
- Prerequisites

### Subject (`subject.dart`)
Represents a subject area (e.g., Math, Programming):
- Subject name
- Topics list
- Overall progress

### UserProgress (`user_progress.dart`)
Tracks user's learning progress:
- Completed questions
- Scores
- Time spent
- Mastery levels

### PerformanceMetrics (`performance_metrics.dart`)
Stores performance analytics:
- Accuracy rates
- Response times
- Improvement trends
- Strengths and weaknesses

### KnowledgeGap (`knowledge_gap.dart`)
Identifies areas needing improvement:
- Gap description
- Related topics
- Severity level
- Recommended actions

### LearningSession (`learning_session.dart`)
Records individual learning sessions:
- Session start/end time
- Questions attempted
- Performance summary
- Topics covered

## Hive Integration
Models will use Hive type adapters for efficient local storage. Each model will be annotated with `@HiveType` and fields with `@HiveField` for code generation.

## Usage
Models will be imported and used by services, repositories, and UI components throughout the app.
