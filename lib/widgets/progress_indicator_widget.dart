import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final double accuracyPercentage;
  final int? correctAnswers;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.accuracyPercentage,
    this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    // Protect against division by zero when totalQuestions == 0
                    value: totalQuestions == 0
                        ? null
                        : (currentQuestionIndex + 1) / totalQuestions,
                    backgroundColor: Colors.grey.shade300,
                    color: Theme.of(context).colorScheme.primary,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                totalQuestions == 0
                    ? '0/0'
                    : "${currentQuestionIndex + 1}/$totalQuestions",
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                context,
                icon: Icons.analytics,
                iconColor: Theme.of(context).colorScheme.primary,
                value: "${accuracyPercentage.toStringAsFixed(0)}%",
                label: "Accuracy",
              ),
              if (correctAnswers != null)
                _buildStat(
                  context,
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  value: "$correctAnswers",
                  label: "Correct",
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
