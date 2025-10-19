import 'package:ai_tutor_app/models/enums.dart';

/// Arguments class for QuestionScreen navigation.
class QuestionScreenArguments {
  final String topicId;
  final DifficultyLevel difficulty;
  final String? sessionId;
  final int questionCount;
  final bool usePersonalizedQuestions;

  const QuestionScreenArguments({
    required this.topicId,
    required this.difficulty,
    this.sessionId,
    this.questionCount = 10,
    this.usePersonalizedQuestions = false,
  });
}
