import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';

/// Service to load, parse, and cache bundled JSON content.
class ContentService extends ChangeNotifier {
  // Singleton pattern
  static final ContentService instance = ContentService._internal();
  ContentService._internal();

  // State
  bool _isInitialized = false;

  // Cache
  final Map<String, Subject> _subjects = {};
  final Map<String, Topic> _topics = {};
  final Map<String, Question> _questions = {};
  final Map<String, List<Topic>> _topicsBySubject = {};
  final Map<String, List<Question>> _questionsByTopic = {};

  // Public getters
  bool get isInitialized => _isInitialized;
  List<Subject> get subjects {
    _checkInitialized();
    return _subjects.values.toList();
  }

  List<Topic> get topics {
    _checkInitialized();
    return _topics.values.toList();
  }

  List<Question> get questions {
    _checkInitialized();
    return _questions.values.toList();
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('ContentService not initialized');
    }
  }

  /// Initialize the service by loading and validating all content.
  Future<Result<void>> initialize() async {
    if (_isInitialized) {
      return const Result.success(null);
    }

    try {
      // Load mathematics content
      await _loadSubjectContent(ContentConstants.mathematicsAsset);

      // Load programming content
      await _loadSubjectContent(ContentConstants.programmingAsset);

      // Build lookup indexes
      _buildIndexes();

      // Validate content if enabled
      if (ContentConstants.enableContentValidation) {
        final validationResult = _validateContent();
        if (validationResult.isError) {
          return validationResult;
        }
      }

      _isInitialized = true;
      notifyListeners();
      return const Result.success(null);
    } on FlutterError catch (e, st) {
      return Result.error(
        NotFoundFailure(
          'Failed to load content assets',
          cause: e,
          stackTrace: st,
        ),
      );
    } on Failure catch (f) {
      // Preserve specific failure types from _loadSubjectContent
      return Result.error(f);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Unexpected error initializing content',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Load content from a JSON asset file.
  Future<void> _loadSubjectContent(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Parse subject
      final subject = Subject.fromJson(data['subject'] as Map<String, dynamic>);
      _subjects[subject.id] = subject;

      // Parse topics
      for (final topicJson in data['topics'] as List<dynamic>) {
        final topic = Topic.fromJson(topicJson as Map<String, dynamic>);
        _topics[topic.id] = topic;
      }

      // Parse questions
      for (final questionJson in data['questions'] as List<dynamic>) {
        final question = Question.fromJson(
          questionJson as Map<String, dynamic>,
        );
        _questions[question.id] = question;
      }
    } on FormatException catch (e, st) {
      throw SerializationFailure(
        'Invalid JSON format in $assetPath',
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw UnknownFailure(
        'Error loading content from $assetPath',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Build lookup indexes for efficient querying.
  void _buildIndexes() {
    // Group topics by subject
    for (final topic in _topics.values) {
      _topicsBySubject.putIfAbsent(topic.subjectId, () => []).add(topic);
    }

    // Sort topics according to their order in subject.topicIds
    for (final subject in _subjects.values) {
      final topicsList = _topicsBySubject[subject.id];
      if (topicsList != null) {
        // Create index map from subject.topicIds
        final orderMap = Map.fromEntries(
          subject.topicIds.asMap().entries.map((e) => MapEntry(e.value, e.key)),
        );

        // Sort using the index map (fallback to name if not in map)
        topicsList.sort((a, b) {
          final orderA = orderMap[a.id];
          final orderB = orderMap[b.id];

          if (orderA == null && orderB == null) {
            return a.name.compareTo(b.name);
          }
          if (orderA == null) return 1;
          if (orderB == null) return -1;
          return orderA.compareTo(orderB);
        });
      }
    }

    // Group questions by topic
    for (final question in _questions.values) {
      _questionsByTopic.putIfAbsent(question.topicId, () => []).add(question);
    }
  }

  /// Validate content structure and relationships.
  Result<void> _validateContent() {
    try {
      // Check for duplicate IDs
      _checkDuplicateIds();

      // Validate reference integrity
      _validateReferences();

      // Validate business rules
      _validateBusinessRules();

      return const Result.success(null);
    } catch (e, st) {
      return Result.error(ValidationFailure(e.toString(), stackTrace: st));
    }
  }

  void _checkDuplicateIds() {
    final allIds = {..._subjects.keys, ..._topics.keys, ..._questions.keys};
    if (allIds.length !=
        _subjects.length + _topics.length + _questions.length) {
      throw const ValidationFailure('Duplicate IDs found in content');
    }
  }

  void _validateReferences() {
    // Validate subject references
    for (final subject in _subjects.values) {
      for (final topicId in subject.topicIds) {
        if (!_topics.containsKey(topicId)) {
          throw ValidationFailure(
            'Topic $topicId referenced by subject ${subject.id} not found',
          );
        }
      }
    }

    // Validate topic references
    for (final topic in _topics.values) {
      if (!_subjects.containsKey(topic.subjectId)) {
        throw ValidationFailure(
          'Subject ${topic.subjectId} referenced by topic ${topic.id} not found',
        );
      }

      for (final questionId in topic.questionIds) {
        if (!_questions.containsKey(questionId)) {
          throw ValidationFailure(
            'Question $questionId referenced by topic ${topic.id} not found',
          );
        }
      }

      for (final prerequisiteId in topic.prerequisiteTopicIds) {
        if (!_topics.containsKey(prerequisiteId)) {
          throw ValidationFailure(
            'Prerequisite topic $prerequisiteId referenced by topic ${topic.id} not found',
          );
        }
      }
    }

    // Validate question references
    for (final question in _questions.values) {
      if (!_topics.containsKey(question.topicId)) {
        throw ValidationFailure(
          'Topic ${question.topicId} referenced by question ${question.id} not found',
        );
      }
    }
  }

  void _validateBusinessRules() {
    // Check topics per subject minimum
    for (final subject in _subjects.values) {
      final topicCount = _topicsBySubject[subject.id]?.length ?? 0;
      if (topicCount < ContentConstants.minTopicsPerSubject) {
        throw ValidationFailure(
          'Subject ${subject.id} has fewer than ${ContentConstants.minTopicsPerSubject} topics',
        );
      }
    }

    // Check questions per topic limits
    for (final topic in _topics.values) {
      final questionCount = _questionsByTopic[topic.id]?.length ?? 0;
      if (questionCount < ContentConstants.minQuestionsPerTopic) {
        throw ValidationFailure(
          'Topic ${topic.id} has fewer than ${ContentConstants.minQuestionsPerTopic} questions',
        );
      }
      if (questionCount > ContentConstants.maxQuestionsPerTopic) {
        throw ValidationFailure(
          'Topic ${topic.id} has more than ${ContentConstants.maxQuestionsPerTopic} questions',
        );
      }
    }

    // Check for circular prerequisites
    for (final topic in _topics.values) {
      _checkCircularPrerequisites(topic.id, {});
    }
  }

  void _checkCircularPrerequisites(String topicId, Set<String> visited) {
    if (visited.contains(topicId)) {
      throw const ValidationFailure('Circular prerequisite dependency detected');
    }

    visited.add(topicId);
    final topic = _topics[topicId];
    for (final prerequisiteId in topic!.prerequisiteTopicIds) {
      _checkCircularPrerequisites(prerequisiteId, {...visited});
    }
  }

  // Query methods used by ContentRepository
  Subject? getSubjectById(String id) {
    _checkInitialized();
    return _subjects[id];
  }

  Topic? getTopicById(String id) {
    _checkInitialized();
    return _topics[id];
  }

  Question? getQuestionById(String id) {
    _checkInitialized();
    return _questions[id];
  }

  List<Topic> getTopicsBySubjectId(String subjectId) {
    _checkInitialized();
    return _topicsBySubject[subjectId] ?? [];
  }

  List<Question> getQuestionsByTopicId(String topicId) {
    _checkInitialized();
    return _questionsByTopic[topicId] ?? [];
  }

  List<Question> getQuestionsByTopicAndDifficulty(
    String topicId,
    DifficultyLevel difficulty,
  ) {
    _checkInitialized();
    return _questionsByTopic[topicId]
            ?.where((q) => q.difficulty == difficulty)
            .toList() ??
        [];
  }

  List<Question> getQuestionsByTopicAndType(String topicId, QuestionType type) {
    _checkInitialized();
    return _questionsByTopic[topicId]?.where((q) => q.type == type).toList() ??
        [];
  }

  // Cache management
  void clearCache() {
    _subjects.clear();
    _topics.clear();
    _questions.clear();
    _topicsBySubject.clear();
    _questionsByTopic.clear();
    _isInitialized = false;
    notifyListeners();
  }

  Future<Result<void>> reload() async {
    clearCache();
    return initialize();
  }
}
