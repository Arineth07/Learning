import 'package:flutter/material.dart';

class FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final int? pointsEarned;

  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.pointsEarned,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.error,
                color: isCorrect ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect ? "Correct!" : "Incorrect",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                ),
              ),
              if (isCorrect && pointsEarned != null)
                Chip(
                  label: Text(
                    "+$pointsEarned pts",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green.shade200,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                ),
          ),
        ],
      ),
    );
  }
}