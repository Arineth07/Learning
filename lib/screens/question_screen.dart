import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_session.dart';
import '../models/question.dart';
import '../repositories/content_repository.dart';
import '../repositories/learning_session_repository.dart';
import '../services/recommendation_service.dart';
import '../widgets/widgets.dart';
import 'question_screen_arguments.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  String _userId = 'demo_user';
  LearningSession? _session;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isAnswerSubmitted = false;
  bool _showFeedback = false;
  DateTime? _questionStartTime;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  Question get _currentQuestion => _questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == _questions.length - 1;
  int get _correctAnswersCount =>
      _session?.questionResults.values.where((v) => v).length ?? 0;
  double get _accuracyPercentage =>
      _session != null ? _session!.accuracyRate * 100 : 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSession());
  }

  @override
  void dispose() {
    if (_session != null && !_session!.isCompleted) {
      _endSession();
    }
    super.dispose();
  }

  Future<void> _initializeSession() async {
    try {
      final args =
          ModalRoute.of(context)!.settings.arguments
              as QuestionScreenArguments?;
      if (args == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Invalid navigation: missing arguments';
          _isLoading = false;
        });
        return;
      }

      final contentRepository = context.read<ContentRepository>();
      final sessionRepository = context.read<LearningSessionRepository>();

      // Attempt to resume an active session for this user.
      // Use getActiveSession(userId) to find any non-completed session.
      final activeSessionResult = await sessionRepository.getActiveSession(
        _userId,
      );
      LearningSession? activeSession;
      activeSessionResult.fold((s) => activeSession = s, (_) => null);

      if (activeSession?.topicIds.contains(args.topicId) == true) {
        // Resume only if the active session is for the same topic.
        _session = activeSession;

        // Reconstruct question list from persisted data where possible.
        // We fetch all questions for the topic and then place answered questions
        // (persisted in session.questionIds) at the front in the same order,
        // followed by the remaining questions.
        final allQuestionsResult = await contentRepository
            .getQuestionsByTopicId(args.topicId);
        final resumedQuestions = allQuestionsResult.fold<List<Question>?>(
          (qs) => qs,
          (f) {
            if (!mounted) return null;
            setState(() {
              _errorMessage = 'Failed to load questions: ${f.message}';
              _isLoading = false;
            });
            return null;
          },
        );
        if (resumedQuestions == null) return;
        _questions = resumedQuestions;

        final answeredIds = _session!.questionIds;
        final questionById = {for (var q in _questions) q.id: q};
        final answeredQuestions = answeredIds
            .map((id) => questionById[id])
            .whereType<Question>()
            .toList();
        final remainingQuestions = _questions
            .where((q) => !answeredIds.contains(q.id))
            .toList();

        _questions = [...answeredQuestions, ...remainingQuestions];
        _currentQuestionIndex = answeredQuestions.length;
      } else {
        // Start new session if no suitable active session exists
        final sessionResult = await sessionRepository.startSession(_userId, [
          args.topicId,
        ]);
        final started = sessionResult.fold<LearningSession?>((s) => s, (f) {
          if (!mounted) return null;
          setState(() {
            _errorMessage = 'Failed to start session: ${f.message}';
            _isLoading = false;
          });
          return null;
        });
        if (started == null) return;
        _session = started;
      }

      // If we didn't resume (no questions loaded), try personalized set first
      if (_questions.isEmpty) {
        final recService = context.read<RecommendationService>();
        if (args.usePersonalizedQuestions && recService.isInitialized) {
          final pResult = await recService.getPersonalizedQuestions(
            _userId,
            args.topicId,
            questionCount: args.questionCount,
            difficulty: args.difficulty,
          );
          final set = pResult.fold<List<Question>?>(
            (s) => s.questions,
            (_) => null,
          );
          if (set != null && set.isNotEmpty) {
            _questions = set;
          } else {
            // Fallback to random questions on failure or empty personalized set
            final questionsResult = await contentRepository.getRandomQuestions(
              args.topicId,
              count: args.questionCount,
              difficulty: args.difficulty,
            );
            final fetched = questionsResult.fold<List<Question>?>((qs) => qs, (
              f,
            ) {
              if (!mounted) return null;
              setState(() {
                _errorMessage = 'Failed to load questions: ${f.message}';
                _isLoading = false;
              });
              return null;
            });
            if (fetched == null) return;
            _questions = fetched;
          }
        } else {
          final questionsResult = await contentRepository.getRandomQuestions(
            args.topicId,
            count: args.questionCount,
            difficulty: args.difficulty,
          );
          final fetched = questionsResult.fold<List<Question>?>((qs) => qs, (
            f,
          ) {
            if (!mounted) return null;
            setState(() {
              _errorMessage = 'Failed to load questions: ${f.message}';
              _isLoading = false;
            });
            return null;
          });
          if (fetched == null) return;
          _questions = fetched;
        }
      }

      // Guard against empty question sets to avoid crashes (division by zero,
      // attempting to read _currentQuestion, etc.). Surface a friendly message
      // and provide retry/back actions via the existing error UI.
      if (_questions.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No questions found for the selected topic.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize session: $e';
        _isLoading = false;
      });
    }
  }

  void _onAnswerSelected(String answer) {
    if (_isAnswerSubmitted) return;
    setState(() => _selectedAnswer = answer);
  }

  Future<void> _onSubmitAnswer() async {
    if (_isSubmitting) return; // prevent double submission

    if (_selectedAnswer == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an answer')));
      return;
    }

    // Defensive: ensure question start time is set before computing timeSpent.
    if (_questionStartTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait a moment before submitting your answer.'),
        ),
      );
      return;
    }

    // Prevent concurrent submissions
    setState(() {
      _isSubmitting = true;
    });

    try {
      final timeSpent = DateTime.now()
          .difference(_questionStartTime!)
          .inSeconds;
      final isCorrect = _selectedAnswer == _currentQuestion.correctAnswer;

      final result = await context
          .read<LearningSessionRepository>()
          .addQuestionResult(
            _session!.id,
            _currentQuestion.id,
            isCorrect,
            timeSpent,
          );
      result.fold((s) => _session = s, (f) => throw f);

      if (!mounted) return;
      setState(() {
        _isAnswerSubmitted = true;
        _showFeedback = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit answer: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _onNextQuestion() {
    if (_isLastQuestion) {
      _showSessionSummary();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _isAnswerSubmitted = false;
        _showFeedback = false;
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
      });
    }
  }

  Future<void> _showSessionSummary() async {
    await _endSession();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionSummaryWidget(
        session: _session!,
        totalQuestions: _questions.length,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _endSession() async {
    if (_session == null || _session!.isCompleted) return;

    try {
      final result = await context.read<LearningSessionRepository>().endSession(
        _session!.id,
      );
      result.fold(
        (s) => _session = s,
        (f) => debugPrint('Failed to end session: ${f.message}'),
      );
    } catch (e) {
      debugPrint('Failed to end session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_session != null && !_session!.isCompleted) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave Session?'),
              content: const Text(
                'Your progress will be saved, but the session will end. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          if (shouldPop == true) {
            await _endSession();
          }
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Practice Session'),
          actions: [
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeSession();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ProgressIndicatorWidget(
          currentQuestionIndex: _currentQuestionIndex,
          totalQuestions: _questions.length,
          accuracyPercentage: _accuracyPercentage,
          correctAnswers: _correctAnswersCount,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: QuestionCard(
              question: _currentQuestion,
              selectedAnswer: _selectedAnswer,
              isAnswerSubmitted: _isAnswerSubmitted,
              onAnswerSelected: _onAnswerSelected,
            ),
          ),
        ),
        if (_showFeedback)
          FeedbackBanner(
            isCorrect: _selectedAnswer == _currentQuestion.correctAnswer,
            explanation: _currentQuestion.explanation,
            pointsEarned: _selectedAnswer == _currentQuestion.correctAnswer
                ? _currentQuestion.points
                : null,
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_questionStartTime == null || _isSubmitting)
                  ? null
                  : (_isAnswerSubmitted ? _onNextQuestion : _onSubmitAnswer),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isAnswerSubmitted
                          ? (_isLastQuestion
                                ? 'Finish Session'
                                : 'Next Question')
                          : 'Submit Answer',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
