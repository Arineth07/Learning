import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/enums.dart';
import 'option_tile.dart';

class QuestionCard extends StatefulWidget {
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

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedAnswer ?? '');
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAnswer != widget.selectedAnswer) {
      _controller.text = widget.selectedAnswer ?? '';
    }
    if (oldWidget.question.id != widget.question.id) {
      // New question, reset controller unless parent provided a selectedAnswer
      _controller.text = widget.selectedAnswer ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getDifficultyColor() {
    return switch (widget.question.difficulty) {
      DifficultyLevel.beginner => Colors.green,
      DifficultyLevel.intermediate => Colors.blue,
      DifficultyLevel.advanced => Colors.orange,
      DifficultyLevel.expert => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
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
                    q.difficulty.name.toUpperCase(),
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
                    '${q.points} pts',
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
            Text(q.text, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            // Branch on question type: MCQ/TrueFalse vs shortAnswer/essay
            if (q.type == QuestionType.multipleChoice ||
                q.type == QuestionType.trueFalse) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: q.options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final option = q.options[index];
                  return OptionTile(
                    option: option,
                    isSelected: widget.selectedAnswer == option,
                    isCorrect:
                        widget.isAnswerSubmitted && option == q.correctAnswer,
                    isIncorrect:
                        widget.isAnswerSubmitted &&
                        widget.selectedAnswer == option &&
                        option != q.correctAnswer,
                    isDisabled: widget.isAnswerSubmitted,
                    onTap: () => widget.onAnswerSelected(option),
                  );
                },
              ),
            ] else if (q.type == QuestionType.shortAnswer ||
                q.type == QuestionType.essay) ...[
              TextField(
                controller: _controller,
                enabled: !widget.isAnswerSubmitted,
                minLines: 1,
                maxLines: q.type == QuestionType.essay ? 6 : 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your answer here',
                ),
                onChanged: (val) => widget.onAnswerSelected(val),
              ),
            ] else ...[
              // Unsupported complex question types (coding, etc.)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This question type (${q.type.name}) is not supported in the current practice UI.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text('Please skip or try another question.'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
