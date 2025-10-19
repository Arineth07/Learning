import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/enums.dart';
import 'option_tile.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswerSubmitted;
  final Function(String) onAnswerSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswerSubmitted,
    required this.onAnswerSelected,
  });

  Color _getDifficultyColor() {
    return switch (question.difficulty) {
      DifficultyLevel.beginner => Colors.green,
      DifficultyLevel.intermediate => Colors.blue,
      DifficultyLevel.advanced => Colors.orange,
      DifficultyLevel.expert => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    question.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getDifficultyColor().withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${question.points} pts',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: question.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = question.options[index];
                return OptionTile(
                  option: option,
                  isSelected: selectedAnswer == option,
                  isCorrect: isAnswerSubmitted && option == question.correctAnswer,
                  isIncorrect: isAnswerSubmitted &&
                      selectedAnswer == option &&
                      option != question.correctAnswer,
                  isDisabled: isAnswerSubmitted,
                  onTap: () => onAnswerSelected(option),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}