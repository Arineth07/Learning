import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/learning_session_repository.dart';
import '../models/models.dart';
import '../utils/result.dart';

class WelcomeCard extends StatelessWidget {
  final String userId;

  const WelcomeCard({
    required this.userId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Consumer<LearningSessionRepository>(
          builder: (context, sessionRepo, _) {
            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                sessionRepo.getTotalSessionCount(userId),
                sessionRepo.getAverageAccuracy(userId),
                sessionRepo.getTotalStudyTimeMinutes(userId),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error loading statistics',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to start your learning journey?',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                final results = snapshot.data!;
                final totalSessionsResult = results[0] as Result<int>;
                final avgAccuracyResult = results[1] as Result<double>;
                final studyMinutesResult = results[2] as Result<int>;

                return totalSessionsResult.fold(
                  (totalSessions) => avgAccuracyResult.fold(
                    (avgAccuracy) => studyMinutesResult.fold(
                      (studyMinutes) => _buildStatsCard(
                        context,
                        totalSessions,
                        avgAccuracy,
                        studyMinutes,
                      ),
                      (failure) => _buildErrorCard(context, failure.message),
                    ),
                    (failure) => _buildErrorCard(context, failure.message),
                  ),
                  (failure) => _buildErrorCard(context, failure.message),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    int totalSessions,
    double avgAccuracy,
    int studyMinutes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Total Sessions: $totalSessions',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Average Accuracy: ${(avgAccuracy * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total Study Time: $studyMinutes minutes',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            totalSessions > 0
                ? 'Keep up the great work!'
                : 'Ready to start your learning journey?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  // ignore: unused_element
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // ignore: unused_element
  String _getMotivationalMessage(UserProgress progress) {
    if (progress.totalAttempts == 0) {
      return 'Welcome! Let\'s start your learning journey.';
    }

    final daysSinceLastSession = DateTime.now()
        .difference(progress.lastAttemptAt)
        .inDays;

    if (daysSinceLastSession == 0) {
      return 'Great work today! Keep the momentum going!';
    } else if (daysSinceLastSession == 1) {
      return 'Welcome back! Ready to continue learning?';
    } else if (daysSinceLastSession <= 3) {
      return 'It\'s been a few days. Let\'s get back to learning!';
    } else {
      return 'We\'ve missed you! Time to jump back in?';
    }
  }
}
