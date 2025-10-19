import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_session.dart';
import '../models/question.dart';
import '../repositories/content_repository.dart';
import '../repositories/learning_session_repository.dart';
import '../utils/result.dart';
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
      final args = ModalRoute.of(context)!.settings.arguments
          as QuestionScreenArguments?;
      if (args == null) {
        setState(() {
          _errorMessage = 'Invalid navigation: missing arguments';
          _isLoading = false;
        });
        return;
      }

      final contentRepository = context.read<ContentRepository>();
      final sessionRepository = context.read<LearningSessionRepository>();

      // Check for existing session
      if (args.sessionId != null) {
        final existingSession =
            await sessionRepository.getSessionById(args.sessionId!);
        if (existingSession is Success<LearningSession>) {
          _session = existingSession.value;
        }
      }

      // Start new session if needed
      if (_session == null) {
        final sessionResult = await sessionRepository.startSession(
          _userId,
          [args.topicId],
        );
        if (sessionResult is Error) {
          throw sessionResult.error;
        }
        _session = (sessionResult as Success<LearningSession>).value;
      }

      // Fetch questions
      final questionsResult = await contentRepository.getRandomQuestions(
        args.topicId,
        count: args.questionCount,
        difficulty: args.difficulty,
      );

      if (questionsResult is Error) {
        throw questionsResult.error;
      }
      _questions = (questionsResult as Success<List<Question>>).value;

      setState(() {
        _isLoading = false;
        _questionStartTime = DateTime.now();
      });
    } catch (e) {
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
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer')),
      );
      return;
    }

    try {
      final timeSpent =
          DateTime.now().difference(_questionStartTime!).inSeconds;
      final isCorrect = _selectedAnswer == _currentQuestion.correctAnswer;

      final result = await context.read<LearningSessionRepository>().addQuestionResult(
            _session!.id,
            _currentQuestion.id,
            isCorrect,
            timeSpent,
          );

      if (result is Error) {
        throw result.error;
      }
      _session = (result as Success<LearningSession>).value;

      setState(() {
        _isAnswerSubmitted = true;
        _showFeedback = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit answer: $e')),
      );
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
        _questionStartTime = DateTime.now();
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
      final result = await context
          .read<LearningSessionRepository>()
          .endSession(_session!.id);
      if (result is Success<LearningSession>) {
        _session = result.value;
      }
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
              onPressed: _isAnswerSubmitted ? _onNextQuestion : _onSubmitAnswer,
              child: Text(
                _isAnswerSubmitted
                    ? _isLastQuestion
                        ? 'Finish Session'
                        : 'Next Question'
                    : 'Submit Answer',
              ),
            ),
          ),
        ),
      ],
    );
  }
}