import '../models/models.dart';
import '../services/content_service.dart';
import '../utils/constants.dart';
import '../utils/failures.dart';
import '../utils/result.dart';
import 'user_progress_repository.dart';

/// Repository interface for content operations.
abstract interface class ContentRepository {
  // Subject operations
  Future<Result<List<Subject>>> getAllSubjects();
  Future<Result<Subject>> getSubjectById(String id);
  Future<Result<Subject>> getSubjectByCategory(SubjectCategory category);

  // Topic operations
  Future<Result<List<Topic>>> getAllTopics();
  Future<Result<Topic>> getTopicById(String id);
  Future<Result<List<Topic>>> getTopicsBySubjectId(String subjectId);
  Future<Result<List<Topic>>> getTopicsByDifficulty(DifficultyLevel difficulty);
  Future<Result<List<Topic>>> getAvailableTopics(String userId);
  Future<Result<Topic?>> getNextTopic(String userId, String currentTopicId);

  // Question operations
  Future<Result<List<Question>>> getAllQuestions();
  Future<Result<Question>> getQuestionById(String id);
  Future<Result<List<Question>>> getQuestionsByTopicId(String topicId);
  Future<Result<List<Question>>> getQuestionsByTopicAndDifficulty(
    String topicId,
    DifficultyLevel difficulty,
  );
  Future<Result<List<Question>>> getQuestionsByTopicAndType(
    String topicId,
    QuestionType type,
  );
  Future<Result<List<Question>>> getRandomQuestions(
    String topicId, {
    int count = 10,
    DifficultyLevel? difficulty,
    QuestionType? type,
  });
  Future<Result<Question?>> getNextQuestion(
    String userId,
    String topicId,
    DifficultyLevel difficulty,
  );

  // Statistics operations
  Future<Result<int>> getQuestionCount(String topicId);
  Future<Result<Map<DifficultyLevel, int>>> getQuestionCountByDifficulty(
    String topicId,
  );
  Future<Result<Map<QuestionType, int>>> getQuestionCountByType(String topicId);
}

/// Concrete implementation of ContentRepository.
class ContentRepositoryImpl implements ContentRepository {
  final ContentService _contentService;
  final UserProgressRepository? _userProgressRepository;

  const ContentRepositoryImpl(
    this._contentService, [
    this._userProgressRepository,
  ]);

  @override
  Future<Result<List<Subject>>> getAllSubjects() async {
    try {
      _checkInitialized();
      final subjects = _contentService.subjects;
      return Result.success(subjects);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get subjects',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Subject>> getSubjectById(String id) async {
    try {
      _checkInitialized();
      final subject = _contentService.getSubjectById(id);
      if (subject == null) {
        return Result.error(
          NotFoundFailure('Subject with ID $id not found'),
        );
      }
      return Result.success(subject);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get subject',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Subject>> getSubjectByCategory(SubjectCategory category) async {
    try {
      _checkInitialized();
      final subject = _contentService.subjects
          .where((s) => s.category == category)
          .firstOrNull;
      if (subject == null) {
        return Result.error(
          NotFoundFailure('No subject found for category $category'),
        );
      }
      return Result.success(subject);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get subject by category',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Topic>>> getAllTopics() async {
    try {
      _checkInitialized();
      final topics = _contentService.topics;
      return Result.success(topics);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Topic>> getTopicById(String id) async {
    try {
      _checkInitialized();
      final topic = _contentService.getTopicById(id);
      if (topic == null) {
        return Result.error(
          NotFoundFailure('Topic with ID $id not found'),
        );
      }
      return Result.success(topic);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Topic>>> getTopicsBySubjectId(String subjectId) async {
    try {
      _checkInitialized();
      final topics = _contentService.getTopicsBySubjectId(subjectId);
      return Result.success(topics);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get topics by subject',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Topic>>> getTopicsByDifficulty(
    DifficultyLevel difficulty,
  ) async {
    try {
      _checkInitialized();
      final topics = _contentService.topics
          .where((t) => t.difficulty == difficulty)
          .toList();
      return Result.success(topics);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get topics by difficulty',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Topic>>> getAvailableTopics(String userId) async {
    try {
      _checkInitialized();

      if (_userProgressRepository == null) {
        // If no progress repository, return all topics
        return Result.success(_contentService.topics);
      }

      final topics = <Topic>[];
      for (final topic in _contentService.topics) {
        var isAvailable = true;

        // Check prerequisites
        for (final prerequisiteId in topic.prerequisiteTopicIds) {
          final progressResult = await _userProgressRepository!
              .getTopicProgress(userId, prerequisiteId);

          final progress = progressResult.fold(
            (progress) => progress,
            (_) => null,
          );

          if (progress == null || progress.masteryLevel < 0.8) {
            isAvailable = false;
            break;
          }
        }

        if (isAvailable) {
          topics.add(topic);
        }
      }

      return Result.success(topics);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get available topics',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Topic?>> getNextTopic(
    String userId,
    String currentTopicId,
  ) async {
    try {
      _checkInitialized();
      final currentTopic = _contentService.getTopicById(currentTopicId);
      if (currentTopic == null) {
        return Result.error(
          NotFoundFailure('Current topic not found'),
        );
      }

      final subjectTopics =
          _contentService.getTopicsBySubjectId(currentTopic.subjectId);

      final currentIndex = subjectTopics.indexOf(currentTopic);
      if (currentIndex == -1 || currentIndex >= subjectTopics.length - 1) {
        // No next topic available
        return const Result.success(null);
      }

      final nextTopic = subjectTopics[currentIndex + 1];
      
      // Check prerequisites if user progress is available
      if (_userProgressRepository != null) {
        for (final prerequisiteId in nextTopic.prerequisiteTopicIds) {
          final progressResult = await _userProgressRepository!
              .getTopicProgress(userId, prerequisiteId);

          final progress = progressResult.fold(
            (progress) => progress,
            (_) => null,
          );

          if (progress == null || progress.masteryLevel < 0.8) {
            // Prerequisites not met
            return const Result.success(null);
          }
        }
      }

      return Result.success(nextTopic);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get next topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Question>>> getAllQuestions() async {
    try {
      _checkInitialized();
      final questions = _contentService.questions;
      return Result.success(questions);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get questions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Question>> getQuestionById(String id) async {
    try {
      _checkInitialized();
      final question = _contentService.getQuestionById(id);
      if (question == null) {
        return Result.error(
          NotFoundFailure('Question with ID $id not found'),
        );
      }
      return Result.success(question);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get question',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Question>>> getQuestionsByTopicId(String topicId) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicId(topicId);
      return Result.success(questions);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get questions by topic',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Question>>> getQuestionsByTopicAndDifficulty(
    String topicId,
    DifficultyLevel difficulty,
  ) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicAndDifficulty(
        topicId,
        difficulty,
      );
      return Result.success(questions);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get questions by topic and difficulty',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Question>>> getQuestionsByTopicAndType(
    String topicId,
    QuestionType type,
  ) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicAndType(
        topicId,
        type,
      );
      return Result.success(questions);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get questions by topic and type',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Question>>> getRandomQuestions(
    String topicId, {
    int count = 10,
    DifficultyLevel? difficulty,
    QuestionType? type,
  }) async {
    try {
      _checkInitialized();

      if (count < 1) {
        return Result.error(
          ValidationFailure('Count must be positive'),
        );
      }

      var questions = _contentService.getQuestionsByTopicId(topicId);

      if (difficulty != null) {
        questions = questions.where((q) => q.difficulty == difficulty).toList();
      }

      if (type != null) {
        questions = questions.where((q) => q.type == type).toList();
      }

      if (questions.isEmpty) {
        return Result.error(
          NotFoundFailure('No questions found matching criteria'),
        );
      }

      questions.shuffle();
      questions = questions.take(count).toList();

      return Result.success(questions);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get random questions',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Question?>> getNextQuestion(
    String userId,
    String topicId,
    DifficultyLevel difficulty,
  ) async {
    try {
      _checkInitialized();
      
      // Get questions for topic and difficulty
      final questions = _contentService.getQuestionsByTopicAndDifficulty(
        topicId,
        difficulty,
      );

      if (questions.isEmpty) {
        return const Result.success(null);
      }

      if (_userProgressRepository == null) {
        // Without progress tracking, return a random question
        questions.shuffle();
        return Result.success(questions.first);
      }

      // Get user's performance for this topic
      final performanceResult = await _userProgressRepository!
          .getTopicProgress(userId, topicId);

      final performance = performanceResult.fold(
        (progress) => progress,
        (_) => null,
      );

      if (performance == null) {
        // No previous attempts, return first question
        return Result.success(questions.first);
      }

      // Filter out recently answered questions
      final recentQuestions = performance.recentQuestionIds.toSet();
      var availableQuestions =
          questions.where((q) => !recentQuestions.contains(q.id)).toList();

      if (availableQuestions.isEmpty) {
        // All questions attempted, return least recently answered
        availableQuestions = questions;
      }

      availableQuestions.shuffle();
      return Result.success(availableQuestions.first);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get next question',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getQuestionCount(String topicId) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicId(topicId);
      return Result.success(questions.length);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get question count',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<DifficultyLevel, int>>> getQuestionCountByDifficulty(
    String topicId,
  ) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicId(topicId);
      final Map<DifficultyLevel, int> counts = {};

      for (final question in questions) {
        counts.update(
          question.difficulty,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      return Result.success(counts);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get question counts by difficulty',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Map<QuestionType, int>>> getQuestionCountByType(
    String topicId,
  ) async {
    try {
      _checkInitialized();
      final questions = _contentService.getQuestionsByTopicId(topicId);
      final Map<QuestionType, int> counts = {};

      for (final question in questions) {
        counts.update(
          question.type,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      return Result.success(counts);
    } catch (e, st) {
      return Result.error(
        UnknownFailure(
          'Failed to get question counts by type',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  void _checkInitialized() {
    if (!_contentService.isInitialized) {
      throw StateError('ContentService not initialized');
    }
  }
}