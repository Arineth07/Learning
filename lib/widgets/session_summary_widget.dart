import 'package:flutter/material.dart';
import '../models/learning_session.dart';

class SessionSummaryWidget extends StatelessWidget {
  final LearningSession session;
  final int totalQuestions;

  const SessionSummaryWidget({
    super.key,
    required this.session,
    required this.totalQuestions,
  });

  int get correctAnswers =>
      session.questionResults.values.where((v) => v).length;

  int get incorrectAnswers => totalQuestions - correctAnswers;

  double get accuracyPercentage => session.accuracyRate * 100;

  String get performanceMessage {
    if (accuracyPercentage >= 90) return "Excellent work! 🎉";
    if (accuracyPercentage >= 75) return "Great job! 👍";
    if (accuracyPercentage >= 60) return "Good effort! 💪";
    return "Keep practicing! 📚";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              "Session Complete!",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              performanceMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildStatCard(
              context,
              icon: Icons.check_circle,
              color: Colors.green,
              label: "Correct",
              value: "$correctAnswers",
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.cancel,
              color: Colors.red,
              label: "Incorrect",
              value: "$incorrectAnswers",
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.analytics,
              color: Colors.blue,
              label: "Accuracy",
              value: "${accuracyPercentage.toStringAsFixed(1)}%",
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.timer,
              color: Colors.orange,
              label: "Time Spent",
              value: "${session.totalTimeSpentMinutes} min",
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to practice again with same topic
                  },
                  child: const Text("Practice Again"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
